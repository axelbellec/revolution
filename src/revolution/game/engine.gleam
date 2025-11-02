/// Game engine - state transitions and game flow logic
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/order.{Eq, Gt, Lt}
import gleam/result
import revolution/error/types.{
  type GameError, GameFull, GameNotStarted, InvalidPlay, NotYourTurn, WrongPhase,
}
import revolution/game/deck
import revolution/game/rules
import revolution/game/scoring
import revolution/game/types.{
  type Card, type GameConfig, type GamePhase, type Player,
  Connected, GameOver, GameState, PendingExchange, Player, Playing,
  President, RoundOver, Trouduc, VicePresident, ViceTrouduc, WaitingForPlayers,
} as game_types
import revolution/utils/id.{type PlayerId}

/// Create a new game
pub fn create_game(
  game_id: id.GameId,
  host_player_id: PlayerId,
  config: GameConfig,
  timestamp: Int,
) -> game_types.GameState {
  GameState(
    id: game_id,
    config: config,
    players: [],
    phase: WaitingForPlayers,
    current_player_index: 0,
    discard_pile: [],
    play_history: [],
    last_play: None,
    revolution_active: False,
    round_number: 0,
    scores: dict.new(),
    created_at: timestamp,
    host_player_id: host_player_id,
    sequence_counter: 0,
  )
}

/// Add a player to the game
pub fn add_player(
  state: game_types.GameState,
  player_id: PlayerId,
  player_name: String,
  timestamp: Int,
) -> Result(game_types.GameState, GameError) {
  // Check if game is full
  case list.length(state.players) >= state.config.max_players {
    True -> Error(GameFull)
    False -> {
      let new_player =
        Player(
          id: player_id,
          name: player_name,
          hand: [],
          role: None,
          finished_position: None,
          connection_state: Connected(timestamp),
          has_passed: False,
        )

      Ok(
        game_types.GameState(
          ..state,
          players: list.append(state.players, [new_player]),
        ),
      )
    }
  }
}

/// Start the game (deal cards, begin first round)
pub fn start_game(state: game_types.GameState, seed: Int) -> Result(game_types.GameState, GameError) {
  case state.phase {
    WaitingForPlayers -> {
      let player_count = list.length(state.players)
      case player_count >= state.config.min_players {
        False -> Error(InvalidPlay("Not enough players to start game"))
        True -> {
          // Create and shuffle deck
          let deck = deck.create_deck() |> deck.shuffle(seed)

          // Deal cards to players
          case deck.deal_cards(deck, state.players) {
            Ok(players_with_cards) ->
              Ok(
                game_types.GameState(
                  ..state,
                  players: players_with_cards,
                  phase: Playing,
                  round_number: 1,
                  current_player_index: 0,
                ),
              )
            Error(msg) -> Error(InvalidPlay(msg))
          }
        }
      }
    }
    _ -> Error(WrongPhase("WaitingForPlayers", phase_to_string(state.phase)))
  }
}

/// Play cards
pub fn play_cards(
  state: game_types.GameState,
  player_id: PlayerId,
  cards: List(Card),
  timestamp: Int,
) -> Result(game_types.GameState, GameError) {
  // Validate phase
  case state.phase {
    Playing -> {
      // Validate it's player's turn
      case get_current_player(state) {
        Ok(current_player) -> {
          case id.player_id_eq(current_player.id, player_id) {
            False -> Error(NotYourTurn)
            True -> {
              // Validate cards are in hand
              result.try(
                rules.validate_cards_in_hand(cards, current_player.hand),
                fn(_) {
                  // Validate play is legal
                  result.try(
                    rules.validate_play(
                      cards,
                      state.last_play,
                      state.revolution_active,
                    ),
                    fn(_) {
                      // Execute play
                      execute_play(state, current_player, cards, timestamp)
                    },
                  )
                },
              )
            }
          }
        }
        Error(_) -> Error(GameNotStarted)
      }
    }
    _ -> Error(WrongPhase("Playing", phase_to_string(state.phase)))
  }
}

/// Execute a play (internal function after validation)
fn execute_play(
  state: game_types.GameState,
  player: Player,
  cards: List(Card),
  timestamp: Int,
) -> Result(game_types.GameState, GameError) {
  // Remove cards from player's hand
  let new_hand = deck.remove_cards(player.hand, cards)

  // Check if pile clears
  let pile_clears = rules.clears_pile(cards)

  // Check if revolution triggers
  let revolution_triggers =
    state.config.revolution_enabled && rules.triggers_revolution(cards)

  // Create play record
  let play = game_types.Play(player.id, cards, pile_clears, timestamp)

  // Update discard pile
  let new_discard_pile = case pile_clears {
    True -> []
    False -> list.append(state.discard_pile, cards)
  }

  // Update player
  let updated_player = Player(..player, hand: new_hand, has_passed: False)

  // Replace player in players list
  let updated_players = replace_player(state.players, updated_player)

  // Check if player finished
  case list.is_empty(new_hand) {
    True -> {
      // Player finished - handle round end
      let finished_player =
        Player(
          ..updated_player,
          finished_position: Some(get_next_finish_position(state)),
        )

      let final_players = replace_player(updated_players, finished_player)

      // Check if round is over
      case count_unfinished_players(final_players) {
        0 | 1 -> {
          // Auto-finish last remaining player (if any)
          let final_players_with_last = auto_finish_last_player(final_players)
          // Round over - create finishing order
          let finishing_order = get_finishing_order(final_players_with_last)
          Ok(
            GameState(
              ..state,
              players: final_players_with_last,
              discard_pile: new_discard_pile,
              play_history: [play, ..state.play_history],
              last_play: Some(play),
              revolution_active: case revolution_triggers {
                True -> !state.revolution_active
                False -> state.revolution_active
              },
              phase: RoundOver(finishing_order),
            ),
          )
        }
        _ -> {
          // Continue playing
          let next_index = get_next_player_index(state, final_players)
          Ok(
            GameState(
              ..state,
              players: final_players,
              discard_pile: new_discard_pile,
              play_history: [play, ..state.play_history],
              last_play: case pile_clears {
                True -> None
                False -> Some(play)
              },
              revolution_active: case revolution_triggers {
                True -> !state.revolution_active
                False -> state.revolution_active
              },
              current_player_index: next_index,
            ),
          )
        }
      }
    }
    False -> {
      // Player continues - advance turn
      let next_index = get_next_player_index(state, updated_players)

      Ok(
        GameState(
          ..state,
          players: updated_players,
          discard_pile: new_discard_pile,
          play_history: [play, ..state.play_history],
          last_play: case pile_clears {
            True -> None
            False -> Some(play)
          },
          revolution_active: case revolution_triggers {
            True -> !state.revolution_active
            False -> state.revolution_active
          },
          current_player_index: next_index,
        ),
      )
    }
  }
}

/// Pass turn
pub fn pass_turn(
  state: game_types.GameState,
  player_id: PlayerId,
) -> Result(game_types.GameState, GameError) {
  case state.phase {
    Playing -> {
      // Validate it's player's turn
      case get_current_player(state) {
        Ok(current_player) -> {
          case id.player_id_eq(current_player.id, player_id) {
            False -> Error(NotYourTurn)
            True -> {
              // Check if can pass
              let is_starting_trick = case state.last_play {
                None -> True
                Some(_) -> False
              }

              result.try(rules.can_pass(is_starting_trick), fn(_) {
                // Mark player as passed
                let updated_player =
                  Player(..current_player, has_passed: True)

                let updated_players =
                  replace_player(state.players, updated_player)

                // Check if all players have passed
                case all_players_passed_except_one(updated_players) {
                  True -> {
                    // Clear pile, reset passes, winner leads
                    let reset_players = reset_all_passes(updated_players)
                    let winner_index = find_last_player_who_played(state)

                    Ok(
                      GameState(
                        ..state,
                        players: reset_players,
                        discard_pile: [],
                        last_play: None,
                        current_player_index: winner_index,
                      ),
                    )
                  }
                  False -> {
                    // Advance to next player
                    let next_index =
                      get_next_player_index(state, updated_players)
                    Ok(
                      GameState(
                        ..state,
                        players: updated_players,
                        current_player_index: next_index,
                      ),
                    )
                  }
                }
              })
            }
          }
        }
        Error(_) -> Error(GameNotStarted)
      }
    }
    _ -> Error(WrongPhase("Playing", phase_to_string(state.phase)))
  }
}

/// Start next round after RoundOver
pub fn start_next_round(
  state: game_types.GameState,
  seed: Int,
) -> Result(game_types.GameState, GameError) {
  case state.phase {
    RoundOver(finishing_order) -> {
      // Assign roles based on finishing order
      let player_count = list.length(state.players)
      let roles = scoring.assign_roles(finishing_order, player_count)

      // Apply roles to players
      let players_with_roles =
        scoring.apply_roles_to_players(state.players, roles)

      // Create and shuffle new deck
      let deck = deck.create_deck() |> deck.shuffle(seed)

      // Deal cards
      case deck.deal_cards(deck, players_with_roles) {
        Ok(players_with_cards) -> {
          // Reset player states
          let reset_players =
            list.map(players_with_cards, fn(p) {
              Player(..p, has_passed: False, finished_position: None)
            })

          // Find President's index (winner from previous round starts)
          let president_index = find_player_with_role_index(reset_players, President)

          // Determine if we need card exchange phase
          case scoring.has_vice_roles(player_count) {
            True -> {
              // Create pending exchanges
              let pending = create_pending_exchanges(reset_players)
              Ok(
                game_types.GameState(
                  ..state,
                  players: reset_players,
                  phase: game_types.CardExchange(pending),
                  discard_pile: [],
                  play_history: [],
                  last_play: None,
                  revolution_active: False,
                  round_number: state.round_number + 1,
                  current_player_index: president_index,
                ),
              )
            }
            False -> {
              // No exchange, go straight to playing
              Ok(
                game_types.GameState(
                  ..state,
                  players: reset_players,
                  phase: game_types.Playing,
                  discard_pile: [],
                  play_history: [],
                  last_play: None,
                  revolution_active: False,
                  round_number: state.round_number + 1,
                  current_player_index: president_index,
                ),
              )
            }
          }
        }
        Error(msg) -> Error(InvalidPlay(msg))
      }
    }
    _ -> Error(WrongPhase("RoundOver", phase_to_string(state.phase)))
  }
}

// Helper functions

fn get_current_player(state: game_types.GameState) -> Result(game_types.Player, Nil) {
  state.players
  |> list.drop(state.current_player_index)
  |> list.first
}

fn replace_player(players: List(game_types.Player), updated: game_types.Player) -> List(game_types.Player) {
  list.map(players, fn(p) {
    case id.player_id_eq(p.id, updated.id) {
      True -> updated
      False -> p
    }
  })
}

fn get_next_player_index(state: game_types.GameState, players: List(game_types.Player)) -> Int {
  let player_count = list.length(players)
  { state.current_player_index + 1 } % player_count
}

fn get_next_finish_position(state: game_types.GameState) -> Int {
  let finished =
    list.filter(state.players, fn(p) {
      case p.finished_position {
        Some(_) -> True
        None -> False
      }
    })

  list.length(finished) + 1
}

fn count_unfinished_players(players: List(game_types.Player)) -> Int {
  list.filter(players, fn(p) {
    case p.finished_position {
      None -> True
      Some(_) -> False
    }
  })
  |> list.length
}

fn get_finishing_order(players: List(Player)) -> List(PlayerId) {
  players
  |> list.filter(fn(p) {
    case p.finished_position {
      Some(_) -> True
      None -> False
    }
  })
  |> list.sort(fn(a, b) {
    case a.finished_position, b.finished_position {
      Some(pos_a), Some(pos_b) ->
        case pos_a == pos_b, pos_a < pos_b {
          True, _ -> Eq
          _, True -> Lt
          _, False -> Gt
        }
      _, _ -> Eq
    }
  })
  |> list.map(fn(p) { p.id })
}

fn all_players_passed_except_one(players: List(Player)) -> Bool {
  let passed_count =
    list.filter(players, fn(p) { p.has_passed })
    |> list.length

  passed_count >= list.length(players) - 1
}

fn reset_all_passes(players: List(Player)) -> List(Player) {
  list.map(players, fn(p) { Player(..p, has_passed: False) })
}

fn auto_finish_last_player(players: List(Player)) -> List(Player) {
  // Find unfinished players
  let unfinished =
    list.filter(players, fn(p) {
      case p.finished_position {
        None -> True
        Some(_) -> False
      }
    })

  case unfinished {
    // Exactly one unfinished player - auto-assign last position
    [last_player] -> {
      let next_position =
        list.filter(players, fn(p) {
          case p.finished_position {
            Some(_) -> True
            None -> False
          }
        })
        |> list.length
        |> fn(count) { count + 1 }

      let finished_last_player =
        Player(..last_player, finished_position: Some(next_position))

      replace_player(players, finished_last_player)
    }
    // No unfinished or multiple unfinished - return as is
    _ -> players
  }
}

fn find_last_player_who_played(state: game_types.GameState) -> Int {
  case state.last_play {
    Some(play) -> {
      // Find the index of the player who made the last play
      list.index_fold(state.players, state.current_player_index, fn(acc, p, idx) {
        case id.player_id_eq(p.id, play.player_id) {
          True -> idx
          False -> acc
        }
      })
    }
    None -> state.current_player_index
  }
}

fn create_pending_exchanges(players: List(game_types.Player)) -> List(game_types.PendingExchange) {
  // Find President, VP, VT, Trouduc
  let president = list.find(players, fn(p) { p.role == Some(President) })
  let vp = list.find(players, fn(p) { p.role == Some(VicePresident) })
  let vt = list.find(players, fn(p) { p.role == Some(ViceTrouduc) })
  let trouduc = list.find(players, fn(p) { p.role == Some(Trouduc) })

  let mut_exchanges = []

  // Trouduc -> President (2 cards)
  let mut_exchanges = case president, trouduc {
    Ok(pres), Ok(trou) -> [
      PendingExchange(trou.id, pres.id, 2, game_types.Best, False),
      ..mut_exchanges
    ]
    _, _ -> mut_exchanges
  }

  // ViceTrouduc -> VicePresident (1 card)
  let mut_exchanges = case vp, vt {
    Ok(vice_pres), Ok(vice_trou) -> [
      PendingExchange(vice_trou.id, vice_pres.id, 1, game_types.Best, False),
      ..mut_exchanges
    ]
    _, _ -> mut_exchanges
  }

  mut_exchanges
}

fn find_player_with_role_index(
  players: List(Player),
  role: game_types.Role,
) -> Int {
  list.index_fold(players, 0, fn(acc, p, idx) {
    case p.role == Some(role) {
      True -> idx
      False -> acc
    }
  })
}

/// Validate card conservation invariant (52 cards total)
/// This ensures no cards are lost or duplicated during gameplay
pub fn validate_card_conservation(state: game_types.GameState) -> Result(Nil, String) {
  let cards_in_hands =
    list.fold(state.players, 0, fn(acc, p) { acc + list.length(p.hand) })

  let cards_in_pile = list.length(state.discard_pile)

  let total = cards_in_hands + cards_in_pile

  case total == 52 {
    True -> Ok(Nil)
    False ->
      Error(
        "Card conservation violated: "
        <> int.to_string(total)
        <> " cards (expected 52)",
      )
  }
}

fn phase_to_string(phase: GamePhase) -> String {
  case phase {
    WaitingForPlayers -> "WaitingForPlayers"
    game_types.CardExchange(_) -> "CardExchange"
    Playing -> "Playing"
    RoundOver(_) -> "RoundOver"
    GameOver(_) -> "GameOver"
  }
}
