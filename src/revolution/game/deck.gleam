/// Card deck operations: creation, shuffling, dealing
import gleam/int
import gleam/list
import gleam/order
import gleam/result
import revolution/game/types.{
  type Card, type Player, type Rank, Ace, Card, Clubs, Diamonds, Eight, Five,
  Four, Hearts, Jack, King, Nine, Queen, Seven, Six, Spades, Ten, Three, Two,
}

/// Create a standard 52-card deck
pub fn create_deck() -> List(Card) {
  let ranks = [
    Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace, Two,
  ]
  let suits = [Hearts, Diamonds, Clubs, Spades]

  list.flat_map(ranks, fn(rank) {
    list.map(suits, fn(suit) { Card(rank, suit) })
  })
}

/// Shuffle a deck using a seed for deterministic randomness
/// In production, this would use crypto-secure random
pub fn shuffle(deck: List(Card), seed: Int) -> List(Card) {
  // Simple Fisher-Yates shuffle with deterministic seed
  shuffle_helper(deck, [], seed, list.length(deck))
}

fn shuffle_helper(
  remaining: List(Card),
  shuffled: List(Card),
  seed: Int,
  count: Int,
) -> List(Card) {
  case remaining {
    [] -> shuffled
    _ -> {
      let index = simple_random(seed, count) % count
      case list_take_at(remaining, index) {
        Ok(#(card, rest)) ->
          shuffle_helper(rest, [card, ..shuffled], seed + 1, count - 1)
        Error(_) -> shuffled
      }
    }
  }
}

// Linear Congruential Generator constants (Numerical Recipes)
const lcg_multiplier = 1_103_515_245

const lcg_increment = 12_345

const lcg_modulus = 2_147_483_647

/// Simple pseudo-random number generator for deterministic shuffling
fn simple_random(seed: Int, max: Int) -> Int {
  // Linear congruential generator for deterministic randomness
  { seed * lcg_multiplier + lcg_increment } % lcg_modulus % int.max(max, 1)
}

/// Take element at index and return it with the remaining list
fn list_take_at(lst: List(a), index: Int) -> Result(#(a, List(a)), Nil) {
  case index {
    0 ->
      case lst {
        [first, ..rest] -> Ok(#(first, rest))
        [] -> Error(Nil)
      }
    _ ->
      case lst {
        [first, ..rest] ->
          case list_take_at(rest, index - 1) {
            Ok(#(elem, remaining)) -> Ok(#(elem, [first, ..remaining]))
            Error(_) -> Error(Nil)
          }
        [] -> Error(Nil)
      }
  }
}

/// Deal cards evenly to players
pub fn deal_cards(
  deck: List(Card),
  players: List(Player),
) -> Result(List(Player), String) {
  let player_count = list.length(players)
  case player_count {
    0 -> Error("Cannot deal to zero players")
    _ -> {
      let cards_per_player = list.length(deck) / player_count
      deal_to_players(deck, players, cards_per_player, [])
    }
  }
}

fn deal_to_players(
  deck: List(Card),
  players: List(Player),
  cards_per_player: Int,
  dealt: List(Player),
) -> Result(List(Player), String) {
  case players {
    [] -> Ok(list.reverse(dealt))
    [player, ..rest_players] -> {
      let hand = list.take(deck, cards_per_player)
      let remaining_deck = list.drop(deck, cards_per_player)
      let updated_player = types.Player(..player, hand: hand)
      deal_to_players(remaining_deck, rest_players, cards_per_player, [
        updated_player,
        ..dealt
      ])
    }
  }
}

/// Sort cards by rank (for display and exchange validation)
pub fn sort_by_rank(cards: List(Card), revolution_active: Bool) -> List(Card) {
  list.sort(cards, fn(a, b) {
    case types.compare_rank(a.rank, b.rank, revolution_active) {
      order.Lt -> order.Gt
      order.Eq -> order.Eq
      order.Gt -> order.Lt
    }
  })
}

/// Check if all cards in a list are the same rank
pub fn all_same_rank(cards: List(Card)) -> Bool {
  case cards {
    [] -> True
    [first, ..rest] -> list.all(rest, fn(c) { c.rank == first.rank })
  }
}

/// Count cards of a specific rank in a hand
pub fn count_rank(hand: List(Card), rank: Rank) -> Int {
  list.filter(hand, fn(c) { c.rank == rank })
  |> list.length
}

/// Get all cards of a specific rank from a hand
pub fn cards_of_rank(hand: List(Card), rank: Rank) -> List(Card) {
  list.filter(hand, fn(c) { c.rank == rank })
}

/// Check if a hand contains specific cards
pub fn contains_cards(hand: List(Card), cards: List(Card)) -> Bool {
  list.all(cards, fn(card) { list.contains(hand, card) })
}

/// Remove cards from a hand
pub fn remove_cards(hand: List(Card), to_remove: List(Card)) -> List(Card) {
  list.filter(hand, fn(card) { !list.contains(to_remove, card) })
}

/// Check if two cards are equal
pub fn card_eq(a: Card, b: Card) -> Bool {
  a.rank == b.rank && a.suit == b.suit
}

/// Get unique cards (remove duplicates)
pub fn unique_cards(cards: List(Card)) -> List(Card) {
  unique_helper(cards, [])
}

fn unique_helper(cards: List(Card), acc: List(Card)) -> List(Card) {
  case cards {
    [] -> list.reverse(acc)
    [first, ..rest] -> {
      case list.any(acc, fn(c) { card_eq(c, first) }) {
        True -> unique_helper(rest, acc)
        False -> unique_helper(rest, [first, ..acc])
      }
    }
  }
}

/// Validate that deck has correct number of cards
pub fn validate_deck_size(deck: List(Card)) -> Result(Nil, String) {
  case list.length(deck) {
    52 -> Ok(Nil)
    n -> Error("Invalid deck size: expected 52 cards, got " <> int.to_string(n))
  }
}

/// Validate that all cards are unique
pub fn validate_unique_cards(deck: List(Card)) -> Result(Nil, String) {
  let unique = unique_cards(deck)
  case list.length(unique) == list.length(deck) {
    True -> Ok(Nil)
    False -> Error("Deck contains duplicate cards")
  }
}

/// Full deck validation
pub fn validate_deck(deck: List(Card)) -> Result(Nil, String) {
  result.try(validate_deck_size(deck), fn(_) { validate_unique_cards(deck) })
}
