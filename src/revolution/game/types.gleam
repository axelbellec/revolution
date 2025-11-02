/// Core game types for Revolution card game

import gleam/dict.{type Dict}
import gleam/option.{type Option}
import gleam/order.{type Order}
import revolution/utils/id.{type GameId, type PlayerId}

/// Card rank in ascending power order (normal mode)
/// During revolution, order inverts
pub type Rank {
  Three
  Four
  Five
  Six
  Seven
  Eight
  Nine
  Ten
  Jack
  Queen
  King
  Ace
  Two
}

/// Card suit (irrelevant for gameplay but needed for card identity)
pub type Suit {
  Hearts
  Diamonds
  Clubs
  Spades
}

/// Playing card
pub type Card {
  Card(rank: Rank, suit: Suit)
}

/// Player role determines card exchange requirements and hierarchy
/// Roles are position-based (1st place → 5th place) for semantic clarity
pub type Role {
  TopRole
  SecondRole
  MiddleRole
  FourthRole
  BottomRole
}

/// Role display theme for customizing role names
pub type RoleTheme {
  PowerTier
  StarRating
  Medieval
  Military
  Descriptive
  Classic
}

/// Custom role labels for fully customizable role names
pub type RoleLabels {
  RoleLabels(
    top: String,
    second: String,
    middle: String,
    fourth: String,
    bottom: String,
  )
}

/// Player connection state with timeout tracking
pub type ConnectionState {
  Connected(last_seen: Int)
  Disconnected(since: Int, grace_period_ms: Int)
  Removed
}

/// Player state within a game
pub type Player {
  Player(
    id: PlayerId,
    name: String,
    hand: List(Card),
    role: Option(Role),
    finished_position: Option(Int),
    connection_state: ConnectionState,
    has_passed: Bool,
  )
}

/// Card exchange requirement between roles
pub type Exchange {
  Exchange(
    from_role: Role,
    to_role: Role,
    count: Int,
    quality: ExchangeQuality,
  )
}

/// Quality of cards to exchange
pub type ExchangeQuality {
  /// Must give highest cards (subjective, but typically highest rank)
  Best
  /// Can give any cards
  Any
}

/// Pending card exchange during CardExchange phase
pub type PendingExchange {
  PendingExchange(
    from_player: PlayerId,
    to_player: PlayerId,
    count: Int,
    quality: ExchangeQuality,
    completed: Bool,
  )
}

/// Current phase of the game
pub type GamePhase {
  WaitingForPlayers
  CardExchange(pending: List(PendingExchange))
  Playing
  RoundOver(finishing_order: List(PlayerId))
  GameOver(final_scores: List(#(PlayerId, Int)))
}

/// Game configuration
pub type GameConfig {
  GameConfig(
    min_players: Int,
    max_players: Int,
    include_jokers: Bool,
    revolution_enabled: Bool,
    twos_clear_pile: Bool,
    rounds_to_play: Option(Int),
    exchange_timeout_ms: Int,
    disconnect_grace_period_ms: Int,
    turn_timeout_ms: Option(Int),
    role_theme: RoleTheme,
    custom_role_labels: Option(RoleLabels),
  )
}

/// A single play in the game
pub type Play {
  Play(
    player_id: PlayerId,
    cards: List(Card),
    cleared_pile: Bool,
    timestamp: Int,
  )
}

/// Complete game state
pub type GameState {
  GameState(
    id: GameId,
    config: GameConfig,
    players: List(Player),
    phase: GamePhase,
    current_player_index: Int,
    discard_pile: List(Card),
    play_history: List(Play),
    last_play: Option(Play),
    revolution_active: Bool,
    round_number: Int,
    scores: Dict(PlayerId, Int),
    created_at: Int,
    host_player_id: PlayerId,
    sequence_counter: Int,
  )
}

// Helper functions for Rank

/// Get the rank value for comparison (normal mode)
pub fn rank_value(rank: Rank) -> Int {
  case rank {
    Three -> 3
    Four -> 4
    Five -> 5
    Six -> 6
    Seven -> 7
    Eight -> 8
    Nine -> 9
    Ten -> 10
    Jack -> 11
    Queen -> 12
    King -> 13
    Ace -> 14
    Two -> 15
  }
}

/// Get the rank value during revolution (inverted)
pub fn rank_value_revolution(rank: Rank) -> Int {
  case rank {
    Three -> 15
    Four -> 14
    Five -> 13
    Six -> 12
    Seven -> 11
    Eight -> 10
    Nine -> 9
    Ten -> 8
    Jack -> 7
    Queen -> 6
    King -> 5
    Ace -> 4
    Two -> 3
  }
}

/// Compare two ranks
pub fn compare_rank(a: Rank, b: Rank, revolution_active: Bool) -> Order {
  let a_val = case revolution_active {
    True -> rank_value_revolution(a)
    False -> rank_value(a)
  }
  let b_val = case revolution_active {
    True -> rank_value_revolution(b)
    False -> rank_value(b)
  }

  case a_val == b_val, a_val < b_val {
    True, _ -> order.Eq
    _, True -> order.Lt
    _, False -> order.Gt
  }
}

/// Check if a rank is a Two (special clearing card)
pub fn is_two(rank: Rank) -> Bool {
  case rank {
    Two -> True
    _ -> False
  }
}

/// Convert rank to string for display
pub fn rank_to_string(rank: Rank) -> String {
  case rank {
    Three -> "3"
    Four -> "4"
    Five -> "5"
    Six -> "6"
    Seven -> "7"
    Eight -> "8"
    Nine -> "9"
    Ten -> "10"
    Jack -> "J"
    Queen -> "Q"
    King -> "K"
    Ace -> "A"
    Two -> "2"
  }
}

/// Convert suit to string for display
pub fn suit_to_string(suit: Suit) -> String {
  case suit {
    Hearts -> "♥"
    Diamonds -> "♦"
    Clubs -> "♣"
    Spades -> "♠"
  }
}

/// Convert card to string for display
pub fn card_to_string(card: Card) -> String {
  rank_to_string(card.rank) <> suit_to_string(card.suit)
}

/// Default game configuration
pub fn default_config() -> GameConfig {
  GameConfig(
    min_players: 3,
    max_players: 6,
    include_jokers: False,
    revolution_enabled: True,
    twos_clear_pile: True,
    rounds_to_play: option.None,
    exchange_timeout_ms: 60_000,
    disconnect_grace_period_ms: 30_000,
    turn_timeout_ms: option.None,
    role_theme: PowerTier,
    custom_role_labels: option.None,
  )
}

/// Convert role to display string based on theme
pub fn role_to_string(role: Role, theme: RoleTheme) -> String {
  case theme {
    PowerTier -> role_to_power_tier(role)
    StarRating -> role_to_star_rating(role)
    Medieval -> role_to_medieval(role)
    Military -> role_to_military(role)
    Descriptive -> role_to_descriptive(role)
    Classic -> role_to_classic(role)
  }
}

/// Convert role to string with custom labels (overrides theme)
pub fn role_to_string_custom(role: Role, labels: RoleLabels) -> String {
  case role {
    TopRole -> labels.top
    SecondRole -> labels.second
    MiddleRole -> labels.middle
    FourthRole -> labels.fourth
    BottomRole -> labels.bottom
  }
}

/// Power Tier theme: Tier 5 → Tier 1
fn role_to_power_tier(role: Role) -> String {
  case role {
    TopRole -> "Tier 5"
    SecondRole -> "Tier 4"
    MiddleRole -> "Tier 3"
    FourthRole -> "Tier 2"
    BottomRole -> "Tier 1"
  }
}

/// Star Rating theme: 5-Star → 1-Star
fn role_to_star_rating(role: Role) -> String {
  case role {
    TopRole -> "★★★★★"
    SecondRole -> "★★★★"
    MiddleRole -> "★★★"
    FourthRole -> "★★"
    BottomRole -> "★"
  }
}

/// Medieval theme: Monarch → Peasant
fn role_to_medieval(role: Role) -> String {
  case role {
    TopRole -> "Monarch"
    SecondRole -> "Duke"
    MiddleRole -> "Knight"
    FourthRole -> "Squire"
    BottomRole -> "Peasant"
  }
}

/// Military theme: General → Private
fn role_to_military(role: Role) -> String {
  case role {
    TopRole -> "General"
    SecondRole -> "Colonel"
    MiddleRole -> "Captain"
    FourthRole -> "Sergeant"
    BottomRole -> "Private"
  }
}

/// Descriptive theme: 1st Place → Last Place
fn role_to_descriptive(role: Role) -> String {
  case role {
    TopRole -> "1st Place"
    SecondRole -> "2nd Place"
    MiddleRole -> "Middle"
    FourthRole -> "Second-Last"
    BottomRole -> "Last Place"
  }
}

/// Classic theme: President → Trouduc (original names)
fn role_to_classic(role: Role) -> String {
  case role {
    TopRole -> "President"
    SecondRole -> "Vice-President"
    MiddleRole -> "Neutral"
    FourthRole -> "Vice-Trouduc"
    BottomRole -> "Trouduc"
  }
}
