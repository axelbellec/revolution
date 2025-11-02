import gleam/dict
import gleam/order
import gleeunit/should
import revolution/game/scoring
import revolution/game/types.{
  BottomRole, FourthRole, MiddleRole, SecondRole, TopRole,
}
import revolution/utils/id

pub fn assign_roles_3_players_test() {
  let finishing_order = [
    id.player_id("alice"),
    id.player_id("bob"),
    id.player_id("carol"),
  ]

  let roles = scoring.assign_roles(finishing_order, 3)

  // Alice (1st) should be TopRole
  dict.get(roles, id.player_id("alice"))
  |> should.equal(Ok(TopRole))

  // Bob (2nd) should be MiddleRole
  dict.get(roles, id.player_id("bob"))
  |> should.equal(Ok(MiddleRole))

  // Carol (3rd) should be BottomRole
  dict.get(roles, id.player_id("carol"))
  |> should.equal(Ok(BottomRole))
}

pub fn assign_roles_4_players_test() {
  let finishing_order = [
    id.player_id("alice"),
    id.player_id("bob"),
    id.player_id("carol"),
    id.player_id("dave"),
  ]

  let roles = scoring.assign_roles(finishing_order, 4)

  // Alice (1st) should be TopRole
  dict.get(roles, id.player_id("alice"))
  |> should.equal(Ok(TopRole))

  // Bob (2nd) should be MiddleRole
  dict.get(roles, id.player_id("bob"))
  |> should.equal(Ok(MiddleRole))

  // Carol (3rd) should be MiddleRole
  dict.get(roles, id.player_id("carol"))
  |> should.equal(Ok(MiddleRole))

  // Dave (4th) should be BottomRole
  dict.get(roles, id.player_id("dave"))
  |> should.equal(Ok(BottomRole))
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

  // Alice (1st) -> TopRole
  dict.get(roles, id.player_id("alice"))
  |> should.equal(Ok(TopRole))

  // Bob (2nd) -> SecondRole
  dict.get(roles, id.player_id("bob"))
  |> should.equal(Ok(SecondRole))

  // Carol (3rd) -> MiddleRole
  dict.get(roles, id.player_id("carol"))
  |> should.equal(Ok(MiddleRole))

  // Dave (4th) -> FourthRole
  dict.get(roles, id.player_id("dave"))
  |> should.equal(Ok(FourthRole))

  // Eve (5th) -> BottomRole
  dict.get(roles, id.player_id("eve"))
  |> should.equal(Ok(BottomRole))
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

  // Alice (1st) -> TopRole
  dict.get(roles, id.player_id("alice"))
  |> should.equal(Ok(TopRole))

  // Bob (2nd) -> SecondRole
  dict.get(roles, id.player_id("bob"))
  |> should.equal(Ok(SecondRole))

  // Carol (3rd) -> MiddleRole
  dict.get(roles, id.player_id("carol"))
  |> should.equal(Ok(MiddleRole))

  // Dave (4th) -> MiddleRole
  dict.get(roles, id.player_id("dave"))
  |> should.equal(Ok(MiddleRole))

  // Eve (5th) -> FourthRole
  dict.get(roles, id.player_id("eve"))
  |> should.equal(Ok(FourthRole))

  // Frank (6th) -> BottomRole
  dict.get(roles, id.player_id("frank"))
  |> should.equal(Ok(BottomRole))
}

pub fn should_give_cards_test() {
  scoring.should_give_cards(BottomRole)
  |> should.be_true

  scoring.should_give_cards(FourthRole)
  |> should.be_true

  scoring.should_give_cards(TopRole)
  |> should.be_false

  scoring.should_give_cards(MiddleRole)
  |> should.be_false
}

pub fn should_receive_cards_test() {
  scoring.should_receive_cards(TopRole)
  |> should.be_true

  scoring.should_receive_cards(SecondRole)
  |> should.be_true

  scoring.should_receive_cards(BottomRole)
  |> should.be_false

  scoring.should_receive_cards(MiddleRole)
  |> should.be_false
}

pub fn get_exchange_target_test() {
  scoring.get_exchange_target(BottomRole)
  |> should.equal(Ok(TopRole))

  scoring.get_exchange_target(FourthRole)
  |> should.equal(Ok(SecondRole))

  scoring.get_exchange_target(MiddleRole)
  |> should.be_error
}

pub fn get_exchange_count_test() {
  scoring.get_exchange_count(BottomRole)
  |> should.equal(2)

  scoring.get_exchange_count(FourthRole)
  |> should.equal(1)

  scoring.get_exchange_count(TopRole)
  |> should.equal(2)

  scoring.get_exchange_count(SecondRole)
  |> should.equal(1)

  scoring.get_exchange_count(MiddleRole)
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
  scoring.role_hierarchy_value(TopRole)
  |> should.equal(5)

  scoring.role_hierarchy_value(SecondRole)
  |> should.equal(4)

  scoring.role_hierarchy_value(MiddleRole)
  |> should.equal(3)

  scoring.role_hierarchy_value(FourthRole)
  |> should.equal(2)

  scoring.role_hierarchy_value(BottomRole)
  |> should.equal(1)
}

pub fn compare_roles_test() {
  scoring.compare_roles(TopRole, BottomRole)
  |> should.equal(order.Gt)

  scoring.compare_roles(BottomRole, TopRole)
  |> should.equal(order.Lt)

  scoring.compare_roles(MiddleRole, MiddleRole)
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
