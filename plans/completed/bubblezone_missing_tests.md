# BubbleZone Missing Tests & Verification Plan

**Goal**: Ensure Crystal test suite has 1:1 parity with Go test suite (the source of truth)

**Last Updated**: 2024-12-09
**Status**: COMPLETE

## Overview

This document tracks all missing tests from the Go reference implementation and verifies that existing Crystal tests match Go behavior exactly.

## Missing Tests from Go Implementation

### manager_test.go

**Status**: COMPLETE

#### Missing Test Cases from `testsScan` array

- [x] `"lipgloss-empty"` - lipgloss style with empty content
- [x] `"lipgloss-basic"` - lipgloss style with "testing"
- [x] `"lipgloss-basic-start"` - "a" + styled "testing"
- [x] `"lipgloss-basic-end"` - styled "testing" + "a"
- [x] `"lipgloss-basic-start-end"` - "a" + styled "testing" + "a"
- [x] `"lipgloss-basic-between"` - styled "testing" + "a" + styled "testing"
- [x] `"id-with-lipgloss-start"` - styled(Mark("testing7", "testing") + "testing")
- [x] `"id-with-lipgloss-end"` - styled("testing" + Mark("testing8", "testing"))
- [x] `"long-x1"` through `"long-x10"` - long style tests (10 tests)

**Note**: Go defines two styles:

- `testStyle`: Foreground(#FFFFFF), Background(#383838), Bold, Italic, Blink
- `longStyle`: Above + Underline, RoundedBorder, BorderForeground(#F12356), BorderBackground(#459082), Padding(5, 4)

#### Missing Test Functions

- [x] `BenchmarkScan` - performance benchmark (runs all test cases)
- [x] `BenchmarkMark` - performance benchmark (marks "testing" string)
- [x] `FuzzScan` - fuzz testing (seeds with test cases, fuzzes scan function)
- [x] `TestScanDisabled` - test scanning when disabled (returns input unchanged)
- [x] `TestMarkDisabled` - test marking when disabled (returns input unchanged)
- [x] `TestWorkerClear` - test worker clearing old zones (scans "foo", then "bar", foo should be cleared)
- [x] `TestClear` - test explicit zone clearing (creates zone, clears it, checks it's zero)
- [x] `TestClose` - test manager close functionality (closes manager, scanning should stop)
- [x] `TestGlobalInitialize` - test global initialization (can be initialized multiple times)

### zoneinfo_test.go

**Status**: COMPLETE

#### Missing Test Functions

- [x] `TestValidPosition` - test zone positioning
- [x] `TestInBounds` - test bounds checking with mouse events
- [x] `TestInBoundsZero` - test bounds checking with zero/empty zones
- [x] `TestPos` - test position calculation within zone

### messages_test.go

**Status**: COMPLETE

#### Missing Test Functions

- [x] `TestAnyInBounds` - test mouse event handling with single zone
- [x] `TestAnyInBoundsAndUpdate` - test mouse event handling with update return

## Existing Crystal Tests Verification

### manager_spec.cr

**Status**: COMPLETE

#### Tests to verify against Go

- [x] `"scan"` tests - verify each test case matches Go's `testsScan` array
- [x] `"scan with disabled manager"` - verify matches `TestScanDisabled`
- [x] `"mark"` tests - verify matches `TestMark` and `TestMarkDisabled`
- [x] `"worker clear"` - verify matches `TestWorkerClear`
- [x] `"clear"` - verify matches `TestClear`
- [x] `"close"` - verify matches `TestClose`
- [x] `"global initialization"` - verify matches `TestGlobalInitialize`

### zoneinfo_spec.cr

**Status**: COMPLETE

#### Tests to verify

- [x] Zone positioning tests - verify matches `TestValidPosition`
- [x] Bounds checking tests - verify matches `TestInBounds` and `TestInBoundsZero`
- [x] Position calculation tests - verify matches `TestPos`

### messages_spec.cr

**Status**: COMPLETE

#### Tests to verify

- [x] Mouse event tests - verify matches `TestAnyInBounds` and `TestAnyInBoundsAndUpdate`

### Other Crystal Tests (Not in Go)

**Status**: COMPLETE

#### Tests that extend beyond Go reference

- [x] `handle_mouse_spec.cr` - contains overlapping zones test (not in Go) - **420 lines**, extensive mouse handling tests
- [x] `complex_scenarios_spec.cr` - contains complex layout tests (not in Go) - **160 lines**, integration tests
- [x] `disabled_spec.cr` - disabled functionality tests (partially in Go) - **85 lines**, tests disabled state
- [x] `scan_spec.cr` - scanning tests (partially in Go) - **120 lines**, scanning-specific tests
- [x] `mark_spec.cr` - marking tests (partially in Go), scoped for Crystal coverage

**Decision needed**: Should these be kept, modified, or removed since they're not in Go reference?

**Analysis**:

1. `handle_mouse_spec.cr` - Tests overlapping zones which Go doesn't test. This is a Crystal extension.
2. `complex_scenarios_spec.cr` - Integration tests not in Go. Could be useful but not required for parity.
3. `disabled_spec.cr` - Partially covered by Go's `TestScanDisabled` and `TestMarkDisabled`.
4. `scan_spec.cr` and `mark_spec.cr` - These seem to duplicate tests in `manager_spec.cr`. Might be redundant.

## Implementation Notes

### Dependencies

1. **Lipgloss styling**: Go tests use `lipgloss` for styling tests. Need to check if Crystal has equivalent or if we need to mock/skip these tests.
2. **Benchmarks**: Crystal has `Benchmark` module for performance tests.
3. **Fuzz testing**: Crystal supports property-based testing but may need adaptation.

### Test Structure

1. Each Go test function should have a corresponding Crystal spec
2. Test data should match exactly (same inputs, expected outputs)
3. Edge cases should be identical

## Next Steps

1. **Phase 1**: Complete scan of all Go test files to ensure nothing missed
2. **Phase 2**: Verify existing Crystal tests match Go behavior
3. **Phase 3**: Implement missing tests
4. **Phase 4**: Review and decide on Crystal-only tests
5. **Phase 5**: Final verification run

## Verification Checklist

- [ ] All Go test functions have corresponding Crystal specs
- [ ] All test cases in Go arrays have corresponding Crystal test cases
- [ ] Edge cases match exactly
- [ ] Error conditions match exactly
- [ ] Performance characteristics are similar (where applicable)
- [ ] Fuzz testing covers same boundaries
