# Term2 Master Plan

## Current Status

**Overall Progress:** ~92%
**Active Workstream:** None
**Recent Completion:** cml upgrade compatibility + parity specs

## Active Workstreams

### None

## Completed Workstreams

### [F] cml Upgrade Compatibility + Parity Specs

**Status:** ✅ Completed (Dec 2025)
**Goal:** Restore full Bubble Tea/Bubbles/Lipgloss parity after updating the `cml` shard.
**Achievements:**

*   Fixed Bubble Tea program loop behaviors (mailbox events, panic recovery, filter proc dispatch)
*   Restored key/focus/mouse parsing parity and prevented focus/blur hangs
*   Improved Bubbles components parity (List filter help, Help width/ellipsis, TextInput placeholders/suggestions, TextArea wrapping/navigation)
*   Corrected Lipgloss parity behaviors (color profiles, sizing/width math, table resizing, underline/strikethrough whitespace behavior, range/rune styling)
*   Marked fuzzy matching specs as pending until fuzzy shard lands
*   Updated example ports/specs to compile against the new APIs (compat helpers for colors/styles, viewport, progress, table/list delegates)
*   Confirmed spec layout matches upstream packages (`spec/bubbletea`, `spec/bubblezone`, `spec/lipgloss`)
*   Verified all examples compile via `make build-examples` and updated remaining stale example code paths
* Restored Bubblezone mouse/zone click behavior and added `spec/examples/bubblezone/*` coverage for bubblezone examples
*   Re-aligned Bubblezone `list-default` example to upstream (altscreen + cell-motion mouse, wheel scroll moves cursor, click selects via zone bounds)
*   Added Bubble Tea parity helpers to `Term2::Components::List` (`cursor_up`, `cursor_down`, `select`) for mouse-driven examples
*   Added `targets` to `shard.yml` so `shards build`/`make build` succeeds for CI build checks
*   Fixed Bubblezone+Lipgloss example rendering by making ANSI/OSC/zone marker stripping/truncation width-aware (`src/style.cr`) and porting `full-lipgloss` example layout/behavior to match upstream Go
*   Matched Bubblezone `NewPrefix()` semantics (`zone_<n>__`) and ensured `full-lipgloss` assigns one unique prefix per component type to prevent zone ID collisions (restores reliable mouse hit-testing)
*   Fixed blank first-frame renders by sending initial `WindowSizeMsg` on program startup when output is a TTY
*   Improved interactive performance by rendering via a line-diff renderer (avoids full-screen clears/writes on every input event, closer to Bubble Tea renderer behavior)
*   Began extracting ANSI-aware word wrapping into a reusable library (`lib/cellwrap`) based on charmbracelet/x/cellbuf.Wrap, and switched `Style` to use it
*   Ported `charm_x/cellbuf/wrap_test.go` into `lib/cellwrap/spec/wrap_parity_spec.cr` and matched `Cellwrap.wrap` behavior (ANSI SGR + OSC-8 links + grapheme/combining mark width); main suite runs it via `spec/cellwrap_parity_spec.cr`

### [E] BubbleZone Integration

**Status:** ✅ Completed (Jan 2025)
**Goal:** Integrate zone-based focus management as core part of Term2.
**Achievements:**

*   Created `Zone` module with mark/scan/focus/handle_mouse
*   Updated all focusable components to use Zone-based focus:
    *   TextInput: Zone.mark() in view, handles ZoneClickMsg
    *   List: Zone-based focus, click-to-select items
    *   Table: Zone-based focus with focused?() method
    *   TextArea: Zone integration with cursor management
    *   FilePicker: Zone-based focus for file navigation
*   Automatic Tab/Shift+Tab focus cycling between zones
*   Mouse click auto-focuses clicked zone
*   Messages: ZoneClickMsg, ZoneFocusMsg, ZoneBlurMsg

### [D] Ergonomics & Namespace Cleanup

**Status:** ✅ Completed (Nov 26, 2025)
**Goal:** Remove "Bubbles" namespace and improve library ergonomics.
**Achievements:**

*   Flattened namespace (Term2::Bubbles -> Term2::Components)
*   Simplified Application setup (Term2.run)
*   Added command helpers (Term2.quit, Term2.batch)
*   Standardized styling API
**Plan File:** `plans/completed/ergonomics-improvements.yml`

### [B] Bubbles Components Port

**Status:** ✅ Completed (Nov 25, 2025)
**Goal:** Port standard UI components from Charmbracelet's Bubbles library.
**Achievements:**

*   Ported Core Utilities (Key, Cursor, RuneUtil, Viewport)
*   Ported Simple Indicators (Spinner, Progress, Timer, Stopwatch)
*   Ported Input Components (TextInput, TextArea)
*   Ported Complex Data Display (Paginator, List, Table, Help, FilePicker)
**Plan File:** `plans/completed/bubbles-components.yml`

### [C] Crystal Idioms & API Ergonomics

**Status:** ✅ Completed (Nov 25, 2025)
**Achievements:**

*   Implemented View DSL (`v_stack`, `h_stack`, `border`, etc.)
*   Introduced `Application(M)` for type-safe models
*   Established Component Composition pattern (Bubble Tea style)
*   Standardized `KeyMsg` handling
**Completion Report:** `plans/completed/CRYSTAL_IDIOMS_COMPLETION.md`

### [A] Bubble Tea Feature Parity

**Status:** ✅ Completed (Nov 25, 2025)
**Achievements:**

*   Core Architecture (Model-Update-View)
*   Terminal Control & Input Handling
*   Basic Styling/Layout
**Plan File:** `plans/completed/bubbletea-feature-parity.md` (Note: Referenced in plans/README.md)

## Backlog

*   [ ] Advanced Text Layout (Word wrapping, etc.)
*   [ ] Lipgloss Port (Advanced Styling)
*   [ ] Windows Support Optimization
