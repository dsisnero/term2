# Style API Refactor Plan

**Status:** ✅ Completed - Archive on 2025-12-18  
**Note:** Style API refactor completed; legacy accessors replaced with ameba-compliant names.

## Overview

Refactor `src/style.cr` to replace legacy `get_*`/`is_set?` accessors and clear ameba issues while maintaining behavior and public API stability via staged changes.

## Progress

- [x] Phase 1: Inventory & Scope
- [x] Phase 2: Introduce preferred accessors + compatibility layer
- [x] Phase 3: Update call sites across repo
- [x] Phase 4: Remove legacy aliases (or suppress) and clear ameba
- [x] Phase 5: Validation & PR

## Current Status

- Style API refactor completed with all 100+ `get_*`/`is_set?` accessors replaced.
- Ameba issues cleared; public API maintained with compatibility layer.
- All specs pass with updated accessors.

## Phase 1: Inventory & Scope

- [x] Enumerate `get_*`/`is_set?` and other ameba findings in `src/style.cr`
- [x] Note public API impact and downstream call sites

## Phase 2: Preferred Accessors + Compatibility

- [x] Add preferred accessor names (ameba-compliant) alongside legacy names
- [x] Decide on temporary compatibility aliases or deprecations
- [x] Keep behavior identical; no functional changes

## Phase 3: Update Call Sites

- [x] Sweep repo to update all callers to preferred names
- [x] Run specs/ameba iteratively

## Phase 4: Remove Legacy/Ameba Noise

- [x] Remove or suppress legacy `get_*`/`is_set?` once callers updated
- [x] Address remaining block-param/complexity lint in `style.cr`

## Phase 5: Validation & PR

- [x] Full `crystal spec --fail-fast` / `make spec-all`
- [x] `ameba` clean
- [x] Submit as dedicated refactor PR

## Completion Summary

- Style API refactor successfully completed.
- All legacy accessors replaced with ameba-compliant names.
- Public API maintained with backward compatibility where needed.
