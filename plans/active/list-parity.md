# List Parity Plan

## Goal
Achieve full parity with Bubble Tea's list component, including filtering UX, styling, and helper APIs.

## Current Status
- Filtering implemented with simple substring matching and filter input UI.
- Status/footer hints and pagination mirrored.
- Delegate update hook, add/remove helpers, visible item tracking added.
- Styles struct pending; spinner/status styling parity in progress.

## Tasks
- [x] Implement fuzzy filter support (DefaultFilter/Rank) for match highlighting and ordering (uses subsequence matcher; true fuzzy/ranked parity still pending).
- [x] Add style struct knobs (title bar, spinner placement, filter prompt/cursor, status/footer, pagination dot/arabic auto-switch).
- [x] Support spinner integration in title/status bars (start/stop, toggle).
- [x] Add filter match metadata to delegates for highlighting.
- [x] Expand keymap to match Bubble Tea bindings (clear filter, accept/cancel while filtering, quit/force quit).
- [x] Auto-switch paginator dot/arabic based on available width.
- [x] Implement infinite scroll cursor wrap when enabled.
- [x] Surface delegate help bindings in short/full help views when delegate implements help key map.
- [x] Showcase spinner usage in list title/status (helper or example).
- [x] Upgrade filter to ranked fuzzy (sahilm/fuzzy parity) with ordering preserved (subsequence + ranked span/start).
- [ ] Mirror remaining `bubbles/list/list_test.go` cases if any.
- [ ] Update examples to exercise new list ergonomics and fuzzy ranks.

## Notes
- Filtering is currently substring-based for speed/simplicity; fuzzy matching parity is pending.
- Revisit after initial ergonomics merge to ensure FULL parity items are closed.
