# Spec/BubbleZone Directory Structure

Based on the Oracle's plan, here's the proposed directory structure for bubblezone specs:

## Directory Layout

```text
spec/bubblezone/
├── unit/                    # Isolated bubblezone functionality tests
│   ├── zone_spec.cr        # Zone class tests
│   ├── bubble_zone_spec.cr # BubbleZone manager tests
│   ├── event_manager_spec.cr
│   ├── mouse_handler_spec.cr
│   └── focus_manager_spec.cr
├── integration/            # Widget interaction tests
│   ├── widget_interaction_spec.cr
│   ├── screen_integration_spec.cr
│   └── layout_integration_spec.cr
├── fixtures/              # Test data and helpers
│   ├── test_zones.cr
│   ├── test_events.cr
│   └── test_widgets.cr
└── support/              # Shared utilities
    ├── bubblezone_helpers.cr
    ├── custom_matchers.cr
    └── spec_helper.cr
```

## File Purposes

### Unit Tests (`spec/bubblezone/unit/`)

- **zone_spec.cr**: Tests for individual Zone class (boundaries, contains?, overlaps?)
- **bubble_zone_spec.cr**: Tests for BubbleZone manager (registration, lookup, management)
- **event_manager_spec.cr**: Event processing and routing tests
- **mouse_handler_spec.cr**: Mouse event handling tests
- **focus_manager_spec.cr**: Focus management and navigation tests

### Integration Tests (`spec/bubblezone/integration/`)

- **widget_interaction_spec.cr**: Tests for widget-zone interactions
- **screen_integration_spec.cr**: Tests for screen-level integration
- **layout_integration_spec.cr**: Tests for layout systems with zones

### Fixtures (`spec/bubblezone/fixtures/`)

- **test_zones.cr**: Predefined zone configurations for testing
- **test_events.cr**: Standardized test events (mouse clicks, keyboard)
- **test_widgets.cr**: Mock widgets for integration testing

### Support (`spec/bubblezone/support/`)

- **bubblezone_helpers.cr**: Shared setup/teardown, helper methods
- **custom_matchers.cr**: Custom RSpec-style matchers for bubblezone
- **spec_helper.cr**: Main spec helper that loads everything

## Custom Matchers to Create

1. **`have_zone_at(x, y)`**: Check if zone exists at coordinates
2. **`receive_mouse_event(type)`**: Check if zone receives mouse event
3. **`have_focus_on(element)`**: Check focus state
4. **`contain_point(x, y)`**: Check if point is within zone
5. **`overlap_with(other_zone)`**: Check zone overlap

## Test Data Generators

1. **Random zones**: Generate zones with random positions/sizes
2. **Grid zones**: Generate zones in grid pattern
3. **Overlapping zones**: Generate intentionally overlapping zones
4. **Nested zones**: Generate zones within zones

## Expected Go Test Files to Port

Based on typical bubblezone implementation, expect these Go test files:

1. **zone_test.go** - Basic zone functionality
2. **bubblezone_test.go** - Manager functionality
3. **mouse_test.go** - Mouse event handling
4. **focus_test.go** - Focus management
5. **integration_test.go** - Integration tests
6. **benchmark_test.go** - Performance tests (if any)

## Porting Strategy per File

### For zone_test.go → zone_spec.cr

- Go's `TestZoneContains` → Crystal's `describe "Zone#contains?"`
- Go's `TestZoneOverlaps` → Crystal's `describe "Zone#overlaps?"`
- Table tests → Crystal's data-driven examples

### For bubblezone_test.go → bubble_zone_spec.cr

- Registration tests → `describe "BubbleZone#register"`
- Lookup tests → `describe "BubbleZone#zone_at"`
- Performance tests → `describe "BubbleZone performance"`

## Initial Implementation Order

1. Create directory structure
2. Create base helper files
3. Port zone_test.go (simplest)
4. Port bubblezone_test.go (core)
5. Port mouse_test.go (event handling)
6. Port integration tests
7. Create missing widget integration tests
