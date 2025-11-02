/// Role assignment algorithm based on finishing order and player count
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None, Some}
import gleam/order.{type Order}
import revolution/game/types.{
  type Player, type Role, BottomRole, FourthRole, MiddleRole, Player, SecondRole,
  TopRole,
}
import revolution/utils/id.{type PlayerId}

/// Assign roles based on finishing order and player count
/// Implements the role assignment algorithm from SPECS.md section 1.3
pub fn assign_roles(
  finishing_order: List(PlayerId),
  player_count: Int,
) -> Dict(PlayerId, Role) {
  case player_count {
    3 -> assign_roles_3_players(finishing_order)
    4 -> assign_roles_4_players(finishing_order)
    5 -> assign_roles_5_players(finishing_order)
    6 -> assign_roles_6_players(finishing_order)
    _ -> dict.new()
  }
}

/// 3 players: Top, Middle, Bottom
fn assign_roles_3_players(
  finishing_order: List(PlayerId),
) -> Dict(PlayerId, Role) {
  case finishing_order {
    [first, second, third] ->
      dict.new()
      |> dict.insert(first, TopRole)
      |> dict.insert(second, MiddleRole)
      |> dict.insert(third, BottomRole)
    _ -> dict.new()
  }
}

/// 4 players: Top, Middle, Middle, Bottom
fn assign_roles_4_players(
  finishing_order: List(PlayerId),
) -> Dict(PlayerId, Role) {
  case finishing_order {
    [first, second, third, fourth] ->
      dict.new()
      |> dict.insert(first, TopRole)
      |> dict.insert(second, MiddleRole)
      |> dict.insert(third, MiddleRole)
      |> dict.insert(fourth, BottomRole)
    _ -> dict.new()
  }
}

/// 5 players: Top, Second, Middle, Fourth, Bottom
fn assign_roles_5_players(
  finishing_order: List(PlayerId),
) -> Dict(PlayerId, Role) {
  case finishing_order {
    [first, second, third, fourth, fifth] ->
      dict.new()
      |> dict.insert(first, TopRole)
      |> dict.insert(second, SecondRole)
      |> dict.insert(third, MiddleRole)
      |> dict.insert(fourth, FourthRole)
      |> dict.insert(fifth, BottomRole)
    _ -> dict.new()
  }
}

/// 6 players: Top, Second, Middle, Middle, Fourth, Bottom
fn assign_roles_6_players(
  finishing_order: List(PlayerId),
) -> Dict(PlayerId, Role) {
  case finishing_order {
    [first, second, third, fourth, fifth, sixth] ->
      dict.new()
      |> dict.insert(first, TopRole)
      |> dict.insert(second, SecondRole)
      |> dict.insert(third, MiddleRole)
      |> dict.insert(fourth, MiddleRole)
      |> dict.insert(fifth, FourthRole)
      |> dict.insert(sixth, BottomRole)
    _ -> dict.new()
  }
}

/// Apply roles to players after a round
pub fn apply_roles_to_players(
  players: List(Player),
  roles: Dict(PlayerId, Role),
) -> List(Player) {
  list.map(players, fn(player) {
    case dict.get(roles, player.id) {
      Ok(role) -> Player(..player, role: Some(role))
      Error(_) -> Player(..player, role: None)
    }
  })
}

/// Get player role from a player
pub fn get_player_role(player: Player) -> Result(Role, Nil) {
  case player.role {
    Some(role) -> Ok(role)
    None -> Error(Nil)
  }
}

/// Check if a role should give cards (lower hierarchy)
pub fn should_give_cards(role: Role) -> Bool {
  case role {
    BottomRole -> True
    FourthRole -> True
    _ -> False
  }
}

/// Check if a role should receive cards (higher hierarchy)
pub fn should_receive_cards(role: Role) -> Bool {
  case role {
    TopRole -> True
    SecondRole -> True
    _ -> False
  }
}

/// Get the role that should receive cards from this role
pub fn get_exchange_target(role: Role) -> Result(Role, Nil) {
  case role {
    BottomRole -> Ok(TopRole)
    FourthRole -> Ok(SecondRole)
    _ -> Error(Nil)
  }
}

/// Get the role that should give cards to this role
pub fn get_exchange_source(role: Role) -> Result(Role, Nil) {
  case role {
    TopRole -> Ok(BottomRole)
    SecondRole -> Ok(FourthRole)
    _ -> Error(Nil)
  }
}

/// Get number of cards to exchange for a role
pub fn get_exchange_count(role: Role) -> Int {
  case role {
    BottomRole -> 2
    FourthRole -> 1
    TopRole -> 2
    SecondRole -> 1
    MiddleRole -> 0
  }
}

/// Determine if player count supports VP/VT roles
pub fn has_vice_roles(player_count: Int) -> Bool {
  player_count >= 5
}

/// Get role hierarchy value (higher = better position)
pub fn role_hierarchy_value(role: Role) -> Int {
  case role {
    TopRole -> 5
    SecondRole -> 4
    MiddleRole -> 3
    FourthRole -> 2
    BottomRole -> 1
  }
}

/// Compare two roles by hierarchy
pub fn compare_roles(a: Role, b: Role) -> Order {
  let a_val = role_hierarchy_value(a)
  let b_val = role_hierarchy_value(b)

  case a_val == b_val, a_val < b_val {
    True, _ -> order.Eq
    _, True -> order.Lt
    _, False -> order.Gt
  }
}

/// Get all neutral players count for a given player count
pub fn get_neutral_count(player_count: Int) -> Int {
  case player_count {
    3 -> 1
    4 -> 2
    5 -> 1
    6 -> 2
    _ -> 0
  }
}
