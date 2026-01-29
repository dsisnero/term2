# Term2 v2 API Update Plan

## Overview

This plan outlines the implementation of Bubble Tea v2 API compatibility for the Term2 Crystal port. The goal is to update Term2 to match the new architecture and features introduced in Bubble Tea v2 while maintaining backward compatibility for existing users.

**Target Version**: Bubble Tea v2-exp branch (commit `76f2e6d81219acce9d8eccb61845d20a77216cf1`)
**Current Term2 State**: v1-compatible API with Model returning `String` from `view` method
**Timeline**: 4-6 weeks for complete implementation
**Created**: January 29, 2026
**Status**: Active
**Priority**: High

## Current Analysis

### Bubble Tea v2 Key Changes
1. **Msg System**: `type Msg = uv.Event` (ultraviolet event system)
2. **View System**: `View()` returns `View` struct instead of `string`
3. **Renderer**: New `cursed_renderer` based on ultraviolet library
4. **New Features**: Clipboard, color profiles, keyboard enhancements, window title, progress bars
5. **Breaking Changes**: `MouseMsg` changes, keyboard event system overhaul

### Term2 Current Architecture
- **Model**: `Term2::Model` module with `view : String` method
- **Msg**: `Term2::Message` class hierarchy (type-safe)
- **Renderer**: Custom diffing renderer with ANSI optimization
- **Components**: 15+ UI components returning strings

## Phases

### Phase 1: Core API Updates (Week 1-2)
**Goal**: Update Model interface and create View struct system

#### Tasks
1. **Create View Struct** (`src/view.cr`)
   - [ ] Mirror Bubble Tea v2 `View` struct fields
   - [ ] Content, Cursor, BackgroundColor, ForegroundColor, WindowTitle
   - [ ] AltScreen, ReportFocus, MouseMode, KeyboardEnhancements
   - [ ] ProgressBar (future), OnMouse handler (future)

2. **Update Model Interface** (`src/base_types.cr`)
   - [ ] Change `view` return type to `Term2::View`
   - [ ] Add backward compatibility via union type `String | View`
   - [ ] Create `NewView()` helper function

3. **Update Core Components** (selected)
   - [ ] Update 5 core components to return `View`: `TextInput`, `List`, `Table`, `Viewport`, `Spinner`
   - [ ] Add compatibility shims for string-based views

4. **Update Examples**
   - [ ] Update 3-5 examples to use new View API
   - [ ] Create v2-specific examples directory

#### Files to Modify/Create
- `src/view.cr` - New View struct and helper functions
- `src/base_types.cr` - Updated Model interface
- `src/components/` - Updated component view methods
- `examples/v2/` - New v2-specific examples

#### Success Criteria
- Model interface accepts both `String` and `View` returns
- Core components work with new View system
- Existing examples continue to work

### Phase 2: Renderer Integration (Week 3-4)
**Goal**: Update renderer to handle View struct and ultraviolet concepts

#### Tasks
1. **Analyze Ultraviolet Integration**
   - [ ] Evaluate ultraviolet library vs custom implementation
   - [ ] Decide: port ultraviolet to Crystal or create compatible interface
   - [ ] Research `uv.Event` system for Msg compatibility

2. **Update Renderer Interface** (`src/renderer.cr`)
   - [ ] Add `render_view(view : View)` method
   - [ ] Handle cursor positioning, colors, window title
   - [ ] Integrate with existing diffing algorithm

3. **Create CursedRenderer Prototype**
   - [ ] Basic ultraviolet-style renderer
   - [ ] Layer compositing support
   - [ ] Color profile integration

4. **Update Zone System**
   - [ ] Ensure zone markers work with View content
   - [ ] Mouse event handling with View.OnMouse callbacks

#### Files to Modify/Create
- `src/renderer.cr` - Updated renderer interface
- `src/cursed_renderer.cr` - New ultraviolet-compatible renderer
- `src/zone.cr` - Updated zone handling

#### Success Criteria
- Renderer can render View struct with all basic fields
- Cursor, colors, window title work correctly
- Zone system integrates with new renderer

### Phase 3: New Feature Implementation (Week 5-6)
**Goal**: Implement v2-specific features

#### Tasks
1. **Keyboard Enhancement System**
   - [ ] `KeyboardEnhancements` struct with `ReportEventTypes`
   - [ ] Key repeat and release event support
   - [ ] Enhanced key parsing (shift+enter, ctrl+i, etc.)

2. **Clipboard Support** (`src/clipboard.cr`)
   - [ ] System clipboard read/write
   - [ ] Cross-platform compatibility (macOS, Linux, Windows)

3. **Color Profile System** (`src/color_profile.cr`)
   - [ ] Integrate with existing color system
   - [ ] Dark/light mode detection
   - [ ] Color space conversions

4. **Environment Detection** (`src/environ.cr`)
   - [ ] Terminal type detection ($TERM)
   - [ ] Feature capability detection
   - [ ] Platform-specific behavior

5. **Mouse Enhancement**
   - [ ] `OnMouse` handler in View struct
   - [ ] View-relative mouse coordinates
   - [ ] SGR/X10 protocol improvements

#### Files to Modify/Create
- `src/clipboard.cr` - New clipboard module
- `src/environ.cr` - New environment detection
- `src/keyboard_enhancements.cr` - New keyboard features
- `src/mouse.cr` - Enhanced mouse handling

#### Success Criteria
- Keyboard enhancements work with major terminals
- Clipboard operations succeed in examples
- Color profiles adapt to terminal capabilities

### Phase 4: Component Updates & Testing (Week 7-8)
**Goal**: Update all components and ensure comprehensive test coverage

#### Tasks
1. **Update Remaining Components**
   - [ ] Update all 15+ components to use View API
   - [ ] Add new v2 features where applicable

2. **Test Suite Updates**
   - [ ] Update existing 135+ tests for v2 API
   - [ ] Add tests for new features
   - [ ] Ensure backward compatibility tests

3. **Documentation**
   - [ ] API documentation for new View system
   - [ ] Migration guide from v1 to v2
   - [ ] Example gallery with v2 features

4. **Performance Optimization**
   - [ ] Benchmark new renderer vs old
   - [ ] Optimize View struct copying
   - [ ] Memory usage analysis

#### Files to Modify/Create
- `spec/` - Updated test suite
- `docs/v2_migration.md` - Migration guide
- `examples/v2_gallery/` - Comprehensive v2 examples

#### Success Criteria
- All components support View API
- Test suite passes with >90% coverage
- Documentation complete and examples work

## Key Technical Decisions

### 1. Ultraviolet Integration Strategy
**Option A**: Port ultraviolet to Crystal (heavy lift, high compatibility)
**Option B**: Create compatible interface without full port (pragmatic, maintainable)
**Recommendation**: Start with Option B, implement necessary ultraviolet concepts in Crystal

### 2. Backward Compatibility Approach
**Option A**: Breaking change - require users to update
**Option B**: Dual API - support both String and View returns
**Recommendation**: Option B with deprecation warnings for String returns

### 3. View Struct Design
```crystal
struct View
  property content : String
  property cursor : Cursor?
  property background_color : Color?
  property foreground_color : Color?
  property window_title : String?
  property alt_screen : Bool = false
  property report_focus : Bool = false
  property mouse_mode : MouseMode = MouseMode::None
  property keyboard_enhancements : KeyboardEnhancements = KeyboardEnhancements.new
  property disable_bracketed_paste_mode : Bool = false
end
```

### 4. Msg System Evolution
**Current**: `Term2::Message` class hierarchy
**v2 Approach**: Keep existing system, add ultraviolet event compatibility
**Implementation**: Create `UVEvent` wrapper or adapter pattern

## Risks & Mitigation

### High Risk: Ultraviolet Complexity
- **Risk**: Ultraviolet is complex Go library, hard to port
- **Mitigation**: Start with minimal compatibility layer, implement only needed features
- **Fallback**: Custom renderer that mimics v2 API without ultraviolet internals

### Medium Risk: Breaking Existing Code
- **Risk**: Users' code breaks with v2 changes
- **Mitigation**: Comprehensive backward compatibility, detailed migration guide
- **Fallback**: Provide compatibility shims for extended transition period

### Low Risk: Performance Regression
- **Risk**: New View struct adds overhead
- **Mitigation**: Benchmark early, optimize struct copying, use immutable patterns
- **Fallback**: Profile and optimize hot paths

## Success Metrics

1. **API Compatibility**: 90% of Bubble Tea v2 public API implemented
2. **Backward Compatibility**: All existing examples work with minimal changes
3. **Performance**: No more than 10% performance regression in rendering
4. **Test Coverage**: >85% test coverage for new features
5. **Documentation**: Complete API docs and migration guide

## Timeline Summary

- **Week 1-2**: Core API updates, View struct, Model interface
- **Week 3-4**: Renderer integration, ultraviolet compatibility
- **Week 5-6**: New features (keyboard, clipboard, color profiles)
- **Week 7-8**: Component updates, testing, documentation
- **Week 9**: Performance optimization, final polish

## Initial Implementation Steps

1. [ ] Create `src/view.cr` with View struct definition
2. [ ] Update `src/base_types.cr` Model module to accept View returns
3. [ ] Create compatibility layer for string-based views
4. [ ] Update `src/term2.cr` Program to handle View rendering
5. [ ] Create simple example demonstrating new API
6. [ ] Run existing test suite to identify breaking changes

## Resources Needed

1. **Bubble Tea v2 Documentation**: API reference, examples
2. **Ultraviolet Source Code**: Understand event system
3. **Term2 Test Suite**: Ensure backward compatibility
4. **Performance Profiling Tools**: Identify bottlenecks early

## Dependencies

- **Bubble Tea v2-exp branch**: Source of truth for API changes
- **Ultraviolet library**: Reference implementation for event system
- **Existing Term2 codebase**: Must maintain backward compatibility
- **Crystal compiler**: Latest stable version for new features

## Related Work

- `plans/completed/bubbletea-feature-parity.md` - Original v1 implementation
- `AGENTS.md` - Development workflow and commands
- `FEATURE_PARITY_PLAN.md` - Previous feature planning

## Next Actions

1. [ ] Review this plan and provide feedback
2. [ ] Start with Phase 1, Task 1 (Create View Struct)
3. [ ] Establish weekly checkpoints for progress review
4. [ ] Create issue tracker for v2 implementation tasks

---

**Plan Version**: 1.0
**Last Updated**: January 29, 2026
**Based On**: Bubble Tea v2-exp branch analysis
**Target Completion**: March 2025