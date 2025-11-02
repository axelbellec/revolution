import gleam/list
import gleam/option
import gleeunit/should
import revolution/game/deck
import revolution/game/types.{
  Card, Connected, Hearts, Player, Seven, Spades, Three, Two,
}
import revolution/utils/id

pub fn create_deck_test() {
  let deck = deck.create_deck()

  // Should have 52 cards
  list.length(deck)
  |> should.equal(52)

  // Should validate correctly
  deck.validate_deck(deck)
  |> should.be_ok
}

pub fn deck_has_all_ranks_test() {
  let deck = deck.create_deck()

  // Should have 4 of each rank (4 suits)
  deck.count_rank(deck, types.Three)
  |> should.equal(4)

  deck.count_rank(deck, types.Two)
  |> should.equal(4)

  deck.count_rank(deck, types.Ace)
  |> should.equal(4)
}

pub fn shuffle_changes_order_test() {
  let deck = deck.create_deck()
  let shuffled = deck.shuffle(deck, 42)

  // Shuffled deck should be different order
  deck
  |> should.not_equal(shuffled)

  // But should still have same cards
  list.length(shuffled)
  |> should.equal(52)

  deck.validate_deck(shuffled)
  |> should.be_ok
}

pub fn shuffle_is_deterministic_test() {
  let deck = deck.create_deck()
  let shuffled1 = deck.shuffle(deck, 42)
  let shuffled2 = deck.shuffle(deck, 42)

  // Same seed should produce same shuffle
  shuffled1
  |> should.equal(shuffled2)
}

pub fn shuffle_different_seeds_test() {
  let deck = deck.create_deck()
  let shuffled1 = deck.shuffle(deck, 42)
  let shuffled2 = deck.shuffle(deck, 99)

  // Different seeds should produce different shuffles
  shuffled1
  |> should.not_equal(shuffled2)
}

pub fn deal_cards_evenly_test() {
  let deck = deck.create_deck()
  let players = [
    Player(
      id: id.player_id("p1"),
      name: "Alice",
      hand: [],
      role: option.None,
      finished_position: option.None,
      connection_state: Connected(0),
      has_passed: False,
    ),
    Player(
      id: id.player_id("p2"),
      name: "Bob",
      hand: [],
      role: option.None,
      finished_position: option.None,
      connection_state: Connected(0),
      has_passed: False,
    ),
    Player(
      id: id.player_id("p3"),
      name: "Carol",
      hand: [],
      role: option.None,
      finished_position: option.None,
      connection_state: Connected(0),
      has_passed: False,
    ),
    Player(
      id: id.player_id("p4"),
      name: "Dave",
      hand: [],
      role: option.None,
      finished_position: option.None,
      connection_state: Connected(0),
      has_passed: False,
    ),
  ]

  case deck.deal_cards(deck, players) {
    Ok(dealt_players) -> {
      // Each player should have 13 cards (52 / 4)
      list.all(dealt_players, fn(p) { list.length(p.hand) == 13 })
      |> should.be_true

      // Total cards should still be 52
      let total_cards =
        list.fold(dealt_players, 0, fn(acc, p) { acc + list.length(p.hand) })

      total_cards
      |> should.equal(52)
    }
    Error(_) -> should.fail()
  }
}

pub fn all_same_rank_test() {
  let cards = [
    Card(Seven, Hearts),
    Card(Seven, Spades),
    Card(Seven, types.Diamonds),
  ]

  deck.all_same_rank(cards)
  |> should.be_true
}

pub fn not_all_same_rank_test() {
  let cards = [Card(Seven, Hearts), Card(Three, Spades)]

  deck.all_same_rank(cards)
  |> should.be_false
}

pub fn contains_cards_test() {
  let hand = [
    Card(Seven, Hearts),
    Card(Three, Spades),
    Card(Two, types.Clubs),
  ]
  let check = [Card(Seven, Hearts), Card(Two, types.Clubs)]

  deck.contains_cards(hand, check)
  |> should.be_true
}

pub fn not_contains_cards_test() {
  let hand = [Card(Seven, Hearts), Card(Three, Spades)]
  let check = [Card(Two, types.Clubs)]

  deck.contains_cards(hand, check)
  |> should.be_false
}

pub fn remove_cards_test() {
  let hand = [
    Card(Seven, Hearts),
    Card(Three, Spades),
    Card(Two, types.Clubs),
  ]
  let to_remove = [Card(Seven, Hearts)]

  let result = deck.remove_cards(hand, to_remove)

  list.length(result)
  |> should.equal(2)

  result
  |> should.equal([Card(Three, Spades), Card(Two, types.Clubs)])
}

pub fn sort_by_rank_normal_test() {
  let cards = [
    Card(Three, Hearts),
    Card(Seven, Spades),
    Card(types.Ace, types.Clubs),
  ]

  let sorted = deck.sort_by_rank(cards, False)

  // Should be Ace, Seven, Three (highest to lowest)
  case sorted {
    [first, second, third] -> {
      first.rank
      |> should.equal(types.Ace)

      second.rank
      |> should.equal(Seven)

      third.rank
      |> should.equal(Three)
    }
    _ -> should.fail()
  }
}

pub fn sort_by_rank_revolution_test() {
  let cards = [
    Card(Three, Hearts),
    Card(Seven, Spades),
    Card(types.Ace, types.Clubs),
  ]

  let sorted = deck.sort_by_rank(cards, True)

  // During revolution, Three is highest, Ace is lowest
  case sorted {
    [first, second, third] -> {
      first.rank
      |> should.equal(Three)

      second.rank
      |> should.equal(Seven)

      third.rank
      |> should.equal(types.Ace)
    }
    _ -> should.fail()
  }
}

pub fn validate_unique_cards_test() {
  let deck = deck.create_deck()

  deck.validate_unique_cards(deck)
  |> should.be_ok
}

pub fn validate_unique_cards_fails_with_duplicates_test() {
  let deck_with_duplicate = [
    Card(Seven, Hearts),
    Card(Seven, Hearts),
    Card(Three, Spades),
  ]

  deck.validate_unique_cards(deck_with_duplicate)
  |> should.be_error
}
