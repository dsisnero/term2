# Term2 Master Plan

## Current Status

**Overall Progress:** ~96%
**Active Workstream:** None
**Recent Completion:** BubbleTea Examples Port

## Active Workstreams

### None

## Completed Workstreams

### [F] BubbleTea Examples Port

**Status:** ✅ Completed (Dec 2025)
**Goal:** Port Bubble Tea's example suite to Term2 under `examples/bubbletea/`.
**Achievements:**

- Ported 48 Bubble Tea examples with feature parity for keys, mouse, and rendering
- Added specs in `spec/examples/` to cover each example, including tabs navigation
- Verified examples build via `make build-examples`
- Plan File: `plans/active/bubbletea-examples.yml`

### [E] BubbleZone Integration

**Status:** ✅ Completed (Jan 2025)
**Goal:** Integrate zone-based focus management as core part of Term2.
**Achievements:**

- Created `Zone` module with mark/scan/focus/handle_mouse
- Updated all focusable components to use Zone-based focus:
  - TextInput: Zone.mark() in view, handles ZoneClickMsg
  - List: Zone-based focus, click-to-select items
  - Table: Zone-based focus with focused?() method
  - TextArea: Zone integration with cursor management
  - FilePicker: Zone-based focus for file navigation
- Automatic Tab/Shift+Tab focus cycling between zones
- Mouse click auto-focuses clicked zone
- Messages: ZoneClickMsg, ZoneFocusMsg, ZoneBlurMsg

### [D] Ergonomics & Namespace Cleanup

**Status:** ✅ Completed (Nov 26, 2025)
**Goal:** Remove "Bubbles" namespace and improve library ergonomics.
**Achievements:**

- Flattened namespace (Term2::Bubbles -> Term2::Components)
- Simplified Application setup (Term2.run)
- Added command helpers (Term2.quit, Term2.batch)
- Standardized styling API
**Plan File:** `plans/completed/ergonomics-improvements.yml`

### [B] Bubbles Components Port

**Status:** ✅ Completed (Nov 25, 2025)
**Goal:** Port standard UI components from Charmbracelet's Bubbles library.
**Achievements:**

- Ported Core Utilities (Key, Cursor, RuneUtil, Viewport)
- Ported Simple Indicators (Spinner, Progress, Timer, Stopwatch)
- Ported Input Components (TextInput, TextArea)
- Ported Complex Data Display (Paginator, List, Table, Help, FilePicker)
**Plan File:** `plans/completed/bubbles-components.yml`

### [C] Crystal Idioms & API Ergonomics

**Status:** ✅ Completed (Nov 25, 2025)
**Achievements:**

- Implemented View DSL (`v_stack`, `h_stack`, `border`, etc.)
- Introduced `Application(M)` for type-safe models
- Established Component Composition pattern (Bubble Tea style)
- Standardized `KeyMsg` handling
**Completion Report:** `plans/completed/CRYSTAL_IDIOMS_COMPLETION.md`

### [A] Bubble Tea Feature Parity

**Status:** ✅ Completed (Nov 25, 2025)
**Achievements:**

- Core Architecture (Model-Update-View)
- Terminal Control & Input Handling
- Basic Styling/Layout
**Plan File:** `plans/completed/bubbletea-feature-parity.md` (Note: Referenced in plans/README.md)

## Backlog

- [ ] Advanced Text Layout (Word wrapping, etc.)
- [ ] Lipgloss Port (Advanced Styling)
- [ ] Windows Support Optimization
