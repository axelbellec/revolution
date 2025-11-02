/// Opaque ID types for type safety
/// Prevents mixing up different ID types at compile time
/// Opaque player identifier - cannot be confused with game IDs
pub opaque type PlayerId {
  PlayerId(String)
}

/// Opaque game identifier
pub opaque type GameId {
  GameId(String)
}

/// Opaque session token for reconnection
pub opaque type SessionToken {
  SessionToken(String)
}

// Constructor functions

/// Create a new PlayerId from a string
pub fn player_id(id: String) -> PlayerId {
  PlayerId(id)
}

/// Create a new GameId from a string
pub fn game_id(id: String) -> GameId {
  GameId(id)
}

/// Create a new SessionToken from a string
pub fn session_token(token: String) -> SessionToken {
  SessionToken(token)
}

// Accessor functions

/// Convert PlayerId to String
pub fn player_id_to_string(id: PlayerId) -> String {
  let PlayerId(s) = id
  s
}

/// Convert GameId to String
pub fn game_id_to_string(id: GameId) -> String {
  let GameId(s) = id
  s
}

/// Convert SessionToken to String
pub fn session_token_to_string(token: SessionToken) -> String {
  let SessionToken(s) = token
  s
}

// Comparison functions (needed for Dict/Set usage)

/// Compare two PlayerIds for equality
pub fn player_id_eq(a: PlayerId, b: PlayerId) -> Bool {
  player_id_to_string(a) == player_id_to_string(b)
}

/// Compare two GameIds for equality
pub fn game_id_eq(a: GameId, b: GameId) -> Bool {
  game_id_to_string(a) == game_id_to_string(b)
}
