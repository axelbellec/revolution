import gleam/list
import gleam/option
import gleam/result
import gleeunit/should
import revolution/game/engine
import revolution/game/types.{Playing, WaitingForPlayers} as game_types
import revolution/utils/id

// Helper function to get player at specific index
fn get_player_at(
  players: List(game_types.Player),
  index: Int,
) -> Result(game_types.Player, Nil) {
  players
  |> list.drop(index)
  |> list.first
}

pub fn create_game_test() {
  let game_id = id.game_id("game1")
  let host_id = id.player_id("host")
  let config = game_types.default_config()

  let game = engine.create_game(game_id, host_id, config, 1_000_000)

  game.phase
  |> should.equal(WaitingForPlayers)

  game.players
  |> list.length
  |> should.equal(0)

  game.round_number
  |> should.equal(0)
}

pub fn add_player_test() {
  let game_id = id.game_id("game1")
  let host_id = id.player_id("host")
  let config = game_types.default_config()
  let game = engine.create_game(game_id, host_id, config, 1_000_000)

  let updated_game =
    engine.add_player(game, id.player_id("p1"), "Alice", 1_000_000)
    |> should.be_ok

  updated_game.players
  |> list.length
  |> should.equal(1)

  case updated_game.players {
    [player] -> {
      player.name
      |> should.equal("Alice")
    }
    _ -> should.fail()
  }
}

pub fn add_multiple_players_test() {
  let game_id = id.game_id("game1")
  let host_id = id.player_id("host")
  let config = game_types.default_config()
  let game = engine.create_game(game_id, host_id, config, 1_000_000)

  let result =
    game
    |> engine.add_player(id.player_id("p1"), "Alice", 1_000_000)
    |> result.try(engine.add_player(_, id.player_id("p2"), "Bob", 1_000_000))
    |> result.try(engine.add_player(_, id.player_id("p3"), "Carol", 1_000_000))
    |> result.try(engine.add_player(_, id.player_id("p4"), "Dave", 1_000_000))

  case result {
    Ok(updated_game) -> {
      updated_game.players
      |> list.length
      |> should.equal(4)
    }
    Error(_) -> should.fail()
  }
}

pub fn add_player_when_full_fails_test() {
  let game_id = id.game_id("game1")
  let host_id = id.player_id("host")
  let config =
    game_types.GameConfig(..game_types.default_config(), max_players: 2)
  let game = engine.create_game(game_id, host_id, config, 1_000_000)

  let result =
    game
    |> engine.add_player(id.player_id("p1"), "Alice", 1_000_000)
    |> result.try(engine.add_player(_, id.player_id("p2"), "Bob", 1_000_000))
    |> result.try(engine.add_player(_, id.player_id("p3"), "Carol", 1_000_000))

  result
  |> should.be_error
}

pub fn start_game_test() {
  let game_id = id.game_id("game1")
  let host_id = id.player_id("host")
  let config = game_types.default_config()
  let game = engine.create_game(game_id, host_id, config, 1_000_000)

  let result =
    game
    |> engine.add_player(id.player_id("p1"), "Alice", 1_000_000)
    |> result.try(engine.add_player(_, id.player_id("p2"), "Bob", 1_000_000))
    |> result.try(engine.add_player(_, id.player_id("p3"), "Carol", 1_000_000))
    |> result.try(engine.add_player(_, id.player_id("p4"), "Dave", 1_000_000))
    |> result.try(engine.start_game(_, 42))

  case result {
    Ok(started_game) -> {
      started_game.phase
      |> should.equal(Playing)

      started_game.round_number
      |> should.equal(1)

      // Each player should have cards
      started_game.players
      |> list.all(fn(p) { !list.is_empty(p.hand) })
      |> should.be_true

      // Total cards should be 52
      let total_cards =
        list.fold(started_game.players, 0, fn(acc, p) {
          acc + list.length(p.hand)
        })

      total_cards
      |> should.equal(52)
    }
    Error(_) -> should.fail()
  }
}

pub fn start_game_not_enough_players_fails_test() {
  let game_id = id.game_id("game1")
  let host_id = id.player_id("host")
  let config = game_types.default_config()
  let game = engine.create_game(game_id, host_id, config, 1_000_000)

  let result =
    game
    |> engine.add_player(id.player_id("p1"), "Alice", 1_000_000)
    |> result.try(engine.add_player(_, id.player_id("p2"), "Bob", 1_000_000))
    |> result.try(engine.start_game(_, 42))

  // Only 2 players, need 3 minimum
  result
  |> should.be_error
}

pub fn play_cards_test() {
  // Create a game with 4 players and start it
  let game_id = id.game_id("game1")
  let host_id = id.player_id("host")
  let config = game_types.default_config()
  let game = engine.create_game(game_id, host_id, config, 1_000_000)

  let result =
    game
    |> engine.add_player(id.player_id("p1"), "Alice", 1_000_000)
    |> result.try(engine.add_player(_, id.player_id("p2"), "Bob", 1_000_000))
    |> result.try(engine.add_player(_, id.player_id("p3"), "Carol", 1_000_000))
    |> result.try(engine.add_player(_, id.player_id("p4"), "Dave", 1_000_000))
    |> result.try(engine.start_game(_, 42))

  case result {
    Ok(started_game) -> {
      // Get current player
      case list.first(started_game.players) {
        Ok(current_player) -> {
          // Try to play first card from hand
          case current_player.hand {
            [card, ..] -> {
              case
                engine.play_cards(
                  started_game,
                  current_player.id,
                  [card],
                  1_000_000,
                )
              {
                Ok(after_play) -> {
                  // Player hand should have one less card
                  case list.first(after_play.players) {
                    Ok(player_after) -> {
                      list.length(player_after.hand)
                      |> should.equal(list.length(current_player.hand) - 1)

                      // There should be a last play
                      after_play.last_play
                      |> should.not_equal(option.None)

                      // Play history should have one entry
                      after_play.play_history
                      |> list.length
                      |> should.equal(1)
                    }
                    Error(_) -> should.fail()
                  }
                }
                Error(_) -> should.fail()
              }
            }
            [] -> should.fail()
          }
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn play_cards_wrong_turn_fails_test() {
  let game_id = id.game_id("game1")
  let host_id = id.player_id("host")
  let config = game_types.default_config()
  let game = engine.create_game(game_id, host_id, config, 1_000_000)

  let started_game =
    game
    |> engine.add_player(id.player_id("p1"), "Alice", 1_000_000)
    |> result.try(engine.add_player(_, id.player_id("p2"), "Bob", 1_000_000))
    |> result.try(engine.add_player(_, id.player_id("p3"), "Carol", 1_000_000))
    |> result.try(engine.add_player(_, id.player_id("p4"), "Dave", 1_000_000))
    |> result.try(engine.start_game(_, 42))
    |> should.be_ok

  // Get second player (not current turn)
  let second_player = get_player_at(started_game.players, 1) |> should.be_ok

  let assert [card, ..] = second_player.hand

  // Try to play when it's not their turn
  engine.play_cards(started_game, second_player.id, [card], 1_000_000)
  |> should.be_error
}

pub fn pass_turn_test() {
  let game_id = id.game_id("game1")
  let host_id = id.player_id("host")
  let config = game_types.default_config()
  let game = engine.create_game(game_id, host_id, config, 1_000_000)

  let result =
    game
    |> engine.add_player(id.player_id("p1"), "Alice", 1_000_000)
    |> result.try(engine.add_player(_, id.player_id("p2"), "Bob", 1_000_000))
    |> result.try(engine.add_player(_, id.player_id("p3"), "Carol", 1_000_000))
    |> result.try(engine.add_player(_, id.player_id("p4"), "Dave", 1_000_000))
    |> result.try(engine.start_game(_, 42))

  case result {
    Ok(started_game) -> {
      // First player makes a play
      case list.first(started_game.players) {
        Ok(first_player) -> {
          case first_player.hand {
            [card, ..] -> {
              case
                engine.play_cards(
                  started_game,
                  first_player.id,
                  [card],
                  1_000_000,
                )
              {
                Ok(after_first_play) -> {
                  // Second player passes
                  case get_player_at(after_first_play.players, 1) {
                    Ok(second_player) -> {
                      case
                        engine.pass_turn(after_first_play, second_player.id)
                      {
                        Ok(after_pass) -> {
                          // Second player should be marked as passed
                          case get_player_at(after_pass.players, 1) {
                            Ok(player_after_pass) -> {
                              player_after_pass.has_passed
                              |> should.be_true
                            }
                            Error(_) -> should.fail()
                          }
                        }
                        Error(_) -> should.fail()
                      }
                    }
                    Error(_) -> should.fail()
                  }
                }
                Error(_) -> should.fail()
              }
            }
            [] -> should.fail()
          }
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn cannot_pass_starting_trick_test() {
  let game_id = id.game_id("game1")
  let host_id = id.player_id("host")
  let config = game_types.default_config()
  let game = engine.create_game(game_id, host_id, config, 1_000_000)

  let started_game =
    game
    |> engine.add_player(id.player_id("p1"), "Alice", 1_000_000)
    |> result.try(engine.add_player(_, id.player_id("p2"), "Bob", 1_000_000))
    |> result.try(engine.add_player(_, id.player_id("p3"), "Carol", 1_000_000))
    |> result.try(engine.add_player(_, id.player_id("p4"), "Dave", 1_000_000))
    |> result.try(engine.start_game(_, 42))
    |> should.be_ok

  // First player tries to pass (starting a trick)
  let first_player = list.first(started_game.players) |> should.be_ok

  engine.pass_turn(started_game, first_player.id)
  |> should.be_error
}

// Card conservation tests

pub fn card_conservation_after_game_start_test() {
  let game_id = id.game_id("game1")
  let host_id = id.player_id("host")
  let config = game_types.default_config()
  let game = engine.create_game(game_id, host_id, config, 1_000_000)

  let started_game =
    game
    |> engine.add_player(id.player_id("p1"), "Alice", 1_000_000)
    |> result.try(engine.add_player(_, id.player_id("p2"), "Bob", 1_000_000))
    |> result.try(engine.add_player(_, id.player_id("p3"), "Carol", 1_000_000))
    |> result.try(engine.add_player(_, id.player_id("p4"), "Dave", 1_000_000))
    |> result.try(engine.start_game(_, 42))
    |> should.be_ok

  // Validate all 52 cards are accounted for
  engine.validate_card_conservation(started_game)
  |> should.be_ok
}

pub fn card_conservation_empty_game_test() {
  let game_id = id.game_id("game1")
  let host_id = id.player_id("host")
  let config = game_types.default_config()
  let game = engine.create_game(game_id, host_id, config, 1_000_000)

  // Game with no cards dealt should fail conservation check
  engine.validate_card_conservation(game)
  |> should.be_error
}
