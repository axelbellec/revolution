import gleam/option
import gleeunit/should
import revolution/game/rules
import revolution/game/types.{
  Ace, Any, Best, Card, Clubs, Diamonds, Hearts, Play, Queen, Seven, Spades,
  Three, Two,
}
import revolution/utils/id

// Play validation tests

pub fn validate_play_higher_rank_test() {
  let last_play =
    option.Some(Play(
      player_id: id.player_id("p1"),
      cards: [Card(Seven, Hearts)],
      cleared_pile: False,
      timestamp: 0,
    ))

  let new_play = [Card(Queen, Clubs)]

  rules.validate_play(new_play, last_play, False)
  |> should.be_ok
}

pub fn validate_play_lower_rank_fails_test() {
  let last_play =
    option.Some(Play(
      player_id: id.player_id("p1"),
      cards: [Card(Queen, Hearts)],
      cleared_pile: False,
      timestamp: 0,
    ))

  let new_play = [Card(Seven, Clubs)]

  rules.validate_play(new_play, last_play, False)
  |> should.be_error
}

pub fn validate_play_same_rank_fails_test() {
  let last_play =
    option.Some(Play(
      player_id: id.player_id("p1"),
      cards: [Card(Seven, Hearts)],
      cleared_pile: False,
      timestamp: 0,
    ))

  let new_play = [Card(Seven, Clubs)]

  rules.validate_play(new_play, last_play, False)
  |> should.be_error
}

pub fn validate_play_pair_test() {
  let last_play =
    option.Some(Play(
      player_id: id.player_id("p1"),
      cards: [Card(Seven, Hearts), Card(Seven, Diamonds)],
      cleared_pile: False,
      timestamp: 0,
    ))

  let new_play = [Card(Queen, Clubs), Card(Queen, Spades)]

  rules.validate_play(new_play, last_play, False)
  |> should.be_ok
}

pub fn validate_play_wrong_count_fails_test() {
  let last_play =
    option.Some(Play(
      player_id: id.player_id("p1"),
      cards: [Card(Seven, Hearts), Card(Seven, Diamonds)],
      cleared_pile: False,
      timestamp: 0,
    ))

  // Trying to play 3 cards when last play was 2
  let new_play = [
    Card(Queen, Clubs),
    Card(Queen, Spades),
    Card(Queen, Hearts),
  ]

  rules.validate_play(new_play, last_play, False)
  |> should.be_error
}

pub fn validate_play_twos_always_valid_test() {
  let last_play =
    option.Some(Play(
      player_id: id.player_id("p1"),
      cards: [Card(Ace, Hearts)],
      cleared_pile: False,
      timestamp: 0,
    ))

  // 2s can beat Aces
  let new_play = [Card(Two, Clubs)]

  rules.validate_play(new_play, last_play, False)
  |> should.be_ok
}

pub fn validate_play_mixed_ranks_fails_test() {
  let new_play = [Card(Seven, Hearts), Card(Queen, Diamonds)]

  rules.validate_play(new_play, option.None, False)
  |> should.be_error
}

pub fn validate_play_first_play_test() {
  let new_play = [Card(Seven, Hearts)]

  // First play of trick should always be valid
  rules.validate_play(new_play, option.None, False)
  |> should.be_ok
}

// Revolution tests

pub fn validate_play_during_revolution_test() {
  let last_play =
    option.Some(Play(
      player_id: id.player_id("p1"),
      cards: [Card(Seven, Hearts)],
      cleared_pile: False,
      timestamp: 0,
    ))

  // During revolution, Three is higher than Seven
  let new_play = [Card(Three, Clubs)]

  rules.validate_play(new_play, last_play, True)
  |> should.be_ok
}

pub fn validate_play_revolution_ace_lower_than_three_test() {
  let last_play =
    option.Some(Play(
      player_id: id.player_id("p1"),
      cards: [Card(Three, Hearts)],
      cleared_pile: False,
      timestamp: 0,
    ))

  // During revolution, Ace is lower than Three
  let new_play = [Card(Ace, Clubs)]

  rules.validate_play(new_play, last_play, True)
  |> should.be_error
}

pub fn twos_clear_pile_normal_test() {
  let cards = [Card(Two, Hearts)]

  rules.clears_pile(cards)
  |> should.be_true
}

pub fn twos_clear_pile_during_revolution_test() {
  // CRITICAL TEST: 2s retain clearing power during revolution
  let cards = [Card(Two, Hearts)]

  rules.clears_pile(cards)
  |> should.be_true
}

pub fn four_of_kind_clears_pile_test() {
  let cards = [
    Card(Seven, Hearts),
    Card(Seven, Diamonds),
    Card(Seven, Clubs),
    Card(Seven, Spades),
  ]

  rules.clears_pile(cards)
  |> should.be_true
}

pub fn triggers_revolution_test() {
  let cards = [
    Card(Seven, Hearts),
    Card(Seven, Diamonds),
    Card(Seven, Clubs),
    Card(Seven, Spades),
  ]

  rules.triggers_revolution(cards)
  |> should.be_true
}

pub fn twos_dont_trigger_revolution_test() {
  let cards = [
    Card(Two, Hearts),
    Card(Two, Diamonds),
    Card(Two, Clubs),
    Card(Two, Spades),
  ]

  // Four 2s should NOT trigger revolution
  rules.triggers_revolution(cards)
  |> should.be_false
}

pub fn three_cards_dont_trigger_revolution_test() {
  let cards = [Card(Seven, Hearts), Card(Seven, Diamonds), Card(Seven, Clubs)]

  rules.triggers_revolution(cards)
  |> should.be_false
}

// Exchange validation tests

pub fn validate_exchange_any_quality_test() {
  let hand = [Card(Seven, Hearts), Card(Three, Spades), Card(Ace, Clubs)]
  let cards = [Card(Three, Spades), Card(Seven, Hearts)]

  // President can give any cards
  rules.validate_exchange(cards, Any, hand, False)
  |> should.be_ok
}

pub fn validate_exchange_best_cards_test() {
  let hand = [
    Card(Two, Hearts),
    Card(Ace, Spades),
    Card(types.King, Clubs),
    Card(Seven, Diamonds),
  ]
  let cards = [Card(Two, Hearts), Card(Ace, Spades)]

  // Trouduc must give best 2 cards
  rules.validate_exchange(cards, Best, hand, False)
  |> should.be_ok
}

pub fn validate_exchange_not_best_cards_fails_test() {
  let hand = [
    Card(Two, Hearts),
    Card(Ace, Spades),
    Card(types.King, Clubs),
    Card(Seven, Diamonds),
  ]
  let cards = [Card(types.King, Clubs), Card(Seven, Diamonds)]

  // Trying to give King and Seven when Two and Ace are better
  rules.validate_exchange(cards, Best, hand, False)
  |> should.be_error
}

pub fn validate_exchange_best_during_revolution_test() {
  let hand = [
    Card(Two, Hearts),
    Card(Ace, Spades),
    Card(Three, Clubs),
    Card(types.Four, Diamonds),
  ]
  // During revolution, Three and Four are best (highest)
  let cards = [Card(Three, Clubs), Card(types.Four, Diamonds)]

  rules.validate_exchange(cards, Best, hand, True)
  |> should.be_ok
}

pub fn validate_exchange_cards_not_in_hand_fails_test() {
  let hand = [Card(Seven, Hearts), Card(Three, Spades)]
  let cards = [Card(Ace, Clubs)]

  rules.validate_exchange(cards, Best, hand, False)
  |> should.be_error
}

// Can pass tests

pub fn can_pass_mid_trick_test() {
  rules.can_pass(False)
  |> should.be_ok
}

pub fn cannot_pass_starting_trick_test() {
  rules.can_pass(True)
  |> should.be_error
}

// Get play rank test

pub fn get_play_rank_test() {
  let cards = [Card(Seven, Hearts), Card(Seven, Diamonds)]

  rules.get_play_rank(cards)
  |> should.equal(Ok(Seven))
}

pub fn get_play_rank_empty_fails_test() {
  let cards = []

  rules.get_play_rank(cards)
  |> should.be_error
}
