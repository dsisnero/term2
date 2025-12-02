# API Improvement Completion Report

## Overview

This phase focused on refactoring the Term2 API to closely model Bubble Tea (Go), improving ergonomics and type safety.

## Completed Features

### 1. Message Type System (Phase 1)

- **Msg Alias**: Created `alias Msg = Message` for future flexibility.
- **Abstract Message**: Kept `abstract class Message` as the base.
- **Type Safety**: Encouraged subclassing `Message` for all events.

### 2. Update Function Signature (Phase 2)

- **Return Type**: Changed `update(msg : Msg)` to return `{Model, Cmd}`.
- **Setters**: Added `input=` and `output=` setters to `Program` for better configuration.

### 3. Command System (Phase 3)

- **Cmd Type**: Redefined `Cmd` as `alias Cmd = Proc(Msg?)?` (nullable proc returning optional message).
- **Cmds Module**: Renamed `Term2::Cmd` module to `Term2::Cmds` to avoid collision with the alias.
- **Constructors**: Added `Cmds.none`, `Cmds.message`, `Cmds.batch`, `Cmds.sequence`, `Cmds.tick`, `Cmds.timeout`.
- **Batch & Sequence**: Implemented `BatchMsg` and `SequenceMsg` to handle multiple commands efficiently without blocking.
- **Async Execution**: Updated `Program` to spawn commands asynchronously, preventing UI freezes.

## Technical Details

### Command Execution

Commands are now Procs that return a `Msg?`. The `Program` loop executes them:

- Single commands are spawned in a fiber.
- `BatchMsg` spawns multiple fibers (parallel).
- `SequenceMsg` spawns a fiber that runs commands sequentially.

### Migration Notes

- `Term2::Cmd` is now a type alias. Use `Term2::Cmds` for helper methods.
- `update` must return `{model, cmd}` tuple.
- Components have been updated to use the new API.

## Verification

- All specs in `spec/` pass.
- `spec/term2_spec.cr` was rewritten to test the new `Cmds` behavior and fix hanging tests.
