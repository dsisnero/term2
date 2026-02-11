# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-02-11

- Ported `github.com/charmbracelet/x/exp/charmtone` to Crystal.
- Added full `Charmtone::Key` palette enum, including additions/deletions/provisional keys.
- Added `hex`, `rgba`, `to_s`, and palette classification helpers.
- Added canonical key list via `Charmtone.keys` (matching Go behavior).
- Added shard specs covering names, hex values, RGBA scaling, key set semantics, and palette groups.
