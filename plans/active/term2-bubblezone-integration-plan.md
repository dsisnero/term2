# Term2 BubbleZone Integration Implementation Plan

## Overview

This plan outlines the strategy for seamlessly integrating bubblezone functionality into term2 as a core feature rather than a separate library. The goal is to make interactive terminal applications feel native to term2.

## Project Structure Changes

### New Directory Structure

```text
term2/
├── src/
│   ├── term2/
│   │   ├── core/
│   │   │   ├── screen.cr
│   │   │   ├── input.cr
│   │   │   └── renderer.cr
│   │   ├── widgets/          # New directory
│   │   │   ├── base_widget.cr
│   │   │   ├── button.cr
│   │   │   ├── input_field.cr
│   │   │   └── container.cr
│   │   ├── interaction/      # New directory
│   │   │   ├── bubble_zone.cr
│   │   │   ├── event_manager.cr
│   │   │   ├── focus_manager.cr
│   │   │   └── mouse_handler.cr
│   │   └── term2.cr         # Main entry point
├── spec/
│   ├── integration/
│   │   ├── bubble_zone_spec.cr
│   │   └── widget_interaction_spec.cr
│   ├── unit/
│   │   ├── interaction/
│   │   └── widgets/
│   └── spec_helper.cr
└── examples/
    ├── interactive_demo.cr
    ├── widget_showcase.cr
    └── migration_example.cr
```

### Shard.yml Updates

```yaml
name: term2
version: 2.0.0
description: Advanced terminal UI library with built-in interactive elements

dependencies:
  # Remove bubblezone dependency

targets:
  term2:
    main: src/term2/term2.cr
```

## Implementation Phases

### Phase 1: Core Infrastructure (Week 1-2)

**Tasks:**

- [ ] Create interaction manager foundation
- [ ] Implement basic event system
- [ ] Add mouse event handling
- [ ] Create basic zone management
- [ ] Write core unit tests

**Key Files:**

- `src/term2/interaction/event_manager.cr`
- `src/term2/interaction/mouse_handler.cr`
- `src/term2/interaction/bubble_zone.cr`

### Phase 2: Widget System (Week 3-4)

**Tasks:**

- [ ] Implement Widget base class
- [ ] Create common widgets (Button, InputField, Container)
- [ ] Add focus management
- [ ] Implement basic styling system
- [ ] Write widget unit tests

**Key Files:**

- `src/term2/widgets/base_widget.cr`
- `src/term2/widgets/button.cr`
- `src/term2/widgets/input_field.cr`
- `src/term2/interaction/focus_manager.cr`

### Phase 3: Advanced Features (Week 5-6)

**Tasks:**

- [ ] Add keyboard navigation
- [ ] Implement z-index/layering
- [ ] Add animation support
- [ ] Create complex layout containers
- [ ] Write integration tests

**Key Files:**

- `src/term2/widgets/container.cr`
- `src/term2/interaction/keyboard_navigation.cr`
- `spec/integration/widget_interaction_spec.cr`

### Phase 4: Polish & Documentation (Week 7-8)

**Tasks:**

- [ ] Performance optimization
- [ ] Complete API documentation
- [ ] Create comprehensive examples
- [ ] Write migration guide
- [ ] Final testing and bug fixes

**Key Files:**

- `examples/interactive_demo.cr`
- `examples/migration_example.cr`
- `docs/interaction-guide.md`

## Code Integration Examples

### Core Screen Integration

```crystal
module Term2
  class Screen
    property interaction_manager : InteractionManager

    def initialize
      @interaction_manager = InteractionManager.new(self)
      # Existing initialization...
    end

    def handle_input : Bool
      if event = read_input
        # First try interaction manager (bubblezone)
        return true if @interaction_manager.process_event(event)

        # Fall back to traditional input handling
        handle_traditional_input(event)
      end
      false
    end
  end
end
```

### Widget Base Class

```crystal
module Term2
  abstract class Widget
    include InteractiveElement

    property position : {Int32, Int32}
    property size : {Int32, Int32}
    property interactive : Bool = true

    def initialize(@position, @size)
      register_interactive_area(position, size) if interactive
    end

    abstract def render(renderer : Renderer)

    def on_mouse_enter(mouse_event : MouseEvent) : Bool
      @hovered = true
      true
    end
  end
end
```

## Test Strategy

### Unit Tests

- **Interaction Manager**: Event processing, zone management
- **Widget Classes**: Individual widget behavior
- **Event System**: Event propagation and handling

### Integration Tests

- **Widget Interaction**: Complex UI scenarios
- **Focus Management**: Tab navigation, focus cycles
- **Performance**: Large numbers of interactive elements

### Performance Tests

- Zone lookup efficiency with 10,000+ zones
- Event processing latency
- Memory usage patterns

## Migration Guide

### Simple Migration

```crystal
# OLD
require "term2"
require "bubblezone"

zone = Bubblezone::Zone.new(0, 0, 10, 5)
zone.on_click { puts "Clicked!" }

# NEW
require "term2"

zone = screen.interaction_manager.register_zone(0, 0, 10, 5)
zone.on_click { puts "Clicked!" }

# OR use built-in widgets
button = Term2::Button.new({0, 0}, {10, 5}, "Click me")
button.onclick = ->{ puts "Clicked!" }
```

### Advanced Migration

```crystal
# OLD: Custom interactive element
class MyInteractiveElement
  include Bubblezone::Interactive

  def initialize
    register_zone(0, 0, 20, 10)
  end
end

# NEW: Term2 Widget
class MyInteractiveElement < Term2::Widget
  def initialize
    super({0, 0}, {20, 10})
  end

  def render(renderer : Term2::Renderer)
    renderer.draw_rectangle(@position, @size, @style)
  end
end
```

## Breaking Changes & Mitigation

### Breaking Changes

1. **Namespace changes**: `Bubblezone::Zone` → `Term2::Zone`
2. **Method signature changes**: Event handlers now take typed events
3. **Dependency removal**: No separate bubblezone shard required
4. **Initialization changes**: Interaction manager auto-initialized

### Compatibility Layer

```crystal
module Term2
  module Compatibility
    class BubblezoneAdapter
      def initialize(@interaction_manager : InteractionManager)
      end

      def register_zone(x, y, width, height)
        @interaction_manager.register_zone(x, y, width, height)
      end
    end
  end
end
```

## Performance Considerations

### Optimization Strategies

- Spatial partitioning for zone lookup
- Batch event processing
- Weak references for event handlers
- Efficient memory management

### Performance Targets

- Process 10,000 zones in < 1 second
- Handle 1,000 events/second
- Memory usage proportional to active zones

## Success Criteria

### Functional Requirements

- [ ] All existing bubblezone functionality available
- [ ] Backward compatibility maintained
- [ ] Performance meets or exceeds standalone bubblezone
- [ ] Comprehensive test coverage

### User Experience

- [ ] Intuitive API for new users
- [ ] Smooth migration path for existing users
- [ ] Clear documentation and examples
- [ ] No breaking changes without deprecation warnings

### Technical Quality

- [ ] Clean, maintainable code
- [ ] Comprehensive test suite
- [ ] Good performance characteristics
- [ ] Proper error handling

## Risk Mitigation

### Technical Risks

- **Performance degradation**: Extensive benchmarking and optimization
- **API complexity**: Progressive disclosure design pattern
- **Migration difficulties**: Comprehensive compatibility layer

### Project Risks

- **Scope creep**: Strict phase-based implementation
- **Timeline slippage**: Weekly progress reviews
- **Quality issues**: Continuous integration and code review

## Next Steps

1. Review and refine this plan
2. Begin Phase 1 implementation
3. Set up continuous integration
4. Create initial documentation structure

---
*Last Updated: 2024-12-19*
*Status: Active*