# Bubbles Test Porting Plan

## Overview

Port all Go tests from `bubbles/*_test.go` to Crystal specs in `spec/bubbles/` and ensure implementation parity (table, viewport, spinner, input, etc.).

## Progress

- [x] Phase 1: Analysis & Inventory
- [x] Phase 2: Porting Strategy & Helpers
- [ ] Phase 3: Core Ports _(in progress)_
- [ ] Phase 4: Execution & Debugging
- [ ] Phase 5: Validation & Documentation

## Current Status

- Table parity: aligned `spec/bubbles/table_spec.cr` with Go golden fixtures (width/height, borders, padding, selection frames).
- Viewport alignment: width=0 behavior now matches Go (no forced padding/truncation).
- Next focus: remaining components (spinner, text inputs, progress, viewport edge cases) and mouse/key parity.

## Phase 1: Analysis & Inventory

- [x] List all `bubbles/*_test.go`
- [x] Categorize by component (table, viewport, spinner, input, etc.)
- [x] Identify shared helpers/fixtures to port

## Phase 2: Porting Strategy & Helpers

- [x] Establish spec structure under `spec/bubbles/`
- [x] Map Go helpers/fixtures to Crystal equivalents
- [x] Decide concurrency translations (channels → CML) where needed

## Phase 3: Core Ports (Component-Level)

- [ ] Table: complete golden/data-driven specs, selection, borders, padding
- [ ] Viewport: scrolling, width/height, frame sizing, mouse wheel
- [ ] Spinner/Progress: tick timing, frame advancement, stop behavior
- [ ] Text inputs/areas: key handling, cursor movement, validation
- [ ] Lists/Paginators: navigation, selection, page math
- [ ] Help/Key bindings: bindings rendering parity

## Phase 4: Execution & Debugging

- [ ] Run targeted specs per component (`crystal spec spec/bubbles/<component>_spec.cr`)
- [ ] Compare outputs to Go goldens/expectations
- [ ] Fix Crystal implementations to match Go behavior; avoid simplifications
- [ ] Re-run `crystal spec --fail-fast` after each fix
- [ ] Address ameba/style warnings locally to touched files

## Phase 5: Validation & Documentation

- [ ] Full `make spec-all` (or `crystal spec --fail-fast`) after all ports
- [ ] Document any intentional deviations; add notes to `docs/migration-from-go.md`
- [ ] Ensure new tests live under `spec/bubbles/` only
- [ ] Consider CI wiring for new specs if missing

## Immediate Next Steps

1) Audit remaining Go tests per component and note missing specs in `spec/bubbles/`.
2) Continue porting (start with spinner/progress and viewport edge cases).
3) Fix implementation gaps uncovered by newly ported specs.
