# Revolution Card Game

A foundation project to explore **advanced multiplayer game features** with the **Gleam** programming language, using the **Revolution** card game (also known as "President" or "Trouduc" in French) as a practical testbed.

## About

This project leverages Gleam's BEAM VM foundations to experiment with concurrent, distributed, and real-time multiplayer game systems. The pure functional implementation of Revolution serves as a solid core for exploring advanced features like WebSocket communication, OTP supervision trees, distributed state management, and real-time synchronization patterns.

## Game Overview

Revolution is a strategic climbing card game where:

- **Goal:** Be the first to empty your hand and claim the "President" role
- **Hierarchy:** 3 (lowest) → 4 → 5 → 6 → 7 → 8 → 9 → 10 → J → Q → K → A → 2 (highest)
- **Revolution:** Playing 4-of-a-kind inverts the hierarchy (3 becomes highest!)
- **Special Cards:** 2s always clear the pile and beat any card (even during revolution)
- **Players:** 3-6 players supported

## Configurable Role Themes

The library supports **6 built-in role themes** plus custom labels to make the game family-friendly and internationally appealing:

### Built-in Themes

| Theme                   | Top → Bottom           | Best For                             |
| ----------------------- | ---------------------- | ------------------------------------ |
| **PowerTier** (default) | Tier 5 → Tier 1        | Universal, neutral, progression feel |
| **StarRating**          | ★★★★★ → ★              | Mobile games, achievement systems    |
| **Medieval**            | Monarch → Peasant      | Thematic, fantasy settings           |
| **Military**            | General → Private      | Strategic, competitive play          |
| **Descriptive**         | 1st Place → Last Place | Completely objective, no flavor      |
| **Classic**             | President → Trouduc    | Original French names (traditional)  |

## Core Modules

### `revolution/game/engine`

Game state management and transitions:

- `create_game` - Initialize a new game
- `add_player` - Add players to lobby
- `start_game` - Deal cards and begin first round
- `play_cards` - Execute a card play
- `pass_turn` - Pass when you can't/don't want to play
- `start_next_round` - Begin next round after scoring

### `revolution/game/rules`

Play validation logic:

- `validate_play` - Check if a play is legal
- `validate_exchange` - Validate card exchanges (Trouduc → President)
- `clears_pile` - Check if play clears the discard pile
- `triggers_revolution` - Check if play triggers revolution mode
- `can_pass` - Validate if player can pass

### `revolution/game/deck`

Card operations:

- `create_deck` - Generate standard 52-card deck
- `shuffle` - Deterministic Fisher-Yates shuffle
- `deal_cards` - Distribute cards evenly to players
- `sort_by_rank` - Sort cards by rank (respects revolution mode)

### `revolution/game/scoring`

Role assignment and scoring:

- `assign_roles` - Map finishing positions to roles
- `calculate_scores` - Compute round scores
- `has_vice_roles` - Check if game size supports vice roles (4+ players)

### `revolution/game/types`

Type definitions for all game entities (cards, players, game state, etc.)

### `revolution/error/types`

Error handling with severity classification:

- `Recoverable` - Player can retry (invalid play, not your turn)
- `GameEnding` - Player removed (session expired, not found)
- `Fatal` - Game restart required (invalid sequence)

## Game Rules

### Card Hierarchy

**Normal Mode:** 3 < 4 < 5 < 6 < 7 < 8 < 9 < 10 < J < Q < K < A < **2**
**Revolution Mode:** 3 > 4 > 5 > 6 > 7 > 8 > 9 > 10 > J > Q > K > A > **2**

### Special Rules

- **2s are wild:** Always clear pile, beat any card, retain power during revolution
- **Four of a kind:** Triggers revolution (hierarchy inverts), clears pile
- **Passing:** Can't pass when starting a new trick
- **Pile clearing:** Clears when all players pass or 2s/4-of-a-kind played

### Roles & Card Exchange (4+ players)

After first round, players are assigned roles based on finishing order:

1. **Top Role** (1st) ← Receives 2 best cards from Bottom Role
2. **Second Role** (2nd) ← Receives 1 best card from Fourth Role
3. **Middle Role** (middle positions) ← No exchange
4. **Fourth Role** (2nd-last) → Gives 1 best card to Second Role
5. **Bottom Role** (last) → Gives 2 best cards to Top Role

**Note:** Role names are configurable! Choose from built-in themes like Power Tier, Star Rating, Medieval, Military, Descriptive, or Classic (original names).

## Architecture

This implementation follows **pure functional core, imperative shell** architecture:

```
revolution/
├── game/           # Pure game logic (no I/O)
│   ├── engine.gleam      # State transitions
│   ├── rules.gleam       # Validation rules
│   ├── deck.gleam        # Card operations
│   ├── scoring.gleam     # Role assignment
│   └── types.gleam       # Type definitions
├── error/          # Error handling
│   └── types.gleam       # GameError with severity
└── utils/          # Utilities
    └── id.gleam          # Opaque ID types
```

**Design Principles:**

- All functions are pure (deterministic, no side effects)
- State is immutable (new state returned from functions)
- Exhaustive pattern matching (no runtime crashes)
- Type-safe IDs (can't mix player/game/session IDs)
- Result types for error handling (no exceptions)

## Development

```sh
# Run tests
gleam test

# Build documentation
gleam docs build

# Format code
gleam format

# Type check
gleam check
```

## Testing

The project has **65 comprehensive tests** covering:

- Game lifecycle (create → add players → start → play → round end)
- Play validation (rank comparison, card counting, revolution mode)
- Revolution mechanics (hierarchy inversion, 2s special behavior)
- Role assignment (3-6 players, all role combinations)
- Card exchange validation (strict best-cards enforcement)
- Edge cases (card conservation, auto-finish last player)

Run tests with:

```sh
gleam test
```

## Project Status

**Phase 1: Core Game Logic** - Complete

- [x] Card deck operations
- [x] Play validation
- [x] Revolution mode
- [x] Role assignment
- [x] Round transitions
- [x] Comprehensive tests

**Phase 2: Advanced Features** - Planned

- [ ] Card exchange implementation
- [ ] Game-over detection
- [ ] Disconnection handling
- [ ] Replay/undo functionality

**Phase 3: Multiplayer** - Future

- [ ] WebSocket server
- [ ] Room management
- [ ] Matchmaking
- [ ] Spectator mode
