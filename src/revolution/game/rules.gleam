/// Play validation and exchange validation rules

import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/order.{Eq, Gt, Lt}
import revolution/error/types.{
  type GameError, CardsNotInHand, InvalidExchange, InvalidPlay,
}
import revolution/game/deck
import revolution/game/types.{
  type Card, type ExchangeQuality, type Play, type Rank, Any, Best, Two,
} as game_types

/// Validate a play against the last play
pub fn validate_play(
  cards: List(Card),
  last_play: Option(Play),
  revolution_active: Bool,
) -> Result(Nil, GameError) {
  // Check that all cards are the same rank
  case deck.all_same_rank(cards) {
    False -> Error(InvalidPlay("All cards must be the same rank"))
    True -> {
      // Check if 2s are being played (always valid, clears pile)
      case cards {
        [] -> Error(InvalidPlay("Must play at least one card"))
        [first, ..] -> {
          case first.rank == Two {
            True -> Ok(Nil)
            False -> validate_play_rank(cards, last_play, revolution_active)
          }
        }
      }
    }
  }
}

/// Validate play rank against last play
fn validate_play_rank(
  cards: List(Card),
  last_play: Option(Play),
  revolution_active: Bool,
) -> Result(Nil, GameError) {
  case last_play {
    option.None -> Ok(Nil)
    option.Some(last) -> {
      // Check card count matches
      let last_count = list.length(last.cards)
      let new_count = list.length(cards)

      case new_count == last_count {
        False ->
          Error(InvalidPlay(
            "Must play same number of cards as last play ("
            <> int.to_string(last_count)
            <> ")",
          ))
        True -> {
          // Compare ranks
          case cards, last.cards {
            [new_card, ..], [last_card, ..] -> {
              case game_types.compare_rank(new_card.rank, last_card.rank, revolution_active) {
                Gt -> Ok(Nil)
                Eq -> Error(InvalidPlay("Must play higher rank than last play"))
                Lt -> Error(InvalidPlay("Must play higher rank than last play"))
              }
            }
            _, _ -> Error(InvalidPlay("Invalid card play"))
          }
        }
      }
    }
  }
}

/// Check if a play clears the pile
pub fn clears_pile(cards: List(Card)) -> Bool {
  case cards {
    [] -> False
    [first, ..] -> {
      // 2s always clear pile, even during revolution
      case first.rank == Two {
        True -> True
        False -> {
          // Four of a kind triggers revolution and clears pile (if enabled)
          list.length(cards) == 4 && deck.all_same_rank(cards)
        }
      }
    }
  }
}

/// Check if a play triggers revolution (four of a kind, not 2s)
pub fn triggers_revolution(cards: List(Card)) -> Bool {
  case cards {
    [first, ..] -> {
      case first.rank == Two {
        True -> False
        False -> list.length(cards) == 4 && deck.all_same_rank(cards)
      }
    }
    [] -> False
  }
}

/// Validate card exchange
/// Ensures that lower-ranked players give their "best" cards
pub fn validate_exchange(
  cards: List(Card),
  quality: ExchangeQuality,
  hand: List(Card),
  revolution_active: Bool,
) -> Result(Nil, GameError) {
  // Check if cards are in hand
  case deck.contains_cards(hand, cards) {
    False -> Error(CardsNotInHand(list.length(cards)))
    True -> {
      case quality {
        Any -> Ok(Nil)
        Best -> validate_best_cards(cards, hand, revolution_active)
      }
    }
  }
}

/// Validate that given cards are among the highest in the hand
fn validate_best_cards(
  cards: List(Card),
  hand: List(Card),
  revolution_active: Bool,
) -> Result(Nil, GameError) {
  let sorted_hand = deck.sort_by_rank(hand, revolution_active)
  let num_cards = list.length(cards)
  let expected_best = list.take(sorted_hand, num_cards)

  // Check if given cards match the top N cards
  case sets_are_equal(cards, expected_best) {
    True -> Ok(Nil)
    False -> {
      let expected_ranks = format_ranks(expected_best)
      Error(InvalidExchange(
        "Must give your highest cards. Expected cards ranked: "
        <> expected_ranks,
      ))
    }
  }
}

/// Check if two sets of cards are equal (ignoring order)
fn sets_are_equal(a: List(Card), b: List(Card)) -> Bool {
  list.length(a) == list.length(b)
  && list.all(a, fn(card) { list.contains(b, card) })
}

/// Format card ranks for error messages
fn format_ranks(cards: List(game_types.Card)) -> String {
  case cards {
    [] -> ""
    [card] -> game_types.rank_to_string(card.rank)
    [first, ..rest] ->
      game_types.rank_to_string(first.rank)
      <> ", "
      <> format_ranks(rest)
  }
}

/// Validate that player has cards in hand
pub fn validate_cards_in_hand(
  cards: List(Card),
  hand: List(Card),
) -> Result(Nil, GameError) {
  case deck.contains_cards(hand, cards) {
    True -> Ok(Nil)
    False -> Error(CardsNotInHand(list.length(cards)))
  }
}

/// Check if a player can pass
pub fn can_pass(is_starting_new_trick: Bool) -> Result(Nil, GameError) {
  case is_starting_new_trick {
    True -> Error(InvalidPlay("Cannot pass when starting a new trick"))
    False -> Ok(Nil)
  }
}

/// Get the rank of a card list (assumes all same rank)
pub fn get_play_rank(cards: List(Card)) -> Result(Rank, Nil) {
  case cards {
    [first, ..] -> Ok(first.rank)
    [] -> Error(Nil)
  }
}
