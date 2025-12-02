# Lipgloss Examples Porting Plan

## Overview

This document outlines the plan for porting lipgloss examples from Go to Crystal for the term2 library.

## Current Status

- ✅ **List Examples**: COMPLETED (8 examples ported)
- ⏳ **Other Examples**: PENDING

## Example Categories to Port

### 1. Layout Examples (`layout/`)

**Source**: `/lipgloss/examples/layout/simple.go`
**Complexity**: Low
**Key Concepts**:

- `lipgloss.Place()` for positioning
- Width/height calculations
- Center alignment
**Porting Priority**: HIGH (simple, foundational)

### 2. Table Examples (`table/`)

**Source**: `/lipgloss/examples/table/pokemon.go`
**Complexity**: Medium
**Key Concepts**:

- Table formatting with borders
- Column alignment
- Row styling
**Porting Priority**: HIGH (useful for data display)

### 3. Tree Examples (`tree/`)

**Source**: `/lipgloss/examples/tree/simple.go`
**Complexity**: Medium
**Key Concepts**:

- Tree structure rendering
- Indentation levels
- Branch characters
**Porting Priority**: MEDIUM

### 4. SSH Examples (`ssh/`)

**Source**: `/lipgloss/examples/ssh/main.go`
**Complexity**: High
**Key Concepts**:

- Custom renderers for SSH sessions
- Terminal capability detection
- Wish SSH server integration
**Porting Priority**: LOW (advanced, requires SSH server)

### 5. Style Examples (to be created)

**Categories needed**:

- Border styles
- Color examples
- Margin/padding examples
- Text styling examples
**Porting Priority**: MEDIUM (educational value)

## Porting Strategy

### Phase 1: Foundation (Week 1)

1. Create directory structure for all example categories
2. Port layout examples (simplest)
3. Port table examples (most practical)

### Phase 2: Core Examples (Week 2)

1. Port tree examples
2. Create basic style examples
3. Test all examples

### Phase 3: Advanced Examples (Week 3)

1. Port SSH examples (if feasible)
2. Create comprehensive documentation
3. Add integration tests

## Technical Considerations

### 1. Architecture Differences

- **lipgloss**: Pure text formatting library
- **term2**: Interactive UI framework with components
- **Approach**: Create simple formatting functions that mimic lipgloss behavior

### 2. Dependencies

- SSH examples require Wish (Go SSH server) - may need alternative approach
- Consider creating simplified versions for educational purposes

### 3. Crystal-Specific Adaptations

- Use Crystal's `String.build` instead of Go's `strings.Builder`
- Adapt Go's struct patterns to Crystal's class/struct system
- Handle error checking differently (exceptions vs error returns)

## Directory Structure

```text
examples/lipgloss/
├── TODO.md
├── PORTING_PLAN.md
├── list/              # ✅ COMPLETED
│   ├── simple.cr
│   ├── bullet.cr
│   ├── dash.cr
│   ├── asterisk.cr
│   ├── alphabet.cr
│   ├── arabic.cr
│   ├── roman.cr
│   └── none.cr
├── layout/            # ⏳ TO PORT
│   └── simple.cr
├── table/             # ⏳ TO PORT
│   └── pokemon.cr
├── tree/              # ⏳ TO PORT
│   └── simple.cr
├── ssh/               # ⏳ TO PORT (optional)
│   └── main.cr
├── border/            # ⏳ TO CREATE
│   └── simple.cr
├── color/             # ⏳ TO CREATE
│   └── simple.cr
├── margin/            # ⏳ TO CREATE
│   └── simple.cr
├── padding/           # ⏳ TO CREATE
│   └── simple.cr
├── style/             # ⏳ TO CREATE
│   └── simple.cr
└── text/              # ⏳ TO CREATE
    └── simple.cr
```

## Success Criteria

1. All examples compile without errors
2. Examples produce similar output to Go versions
3. Code follows Crystal idioms and best practices
4. Examples are well-documented with comments
5. README files explain how to run each example

## Next Immediate Actions

1. Create `layout/` directory and port `simple.go`
2. Create `table/` directory and port `pokemon.go`
3. Update TODO.md with progress
4. Test compiled examples