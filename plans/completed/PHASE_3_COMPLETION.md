# Phase 3 Completion Report: Renderer System & Advanced Features

## Overview

Phase 3 focused on implementing a flexible renderer system, advanced input
handling (bracketed paste), and message filtering. This phase establishes the
foundation for robust terminal output and application lifecycle management.

## Completed Features

### 1. Renderer System

- **Abstract Renderer Interface**: Defined `Term2::Renderer` abstract class.
- **Standard Renderer**: Implemented `Term2::StandardRenderer` with:
  - ANSI escape sequence handling
  - Frame rate control (FPS)
  - Screen clearing and repainting
  - Rate limiting
- **Nil Renderer**: Implemented `Term2::NilRenderer` for headless/non-TUI modes.
- **Program Integration**: Updated `Term2::Program` to use the renderer system.

### 2. Advanced Input Handling

- **Bracketed Paste**:
  - Implemented detection of bracketed paste sequences (`\e[200~` ...
    `\e[201~`).
  - Added `paste` flag to `Term2::Key`.
  - Added `WithoutBracketedPaste` option to disable it.
- **Message Filtering**:
  - Implemented `WithFilter` option to intercept and transform messages.
  - Integrated filtering into the main event loop.

### 3. Print Functionality

- **Println/Printf**: Implemented `Term2.println` and `Term2.printf`.
- **PrintMsg**: Added `Term2::PrintMsg` to handle print requests via the message
  loop.
- **Renderer Support**: Added `print` method to `Renderer` interface to handle
  printing while TUI is running (clearing screen, printing, repainting).

### 4. Window Management

- **Size Detection**: Implemented terminal size detection using `ioctl`.
- **Resize Handling**: Handled `SIGWINCH` signals and dispatched
  `WindowSizeMsg`.

## Technical Details

### Renderer Architecture

The renderer runs in the main loop (synchronously with event processing) to
ensure thread safety with `STDOUT`. It consumes from a `render_mailbox` which
now supports `RenderOp` (either a frame `String` or a `PrintMsg`).

### Input Processing

The `KeyReader` was enhanced to statefully parse bracketed paste sequences,
buffering content until the end sequence is received, and then emitting a single
`Key` event with the `paste` flag set.

## Testing

- Added `spec/renderer_spec.cr` covering renderer lifecycle, FPS control, and
  output.
- Updated `spec/term2_spec.cr` to test bracketed paste, message filtering, and
  print functionality.
- Verified `SpecCounterApp` with high FPS settings to ensure proper rendering
  behavior in tests.

## Next Steps

Proceed to Phase 4: Enhanced Key Support & Polish.

- Expand key sequence coverage.
- Improve key reader robustness.
- Comprehensive testing and documentation.
