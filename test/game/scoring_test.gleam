import gleam/dict
import gleam/order
import gleeunit/should
import revolution/game/scoring
import revolution/game/types.{
  Neutral, President, Trouduc, VicePresident, ViceTrouduc,
}
import revolution/utils/id

pub fn assign_roles_3_players_test() {
  let finishing_order = [
    id.player_id("alice"),
    id.player_id("bob"),
    id.player_id("carol"),
  ]

  let roles = scoring.assign_roles(finishing_order, 3)

  // Alice (1st) should be President
  dict.get(roles, id.player_id("alice"))
  |> should.equal(Ok(President))

  // Bob (2nd) should be Neutral
  dict.get(roles, id.player_id("bob"))
  |> should.equal(Ok(Neutral))

  // Carol (3rd) should be Trouduc
  dict.get(roles, id.player_id("carol"))
  |> should.equal(Ok(Trouduc))
}

pub fn assign_roles_4_players_test() {
  let finishing_order = [
    id.player_id("alice"),
    id.player_id("bob"),
    id.player_id("carol"),
    id.player_id("dave"),
  ]

  let roles = scoring.assign_roles(finishing_order, 4)

  // Alice (1st) should be President
  dict.get(roles, id.player_id("alice"))
  |> should.equal(Ok(President))

  // Bob (2nd) should be Neutral
  dict.get(roles, id.player_id("bob"))
  |> should.equal(Ok(Neutral))

  // Carol (3rd) should be Neutral
  dict.get(roles, id.player_id("carol"))
  |> should.equal(Ok(Neutral))

  // Dave (4th) should be Trouduc
  dict.get(roles, id.player_id("dave"))
  |> should.equal(Ok(Trouduc))
}

pub fn assign_roles_5_players_test() {
  let finishing_order = [
    id.player_id("alice"),
    id.player_id("bob"),
    id.player_id("carol"),
    id.player_id("dave"),
    id.player_id("eve"),
  ]

  let roles = scoring.assign_roles(finishing_order, 5)

  // Alice (1st) -> President
  dict.get(roles, id.player_id("alice"))
  |> should.equal(Ok(President))

  // Bob (2nd) -> Vice-President
  dict.get(roles, id.player_id("bob"))
  |> should.equal(Ok(VicePresident))

  // Carol (3rd) -> Neutral
  dict.get(roles, id.player_id("carol"))
  |> should.equal(Ok(Neutral))

  // Dave (4th) -> Vice-Trouduc
  dict.get(roles, id.player_id("dave"))
  |> should.equal(Ok(ViceTrouduc))

  // Eve (5th) -> Trouduc
  dict.get(roles, id.player_id("eve"))
  |> should.equal(Ok(Trouduc))
}

pub fn assign_roles_6_players_test() {
  let finishing_order = [
    id.player_id("alice"),
    id.player_id("bob"),
    id.player_id("carol"),
    id.player_id("dave"),
    id.player_id("eve"),
    id.player_id("frank"),
  ]

  let roles = scoring.assign_roles(finishing_order, 6)

  // Alice (1st) -> President
  dict.get(roles, id.player_id("alice"))
  |> should.equal(Ok(President))

  // Bob (2nd) -> Vice-President
  dict.get(roles, id.player_id("bob"))
  |> should.equal(Ok(VicePresident))

  // Carol (3rd) -> Neutral
  dict.get(roles, id.player_id("carol"))
  |> should.equal(Ok(Neutral))

  // Dave (4th) -> Neutral
  dict.get(roles, id.player_id("dave"))
  |> should.equal(Ok(Neutral))

  // Eve (5th) -> Vice-Trouduc
  dict.get(roles, id.player_id("eve"))
  |> should.equal(Ok(ViceTrouduc))

  // Frank (6th) -> Trouduc
  dict.get(roles, id.player_id("frank"))
  |> should.equal(Ok(Trouduc))
}

pub fn should_give_cards_test() {
  scoring.should_give_cards(Trouduc)
  |> should.be_true

  scoring.should_give_cards(ViceTrouduc)
  |> should.be_true

  scoring.should_give_cards(President)
  |> should.be_false

  scoring.should_give_cards(Neutral)
  |> should.be_false
}

pub fn should_receive_cards_test() {
  scoring.should_receive_cards(President)
  |> should.be_true

  scoring.should_receive_cards(VicePresident)
  |> should.be_true

  scoring.should_receive_cards(Trouduc)
  |> should.be_false

  scoring.should_receive_cards(Neutral)
  |> should.be_false
}

pub fn get_exchange_target_test() {
  scoring.get_exchange_target(Trouduc)
  |> should.equal(Ok(President))

  scoring.get_exchange_target(ViceTrouduc)
  |> should.equal(Ok(VicePresident))

  scoring.get_exchange_target(Neutral)
  |> should.be_error
}

pub fn get_exchange_count_test() {
  scoring.get_exchange_count(Trouduc)
  |> should.equal(2)

  scoring.get_exchange_count(ViceTrouduc)
  |> should.equal(1)

  scoring.get_exchange_count(President)
  |> should.equal(2)

  scoring.get_exchange_count(VicePresident)
  |> should.equal(1)

  scoring.get_exchange_count(Neutral)
  |> should.equal(0)
}

pub fn has_vice_roles_test() {
  scoring.has_vice_roles(3)
  |> should.be_false

  scoring.has_vice_roles(4)
  |> should.be_false

  scoring.has_vice_roles(5)
  |> should.be_true

  scoring.has_vice_roles(6)
  |> should.be_true
}

pub fn role_hierarchy_value_test() {
  scoring.role_hierarchy_value(President)
  |> should.equal(5)

  scoring.role_hierarchy_value(VicePresident)
  |> should.equal(4)

  scoring.role_hierarchy_value(Neutral)
  |> should.equal(3)

  scoring.role_hierarchy_value(ViceTrouduc)
  |> should.equal(2)

  scoring.role_hierarchy_value(Trouduc)
  |> should.equal(1)
}

pub fn compare_roles_test() {
  scoring.compare_roles(President, Trouduc)
  |> should.equal(order.Gt)

  scoring.compare_roles(Trouduc, President)
  |> should.equal(order.Lt)

  scoring.compare_roles(Neutral, Neutral)
  |> should.equal(order.Eq)
}

pub fn get_neutral_count_test() {
  scoring.get_neutral_count(3)
  |> should.equal(1)

  scoring.get_neutral_count(4)
  |> should.equal(2)

  scoring.get_neutral_count(5)
  |> should.equal(1)

  scoring.get_neutral_count(6)
  |> should.equal(2)
}
