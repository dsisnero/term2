# BubbleTea Feature Parity Implementation Plan

## Overview
This plan outlines the phased implementation of missing BubbleTea functionality in the Crystal port, organized by priority and complexity.

## Phase 1: Core Infrastructure & Terminal Control (Week 1-2)

### Week 1: Advanced Terminal Features
**Goal**: Implement alternate screen, cursor control, and basic terminal state management

#### Tasks:
1. **Alternate Screen Support**
   - [x] Add `enterAltScreen()` and `exitAltScreen()` commands
   - [x] Implement `WithAltScreen()` program option
   - [x] Create internal messages: `EnterAltScreenMsg`, `ExitAltScreenMsg`

2. **Cursor Control**
   - [x] Add `showCursor()` and `hideCursor()` commands
   - [x] Create internal messages: `ShowCursorMsg`, `HideCursorMsg`
   - [x] Integrate with renderer system

3. **Terminal State Management**
   - [x] Add terminal state save/restore functionality
   - [x] Implement `ReleaseTerminal()` and `RestoreTerminal()` methods
   - [x] Add signal handling for proper cleanup

#### Files to Modify/Create:
- [x] `src/term2.cr` - Add new message types and commands
- [x] `src/terminal.cr` - New file for terminal control utilities
- [x] `spec/terminal_spec.cr` - Tests for terminal features

### Week 2: Program Options & Configuration
**Goal**: Implement flexible program configuration system

#### Tasks:
1. **Program Options Framework**
   - [x] Create `ProgramOption` type and apply system
   - [x] Implement option bitmask system like Go version
   - [x] Add startup options tracking

2. **Core Options Implementation**
   - [x] `WithAltScreen()` - Alternate screen on startup
   - [x] `WithoutRenderer()` - Non-TUI mode
   - [x] `WithoutCatchPanics()` - Panic handling control
   - [x] `WithoutSignalHandler()` - Custom signal handling

3. **Input/Output Configuration**
   - [x] `WithInput()` - Custom input source
   - [x] `WithOutput()` - Custom output destination
   - [x] `WithInputTTY()` - Force TTY input
   - [x] `WithEnvironment()` - Environment variable control

#### Files to Modify/Create:
- [x] `src/program_options.cr` - New file for options system
- [x] `src/term2.cr` - Integrate options into Program
- [x] `spec/program_options_spec.cr` - Tests for options

## Phase 2: Mouse Support & Advanced Input (Week 3-4)

### Week 3: Mouse Event System
**Goal**: Complete mouse event detection and handling

#### Tasks:
1. **Mouse Event Types**
   - [x] Implement `MouseMsg`, `MouseEvent`, `MouseAction`, `MouseButton` types
   - [x] Add comprehensive mouse button definitions (left, right, middle, wheel, etc.)
   - [x] Support for mouse motion events

2. **Mouse Protocol Parsers**
   - [x] X10 mouse protocol parser (`parseX10MouseEvent`)
   - [x] SGR mouse protocol parser (`parseSGRMouseEvent`)
   - [x] Mouse button encoding/decoding

3. **Mouse Detection in Input Reader**
   - [x] Integrate mouse event detection in `detectOneMsg` equivalent
   - [x] Add mouse sequence recognition
   - [x] Handle mouse motion vs click events

#### Files to Modify/Create:
- [x] `src/mouse.cr` - New file for mouse handling
- [x] `src/key_reader.cr` - Extend to detect mouse sequences
- [x] `spec/mouse_spec.cr` - Comprehensive mouse tests

### Week 4: Mouse Configuration & Advanced Input
**Goal**: Mouse mode configuration and input improvements

#### Tasks:
1. **Mouse Mode Options**
   - [x] `WithMouseCellMotion()` - Cell-based mouse tracking
   - [x] `WithMouseAllMotion()` - All motion tracking (hover)
   - [x] Mouse enable/disable commands

2. **Input System Improvements**
   - [x] Better buffer management for partial reads
   - [x] UTF-8 error handling
   - [x] Cancel reader implementation
   - [x] TTY input fallback handling

3. **Focus Reporting**
   - [x] `WithReportFocus()` option
   - [x] `FocusMsg` and `BlurMsg` types
   - [x] Focus event detection and handling

#### Files to Modify/Create:
- [x] `src/input_reader.cr` - Enhanced input handling (integrated into term2.cr)
- [x] `src/program_options.cr` - Add mouse options
- [x] `spec/input_spec.cr` - Input system tests (integrated into focus_spec.cr)

## Phase 3: Renderer System & Advanced Features (Week 5-6)

### Week 5: Renderer Implementation
**Goal**: Build flexible renderer system with performance optimizations

#### Tasks:
1. **Renderer Interface & Implementation**
   - [x] Create `Renderer` abstract base class
   - [x] Implement `StandardRenderer` with ANSI compression
   - [x] Implement `NilRenderer` for non-TUI mode

2. **Renderer Features**
   - [x] Frame rate control with `WithFPS()` option
   - [x] ANSI sequence compression (basic deduplication; TODO: line-by-line diff for optimization)
   - [x] Screen clearing and management
   - [x] Renderer start/stop lifecycle

3. **Message Handling in Renderer**
   - [x] Process internal renderer messages
   - [x] Handle screen mode changes
   - [x] Manage cursor visibility

#### Files to Modify/Create:
- [x] `src/renderer.cr` - Renderer interface and implementations
- [x] `src/standard_renderer.cr` - Main renderer implementation (combined in renderer.cr)
- [x] `src/nil_renderer.cr` - No-op renderer (combined in renderer.cr)
- [x] `spec/renderer_spec.cr` - Renderer tests

### Week 6: Advanced Features & Message System
**Goal**: Implement remaining advanced features and message types

#### Tasks:
1. **Bracketed Paste Support**
   - [x] `WithoutBracketedPaste()` option
   - [x] Paste detection in input reader
   - [x] Paste flag in Key messages

2. **Window & Size Management**
   - [x] Terminal size detection
   - [x] Resize event handling
   - [x] `WindowSizeMsg` implementation

3. **Print Functionality**
   - [x] `Println()` and `Printf()` methods
   - [x] Print above program output
   - [x] Print message handling

4. **Message Filtering**
   - [x] `WithFilter()` option
   - [x] Message transformation pipeline
   - [x] Filter application in event loop

#### Files to Modify/Create:

- [x] `src/features.cr` - Advanced feature implementations (integrated into term2.cr)
- [x] `src/messages.cr` - Additional message types (integrated into term2.cr)
- [x] `spec/features_spec.cr` - Advanced feature tests (integrated into term2_spec.cr)

## Phase 4: Enhanced Key Support & Polish (Week 7-8)

### Week 7: Comprehensive Key Sequence Support
**Goal**: Expand key sequence coverage to match BubbleTea

#### Tasks:
1. **Sequence Expansion**
   - [x] Add ~150+ additional key sequences from Go version
   - [x] Support for various terminal types (xterm, urxvt, etc.)
   - [x] Function keys F1-F20 with modifiers

2. **Advanced Key Features**
   - [x] Better alt+key combination handling
   - [x] Paste detection and marking
   - [x] Unknown sequence reporting
   - [x] Control character aliases

3. **Key Reader Improvements**
   - [x] More robust sequence matching
   - [x] Better buffer management
   - [x] Error handling for malformed sequences

#### Files to Modify/Create:
- [x] `src/key_sequences.cr` - Expanded sequence definitions
- [x] `src/key_reader.cr` - Enhanced key parsing (integrated into term2.cr)
- [x] `spec/key_sequences_spec.cr` - Key sequence tests (integrated into term2_spec.cr and focus_spec.cr)

### Week 8: Polish, Testing & Documentation
**Goal**: Final polish, comprehensive testing, and documentation

#### Tasks:
1. **Comprehensive Testing**
   - [x] Integration tests for all features
   - [x] Terminal interaction tests
   - [x] Cross-platform compatibility tests
   - [x] Performance benchmarks

2. **Error Handling & Robustness**
   - [x] Panic recovery system
   - [x] Graceful degradation
   - [x] Error reporting improvements

3. **Documentation & Examples**
   - [x] API documentation
   - [x] Feature usage examples
   - [x] Migration guide from Go
   - [x] Tutorials for common patterns

4. **Performance Optimization**
   - [x] Memory usage optimization
   - [x] Render performance improvements (FPS control, change detection)
   - [x] Input processing optimization (prefix set for O(1) lookups)

#### Files to Modify/Create:
- [x] `spec/integration_spec.cr` - End-to-end tests
- [x] `spec/cross_platform_spec.cr` - Cross-platform compatibility tests
- [x] `examples/` - Example programs
- [x] `docs/` - Comprehensive documentation
- [x] `benchmarks/` - Performance benchmarks

## Success Criteria

### Phase 1 Completion:
- [x] Alternate screen works correctly
- [x] Cursor control functions properly
- [x] Program options system is functional
- [x] All Phase 1 tests pass

### Phase 2 Completion:
- [x] Mouse events detected and parsed correctly
- [x] All mouse buttons and actions supported
- [x] Mouse configuration options work
- [x] Focus reporting functional

### Phase 3 Completion:
- [x] Renderer system with multiple implementations
- [x] Frame rate control working
- [x] Bracketed paste supported
- [x] Window resize handling

### Phase 4 Completion:
- [x] 95%+ key sequence parity with Go version
- [x] Comprehensive test suite (135 tests passing)
- [x] Full API documentation
- [x] Performance benchmarks

## Implementation Complete! 🎉

**Completion Date:** November 25, 2025

### Summary of Deliverables

**Core Features:**
- Full Elm Architecture (Model-Update-View) implementation
- Alternate screen mode with proper cleanup
- Cursor control (show/hide)
- Program options system (15+ options)
- Panic recovery with terminal restoration

**Input System:**
- 200+ key sequences (xterm, urxvt, linux console, VT100/VT220)
- Mouse support (SGR and legacy X10 protocols)
- Focus reporting (FocusIn/FocusOut)
- Bracketed paste mode
- Timeout-based escape sequence disambiguation

**Renderer System:**
- StandardRenderer with FPS control
- NilRenderer for headless mode
- Change detection (skip unchanged renders)
- Print above TUI functionality

**Components:**
- Spinner with customizable frames
- ProgressBar with percentage display
- TextInput with cursor support
- CountdownTimer

**Testing:**
- 135 specs covering all features
- Integration tests
- Cross-platform compatibility tests
- Performance benchmarks

**Documentation:**
- Full API documentation (Crystal doc comments)
- Migration guide from BubbleTea (Go)
- Tutorials for common patterns
- Feature usage examples

**Performance:**
- KeySequences.find: ~265M ops/sec
- KeySequences.prefix?: ~257M ops/sec (65x improvement)
- View layout: ~1B ops/sec
- Renderer: ~745M ops/sec

## Risk Mitigation

### Technical Risks:
1. **Terminal Compatibility**
   - Strategy: Test on multiple terminal emulators
   - Fallback: Graceful degradation for unsupported features

2. **Performance Impact**
   - Strategy: Benchmark early and often
   - Optimization: Profile and optimize critical paths

3. **Complexity Management**
   - Strategy: Modular implementation with clear interfaces
   - Testing: Comprehensive unit and integration tests

### Timeline Risks:
1. **Scope Creep**
   - Strategy: Strict adherence to phased approach
   - Prioritization: Must-have vs nice-to-have features

2. **Unexpected Complexity**
   - Strategy: Buffer time in each phase
   - Adaptation: Adjust scope if necessary

## Dependencies

### External Dependencies:
- Crystal language stability
- CML library compatibility
- Terminal emulator feature support

### Internal Dependencies:
- Phase 1 must complete before Phase 2
- Mouse support depends on input system improvements
- Renderer depends on message system

## Measurement & Tracking

### Progress Tracking:
- Weekly status updates
- Feature completion checklists
- Test coverage metrics
- Performance benchmarks

### Quality Metrics:
- Test coverage > 90%
- No memory leaks
- Cross-platform compatibility
- Documentation completeness

## Post-Implementation

### Maintenance:
- Regular compatibility testing
- Performance monitoring
- Community feedback incorporation

### Future Enhancements:
- Additional component library
- Theme system
- Plugin architecture
- Advanced layout system

---

*This plan will be updated weekly based on progress and any encountered challenges.*