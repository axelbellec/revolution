/// Error types and severity classification for the Revolution game

import gleam/int
import revolution/utils/id.{type PlayerId}

/// Game errors with detailed context
pub type GameError {
  /// Invalid play attempt with reason
  InvalidPlay(reason: String)
  /// Player attempted action when it's not their turn
  NotYourTurn
  /// Action performed in wrong game phase
  WrongPhase(expected: String, actual: String)
  /// Player not found in game
  PlayerNotFound(player_id: PlayerId)
  /// Card count mismatch (e.g., trying to play 2 cards when last play was 3)
  InvalidCardCount(expected: Int, actual: Int)
  /// Cards not in player's hand
  CardsNotInHand(card_count: Int)
  /// Cannot pass at this time
  CannotPassNow
  /// Game is full, cannot join
  GameFull
  /// Game has not started yet
  GameNotStarted
  /// Invalid card exchange
  InvalidExchange(reason: String)
  /// Message sequence number is invalid
  InvalidSequence(expected: Int, actual: Int)
  /// Duplicate action detected (idempotency check)
  DuplicateAction(idempotency_key: String)
  /// Session has expired
  SessionExpired
  /// Invalid session token
  InvalidSessionToken
  /// Rate limit exceeded
  RateLimitExceeded
}

/// Error severity determines recovery strategy
pub type ErrorSeverity {
  /// Show error to player, they can retry
  Recoverable
  /// Remove player, continue with others
  GameEnding
  /// Crash game room, requires restart
  Fatal
}

/// Recovery action to take based on severity
pub type RecoveryAction {
  /// Send error to client, keep connection
  ReturnError
  /// Disconnect player, update game state
  RemovePlayer
  /// Supervisor will restart with empty state
  CrashGameRoom
}

/// Map error to its severity level
pub fn error_severity(error: GameError) -> ErrorSeverity {
  case error {
    // Recoverable - player can fix and retry
    InvalidPlay(_) -> Recoverable
    NotYourTurn -> Recoverable
    WrongPhase(_, _) -> Recoverable
    InvalidCardCount(_, _) -> Recoverable
    CardsNotInHand(_) -> Recoverable
    CannotPassNow -> Recoverable
    InvalidExchange(_) -> Recoverable
    DuplicateAction(_) -> Recoverable

    // Game-ending - player should be removed
    PlayerNotFound(_) -> GameEnding
    SessionExpired -> GameEnding
    InvalidSessionToken -> GameEnding
    RateLimitExceeded -> GameEnding

    // Fatal - requires game restart
    GameFull -> Fatal
    GameNotStarted -> Fatal
    InvalidSequence(_, _) -> Fatal
  }
}

/// Define recovery action for each severity level
pub fn recovery_strategy(severity: ErrorSeverity) -> RecoveryAction {
  case severity {
    Recoverable -> ReturnError
    GameEnding -> RemovePlayer
    Fatal -> CrashGameRoom
  }
}

/// Get a user-friendly error message
pub fn error_message(error: GameError) -> String {
  case error {
    InvalidPlay(reason) -> "Cannot play these cards: " <> reason
    NotYourTurn -> "Wait for your turn"
    WrongPhase(expected, actual) ->
      "Cannot perform this action now. Expected: "
      <> expected
      <> ", Current: "
      <> actual
    PlayerNotFound(_) -> "Player not found in game"
    InvalidCardCount(expected, actual) ->
      "Invalid card count. Expected: "
      <> int.to_string(expected)
      <> ", Got: "
      <> int.to_string(actual)
    CardsNotInHand(_) -> "Invalid card selection"
    CannotPassNow -> "Cannot pass at this time"
    GameFull -> "Game is full"
    GameNotStarted -> "Game has not started yet"
    InvalidExchange(reason) -> "Invalid card exchange: " <> reason
    InvalidSequence(expected, actual) ->
      "Invalid message sequence. Expected: "
      <> int.to_string(expected)
      <> ", Got: "
      <> int.to_string(actual)
    DuplicateAction(key) -> "Duplicate action: " <> key
    SessionExpired -> "Session expired, reconnecting..."
    InvalidSessionToken -> "Invalid session token"
    RateLimitExceeded -> "Too many actions, please slow down"
  }
}
