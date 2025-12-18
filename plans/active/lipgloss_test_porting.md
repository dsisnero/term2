# Lipgloss Test Porting Plan

## Overview

Port all Go tests from `lipgloss/*_test.go` to Crystal specs in `spec/style*` and align implementations for full parity (borders, alignment, rendering, width/height, ANSI handling).
If anything differs from our port which is in the src/stlye.cr from the golang lipgloss implementation located in lipgloss/ directory, the correct logic is in the golang code. Have to match their logic but use crystal idioms, library, etc.  The lipgloss specs need to be under spec/lipgloss/.  To reach parity, our lipgloss code is under src/style.cr. If you need to create directories or more files for lipgloss code, put it under src/style/ directory.  Any questions about logic or structures needed can be found in libgloss/**/*.go code.  All code for bubbles/ is ported to src/components.

You must use the todo tool
You must run 'crystal spec spec/bubbles --fail-fast -v'
You must run 'crystal tool format'
You must run 'ameba --fix'
You must run 'ameba' and fix any errors on files we changed
After each plain 'ameba' run - rerun 'crystal spec' to make sure we fix the errors our ameba changes surfaced.

## Progress

- [x] Phase 1: Analysis & Inventory
- [x] Phase 2: Porting Strategy & Helpers
- [ ] Phase 3: Core Ports _(in progress)_
- [ ] Phase 4: Execution & Debugging
- [ ] Phase 5: Validation & Documentation

## Current Status

- Many style specs already ported; recent fixes include ANSI stripping, table/viewport width handling, underline/strikethrough parity, and ANSI-aware StyleRanges/alignment tweaks.
- Need systematic pass over all Go lipgloss tests to confirm coverage and fill gaps (borders, margins/padding, color, alignment, joins).

## Phase 1: Analysis & Inventory

- [x] List all `lipgloss/*_test.go`
- [x] Map existing Crystal specs (`spec/style_spec.cr`, related helpers) to Go tests
- [x] Identify shared fixtures/goldens to port (e.g., join/width cases)

## Phase 2: Porting Strategy & Helpers

- [x] Ensure spec structure under `spec/` mirrors Go coverage areas
- [x] Use golden fixtures where present; prefer direct comparisons without simplification
- [x] Keep ANSI-aware width helpers aligned with Go’s behavior

## Phase 3: Core Ports

- [ ] Borders & frames (padding/margin, rounded/normal, partial borders)
- [ ] Alignment and width/height calculations (place, join)
- [x] Rendering with ANSI sequences and strip logic
- [ ] Color/adaptive color behaviors
- [ ] Table-related helpers that depend on lipgloss joins

## Phase 4: Execution & Debugging

- [ ] Run targeted specs (`crystal spec spec/style_spec.cr` and related files)
- [ ] Compare with Go goldens; add missing test cases
- [ ] Fix Crystal implementation to match Go; avoid simplification
- [ ] Address ameba/style warnings in touched files

## Phase 5: Validation & Documentation

- [ ] Full `make spec-all` (or `crystal spec --fail-fast`) after ports
- [ ] Document any intentional deviations; note in `docs/migration-from-go.md`
- [ ] Ensure new tests live under `spec/` and mirror Go structure
- [ ] Consider CI wiring if missing

## Immediate Next Steps

1) Audit `lipgloss/*_test.go` vs `spec/style_spec.cr` for remaining gaps in borders, joins, alignment, and adaptive color behaviors.
2) Port missing goldens and assertions; add fixtures if Go uses them. Remaining large gap: `lipgloss/table/*` golden tests are not yet ported—decide where they belong (style vs components) and mirror outputs.
3) Fix any implementation gaps (frame size, border/margin edge cases, adaptive colors) uncovered by the new specs, including any table-related join/width helpers once tests are in place.
