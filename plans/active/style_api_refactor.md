# Style API Refactor Plan

## Overview

Refactor `src/style.cr` to replace legacy `get_*`/`is_set?` accessors and clear ameba issues while maintaining behavior and public API stability via staged changes.

## Progress

- [x] Phase 1: Inventory & Scope
- [ ] Phase 2: Introduce preferred accessors + compatibility layer
- [ ] Phase 3: Update call sites across repo
- [ ] Phase 4: Remove legacy aliases (or suppress) and clear ameba
- [ ] Phase 5: Validation & PR

## Current Status

- Inventory shows 100+ `get_*`/`is_set?` accessors and related lint findings in `src/style.cr`. Bulk rename needs careful staging.

## Phase 1: Inventory & Scope

- [x] Enumerate `get_*`/`is_set?` and other ameba findings in `src/style.cr`
- [x] Note public API impact and downstream call sites

## Phase 2: Preferred Accessors + Compatibility

- [ ] Add preferred accessor names (ameba-compliant) alongside legacy names
- [ ] Decide on temporary compatibility aliases or deprecations
- [ ] Keep behavior identical; no functional changes

## Phase 3: Update Call Sites

- [ ] Sweep repo to update all callers to preferred names
- [ ] Run specs/ameba iteratively

## Phase 4: Remove Legacy/Ameba Noise

- [ ] Remove or suppress legacy `get_*`/`is_set?` once callers updated
- [ ] Address remaining block-param/complexity lint in `style.cr`

## Phase 5: Validation & PR

- [ ] Full `crystal spec --fail-fast` / `make spec-all`
- [ ] `ameba` clean
- [ ] Submit as dedicated refactor PR

## Immediate Next Steps

1) Draft accessor mapping (legacy -> preferred) and compatibility approach.
2) Implement new accessors in `src/style.cr` (no caller updates yet).
3) Plan repo-wide caller sweep.
