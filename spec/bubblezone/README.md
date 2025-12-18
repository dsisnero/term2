# BubbleZone Test Suite

This directory contains the Crystal port of the Go bubblezone test suite.

## Structure

```text
spec/bubblezone/
├── unit/                    # Unit tests for individual components
│   ├── zoneinfo_spec.cr    # ZoneInfo functionality tests
│   ├── manager_spec.cr     # Manager functionality tests
│   ├── messages_spec.cr    # Message handling tests
│   ├── scan_spec.cr        # Scan functionality tests
│   ├── mark_spec.cr        # Mark functionality tests
│   ├── disabled_spec.cr    # Disabled mode tests
│   └── handle_mouse_spec.cr # Mouse event tests
├── integration/            # Integration tests
│   └── complex_scenarios_spec.cr # Complex use cases
├── support/               # Test helpers and utilities
│   ├── bubblezone_helpers.cr # Shared helpers and matchers
│   └── spec_helper.cr    # Bubblezone-specific spec setup
└── fixtures/             # Test data (if needed)
```

## Test Coverage

This test suite ports the following Go test files:

1. **zoneinfo_test.go** → `zoneinfo_spec.cr`
   - Zone position calculations
   - Bounds checking
   - Relative position calculations

2. **manager_test.go** → `manager_spec.cr`
   - Scan functionality with various inputs
   - Mark functionality
   - Zone clearing and management
   - Worker/background processing

3. **messages_test.go** → `messages_spec.cr`
   - Mouse event handling
   - ZoneInBounds message sending
   - Model integration

## Running Tests

### Run all bubblezone tests

```bash
crystal spec spec/bubblezone/
```

### Run specific test categories

```bash
# Unit tests only
crystal spec spec/bubblezone/unit/

# Integration tests only
crystal spec spec/bubblezone/integration/

# Specific test file
crystal spec spec/bubblezone/unit/zoneinfo_spec.cr
```

### Run with coverage (if configured)

```bash
crystal spec --coverage spec/bubblezone/
```

## Test Patterns

### Custom Matchers

The test suite includes custom matchers in `support/bubblezone_helpers.cr`:

```crystal
# Check if zone contains point
zone.should contain_point(x, y)

# Check if zone exists at position
zone.should have_zone_at(x, y)
```

### Helper Methods

Common test patterns are available via the `BubbleZoneHelpers` module:

```crystal
# Create test zones
create_test_zone("id", x, y, width, height)
create_test_zones(5)

# Create mouse events
create_mouse_event(x, y, :left, :press)

# Wait for async processing
wait_for_zones(50) # 50ms

# Scan with automatic waiting
scan_and_wait(text, 100)

# Mark with automatic waiting
mark_and_wait("id", content, 100)
```

## Porting Notes

### Go → Crystal Differences

1. **Concurrency**: Go goroutines → Crystal fibers
2. **Error Handling**: Go multiple returns → Crystal exceptions/Result types
3. **Testing**: Go `testing` package → Crystal `spec` module
4. **Time**: Go `time.Sleep` → Crystal `sleep`

### Behavior Differences

Some tests may behave differently due to:

- Different event loop implementations
- Timing differences in async processing
- Memory model variations

### Pending Tests

Some tests are marked as `pending` when functionality:

- Doesn't exist in Crystal port yet
- Behaves significantly differently
- Requires additional implementation

## Adding New Tests

When adding new tests:

1. Follow existing patterns in the test suite
2. Use helper methods from `BubbleZoneHelpers`
3. Add appropriate `sleep` calls for async operations
4. Mark tests as `pending` if functionality is not yet implemented
5. Document any behavioral differences from Go version

## Debugging Tips

1. **Async Issues**: Increase sleep durations in `wait_for_zones`
2. **Zone Positions**: Use `puts zone.inspect` to debug coordinates
3. **Mouse Events**: Verify event coordinates match zone bounds
4. **Scan Results**: Compare raw strings with `inspect` to see escape sequences

## Integration with Existing Tests

Note that there are also existing tests in `spec/zone/` directory. These were created earlier and cover some of the same functionality. The bubblezone test suite in this directory aims to be a complete port of the Go test suite.

## CI Integration

The test suite should be integrated into the existing CI pipeline. All tests should pass before merging changes to bubblezone functionality.
