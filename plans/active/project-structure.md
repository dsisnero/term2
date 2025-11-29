# Term2 BubbleZone Integration - Project Structure

## New Directory Structure

```text
term2/
├── src/
│   ├── term2/
│   │   ├── core/
│   │   │   ├── screen.cr              # Modified: Add interaction_manager
│   │   │   ├── input.cr               # Modified: Integrate event processing
│   │   │   └── renderer.cr            # Modified: Add zone tracking
│   │   ├── interaction/               # NEW: All interactive functionality
│   │   │   ├── interaction_manager.cr # Central coordination
│   │   │   ├── event_manager.cr       # Event processing pipeline
│   │   │   ├── mouse_handler.cr       # Mouse event processing
│   │   │   ├── keyboard_handler.cr    # Keyboard event processing
│   │   │   ├── focus_manager.cr       # Focus and tab navigation
│   │   │   ├── bubble_zone.cr         # Zone management
│   │   │   ├── zone.cr                # Individual zone class
│   │   │   └── interactive_element.cr # Base mixin for interactivity
│   │   ├── widgets/                   # NEW: Built-in interactive widgets
│   │   │   ├── base_widget.cr         # Abstract widget base class
│   │   │   ├── button.cr              # Clickable button
│   │   │   ├── input_field.cr         # Text input field
│   │   │   ├── label.cr               # Non-interactive text
│   │   │   ├── container.cr           # Base container
│   │   │   ├── vertical_layout.cr     # Vertical arrangement
│   │   │   ├── horizontal_layout.cr   # Horizontal arrangement
│   │   │   └── grid_layout.cr         # Grid arrangement
│   │   └── term2.cr                   # Main entry point
├── spec/
│   ├── unit/
│   │   ├── interaction/
│   │   │   ├── interaction_manager_spec.cr
│   │   │   ├── event_manager_spec.cr
│   │   │   ├── mouse_handler_spec.cr
│   │   │   ├── focus_manager_spec.cr
│   │   │   └── bubble_zone_spec.cr
│   │   ├── widgets/
│   │   │   ├── base_widget_spec.cr
│   │   │   ├── button_spec.cr
│   │   │   ├── input_field_spec.cr
│   │   │   └── container_spec.cr
│   │   └── spec_helper.cr
│   ├── integration/
│   │   ├── screen_integration_spec.cr
│   │   ├── widget_interaction_spec.cr
│   │   └── focus_navigation_spec.cr
│   └── performance/
│       ├── zone_performance_spec.cr
│       ├── event_processing_spec.cr
│       └── memory_usage_spec.cr
├── examples/
│   ├── interactive_demo.cr            # Comprehensive demo
│   ├── widget_showcase.cr             # All widgets in action
│   ├── migration_example.cr           # Migration from bubblezone
│   ├── custom_widget.cr               # Custom widget example
│   └── complex_layout.cr              # Advanced layout example
└── docs/
    ├── interaction-guide.md           # How to use interactive features
    ├── migration-guide.md             # Migrating from bubblezone
    ├── widget-reference.md            # Widget API reference
    └── examples/                      # Example documentation
        ├── interactive-demo.md
        └── migration-examples.md
```

## Key Integration Points

### 1. Screen Integration

**File:** `src/term2/core/screen.cr`

```crystal
class Screen
  property interaction_manager : InteractionManager

  def initialize
    @interaction_manager = InteractionManager.new(self)
    # ... existing initialization
  end

  def handle_input : Bool
    if event = read_input
      # Priority: interaction manager first
      return true if @interaction_manager.process_event(event)

      # Fallback: traditional input handling
      handle_traditional_input(event)
    end
    false
  end

  def render
    @interaction_manager.pre_render
    traditional_render
    @interaction_manager.post_render
  end
end
```

### 2. Input System Integration

**File:** `src/term2/core/input.cr`

```crystal
# Enhanced to work with interaction manager
# Mouse events are passed to interaction manager first
# Keyboard events for focus navigation
```

### 3. Renderer Integration

**File:** `src/term2/core/renderer.cr`

```crystal
# Optional: Automatic zone tracking for rendered content
# Could track cursor position and automatically create zones
# for certain types of output
```

## Core Interaction Components

### InteractionManager

- Central coordination of all interactive elements
- Event routing and processing
- Zone management and lookup
- Focus management coordination

### EventManager

- Event processing pipeline
- Event propagation (bubbling/capturing)
- Custom event support
- Performance monitoring

### FocusManager

- Tab navigation between interactive elements
- Focus visual indicators
- Focus event handling
- Accessibility support

### BubbleZone

- Spatial partitioning for efficient zone lookup
- Zone lifecycle management
- Performance optimization
- Memory management

## Widget System

### BaseWidget

- Abstract base class for all widgets
- Automatic interactive area registration
- Common event handling
- Styling and rendering interface

### Built-in Widgets

- **Button**: Clickable element with text
- **InputField**: Text input with cursor
- **Label**: Non-interactive text display
- **Container**: Base for layout containers
- **Layouts**: Vertical, horizontal, grid arrangements

## Testing Strategy

### Unit Tests

- Individual component behavior
- Event processing logic
- Widget functionality
- Focus management

### Integration Tests

- Screen integration
- Widget interaction scenarios
- Focus navigation flows
- Complex UI layouts

### Performance Tests

- Zone lookup efficiency
- Event processing latency
- Memory usage patterns
- Large-scale scenarios

## Migration Support

### Compatibility Layer

```crystal
module Term2::Compatibility
  class BubblezoneAdapter
    # Provides familiar bubblezone API
    # Automatically converts to new system
    # Issues deprecation warnings
  end
end
```

### Automatic Conversion

- Existing bubblezone code works with minimal changes
- Gradual migration path
- Clear upgrade instructions

## Performance Considerations

### Spatial Partitioning

- Divide screen into regions for efficient zone lookup
- Handle overlapping zones with z-index
- Optimize for common usage patterns

### Event Processing

- Batch processing where possible
- Early termination for handled events
- Efficient data structures

### Memory Management

- Weak references for event handlers
- Automatic cleanup of unused zones
- Predictable memory growth

## Next Steps for Implementation

1. **Create directory structure**
2. **Implement core interaction components**
3. **Integrate with existing screen system**
4. **Create basic widget system**
5. **Add comprehensive testing**
6. **Implement performance optimizations**
7. **Create documentation and examples**
8. **Add migration support**

This structure provides a solid foundation for seamless bubblezone integration while maintaining the existing term2 architecture and providing a clear path for future enhancements.