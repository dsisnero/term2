# V2-Exp Output Verification Plan

## Overview

There are extreme differences in output between the Crystal implementation and the Go v2-exp reference implementation. This plan outlines a systematic approach to verify output parity, identify discrepancies, and prioritize fixes.

## Current State

### Golden File Infrastructure

- **Golden library**: Used for storing expected output (`spec/testdata/`)
- **Generation scripts**: `scripts/golden/gen_*.sh` run Go programs to generate golden files
- **Existing golden files**: Currently limited to examples (DoomFire, Tabs, ListFancy, etc.) and a few components (Table)
- **Missing golden files**: Most components lack golden files for v2-exp API

### Component Coverage

The following components need golden file generation and verification:

| Component | Golden Files Exist | Notes |
|-----------|-------------------|-------|
| TextArea | Partial (text_area_view_spec.cr) | Need v2-exp golden files |
| TextInput | No | |
| List | No | |
| Table | Yes (in vendor/bubbles/table/testdata) | Need to symlink or copy |
| Viewport | No | |
| Spinner | No | |
| Progress | No | |
| Paginator | No | |
| Help | No | |
| Cursor | No | |
| Key | No | |
| FilePicker | Yes (spec/testdata/BubblesFilePicker) | |
| Timer | No | |
| Stopwatch | No | |

### Known Issues

1. **Missing symlinks**: `spec/bubbles/` expects golden files in `bubbles/component/testdata/` but they're in `vendor/bubbles/component/testdata/`
2. **Color profile differences**: Output varies based on terminal color capabilities
3. **ANSI sequence variations**: Different escape code rendering between Go and Crystal
4. **Styling differences**: Lipgloss v2-exp API changes may not be fully implemented

## Verification Plan

### Phase 1: Golden File Generation

**Goal**: Generate golden files for all components using Go v2-exp reference implementations.

**Tasks**:
1. Create Go generator programs for each component under `scripts/golden/`
2. Update `run_go_generator.sh` to use v2-exp submodules
3. Generate golden files for:
   - Basic rendering (default styles)
   - Styled rendering (with borders, colors, etc.)
   - Interactive states (focused, disabled, etc.)
   - Edge cases (empty data, overflow, etc.)

**Output**: Complete set of golden files in `spec/testdata/`

### Phase 2: Crystal Spec Execution

**Goal**: Run Crystal component specs that compare with golden files to identify failures.

**Tasks**:
1. Update component specs to use golden file comparisons
2. Run `crystal spec spec/components/` and `crystal spec spec/bubbles/`
3. Document which tests pass/fail
4. Capture actual output for failing tests

**Output**: Failure report with diff outputs

### Phase 3: Systematic Comparison Tool

**Goal**: Create a tool to capture Crystal output and compare with golden files line-by-line.

**Tasks**:
1. Develop `scripts/compare_output.cr` that:
   - Runs a Crystal component with same parameters as Go generator
   - Captures output (ANSI sequences preserved)
   - Compares with golden file using diff algorithm
   - Generates HTML report with side-by-side comparison
2. Integrate with CI for automated regression detection

**Output**: Comparison tool and regression test suite

### Phase 4: Difference Categorization

**Goal**: Categorize differences to understand root causes.

**Categories**:
1. **ANSI Sequences**: Different escape codes for same styling
2. **Spacing**: Padding/margin differences
3. **Styling**: Missing or incorrect style properties
4. **Rendering Algorithms**: Different wrapping/truncation logic
5. **Missing Features**: v2-exp APIs not implemented in Crystal
6. **Platform Differences**: Line endings, character encoding

**Tasks**:
1. Analyze failing tests and assign categories
2. Create issue for each category with examples

**Output**: Categorized issue list with priority levels

### Phase 5: Fix Prioritization and Implementation

**Goal**: Prioritize and implement fixes based on component importance and magnitude of difference.

**Priority Criteria**:
1. **High**: Core components (TextInput, List, TextArea) with major output differences
2. **Medium**: Secondary components with moderate differences
3. **Low**: Minor styling differences, edge cases

**Tasks**:
1. Create implementation plan for each component
2. Fix highest priority differences first
3. Update golden files after fixes
4. Verify parity with Go output

**Output**: Fixed components with passing tests

## Timeline

- **Week 1**: Phase 1 (Golden File Generation)
- **Week 2**: Phase 2-3 (Spec Execution & Comparison Tool)
- **Week 3**: Phase 4 (Difference Categorization)
- **Week 4-6**: Phase 5 (Fix Implementation)

## Success Metrics

1. **90% component coverage**: Golden files exist for all major components
2. **80% test pass rate**: Crystal specs pass against golden files
3. **Zero major differences**: Core functionality produces identical output
4. **Automated regression detection**: CI fails when output diverges

## Resources Needed

1. **Go v2-exp submodules**: Updated to latest commits
2. **Crystal compiler**: Latest stable version
3. **CI environment**: Consistent terminal emulation (xterm-256color)
4. **Development time**: 4-6 weeks

## Risks and Mitigation

- **Risk**: Go v2-exp API still changing
  - **Mitigation**: Pin submodule to specific commit, update monthly
- **Risk**: Crystal implementation lags behind Go features
  - **Mitigation**: Focus on API parity first, then optimize
- **Risk**: Performance regression from strict output matching
  - **Mitigation**: Allow minor differences where they don't affect functionality

## Next Steps

1. [ ] Create golden file generators for missing components
2. [ ] Update `spec/bubbles/` to use correct golden file paths
3. [ ] Run comprehensive test suite and document failures
4. [ ] Develop comparison tool for automated verification
5. [ ] Begin fixing highest priority differences

## Related Documents

- [V2 Update Plan](./v2_update.md)
- [How to Test with Teatest](./how_to_test.md)
- [Golden Library Documentation](../lib/golden/README.md)

---

*Last Updated: February 11, 2026*
*Status: Planning*