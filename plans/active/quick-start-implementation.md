# Quick Start Implementation Guide

## Phase 1: Core Infrastructure (Week 1-2)

### Step 1: Create Directory Structure

```bash
mkdir -p src/term2/interaction
mkdir -p src/term2/widgets
mkdir -p spec/unit/interaction
mkdir -p spec/unit/widgets
mkdir -p spec/integration
mkdir -p examples
```

### Step 2: Implement Core Interaction Classes

**File:** `src/term2/interaction/interaction_manager.cr`

```crystal
module Term2
  # Central manager for all interactive elements
  class InteractionManager
    @zones : Array(Zone) = [] of Zone
    @focus_manager : FocusManager
    @event_manager : EventManager

    def initialize(screen : Screen)
      @screen = screen
      @focus_manager = FocusManager.new
      @event_manager = EventManager.new
    end

    def register_zone(x : Int32, y : Int32, width : Int32, height : Int32) : Zone
      zone = Zone.new(x, y, width, height)
      @zones << zone
      zone
    end

    def process_event(event : Event) : Bool
      @event_manager.process(event)
    end
  end
end
```

**File:** `src/term2/interaction/zone.cr`

```crystal
module Term2
  class Zone
    property x : Int32, y : Int32, width : Int32, height : Int32
    property on_click : Proc(MouseEvent, Bool)? = nil

    def initialize(@x, @y, @width, @height)
    end

    def contains?(x : Int32, y : Int32) : Bool
      x >= @x && x < @x + @width && y >= @y && y < @y + @height
    end
  end
end
```

### Step 3: Integrate with Screen

**File:** `src/term2/core/screen.cr` (modify)

```crystal
class Screen
  property interaction_manager : InteractionManager

  def initialize
    @interaction_manager = InteractionManager.new(self)
    # ... existing code
  end

  def handle_input : Bool
    if event = read_input
      return true if @interaction_manager.process_event(event)
      handle_traditional_input(event)
    end
    false
  end
end
```

### Step 4: Basic Tests

**File:** `spec/unit/interaction/interaction_manager_spec.cr`

```crystal
require "../spec_helper"

describe Term2::InteractionManager do
  it "registers and finds zones" do
    screen = Term2::Screen.new
    manager = Term2::InteractionManager.new(screen)

    zone = manager.register_zone(0, 0, 10, 5)
    zone.should be_a(Term2::Zone)
  end

  it "handles mouse events in zones" do
    screen = Term2::Screen.new
    manager = Term2::InteractionManager.new(screen)

    zone = manager.register_zone(0, 0, 10, 5)
    clicked = false
    zone.on_click = ->(event : Term2::MouseEvent) { clicked = true; true }

    # Simulate mouse click in zone
    event = Term2::MouseEvent.new(x: 5, y: 2, button: :left, action: :press)
    manager.process_event(event).should be_true
    clicked.should be_true
  end
end
```

## Phase 2: Widget System (Week 3-4)

### Step 1: Create Widget Base Class

**File:** `src/term2/widgets/base_widget.cr`

```crystal
module Term2
  abstract class Widget
    property position : {Int32, Int32}
    property size : {Int32, Int32}
    property interactive : Bool = true

    def initialize(@position, @size)
      register_interactive_area if interactive
    end

    abstract def render(renderer : Renderer)

    def on_mouse_enter(event : MouseEvent) : Bool
      false # Override in subclasses
    end

    def on_mouse_leave(event : MouseEvent) : Bool
      false
    end

    def on_click(event : MouseEvent) : Bool
      false
    end

    private def register_interactive_area
      # Auto-register with interaction manager
    end
  end
end
```

### Step 2: Implement Button Widget

**File:** `src/term2/widgets/button.cr`

```crystal
module Term2
  class Button < Widget
    property label : String
    property onclick : Proc(Nil)? = nil

    def initialize(position : {Int32, Int32}, size : {Int32, Int32}, @label : String)
      super(position, size)
    end

    def render(renderer : Renderer)
      # Simple button rendering
      renderer.draw_rectangle(@position, @size, @style)
      renderer.draw_text(@position, @label, @style)
    end

    def on_click(event : MouseEvent) : Bool
      @onclick.try(&.call)
      true
    end
  end
end
```

### Step 3: Create Example

**File:** `examples/simple_button.cr`

```crystal
require "../src/term2"

screen = Term2::Screen.new

# Create a button
button = Term2::Button.new({10, 5}, {20, 3}, "Click Me!")
button.onclick = ->{ puts "Button clicked!" }

# Main loop
loop do
  screen.render
  break unless screen.handle_input
end
```

## Immediate Next Actions

1. **Set up the basic directory structure**
2. **Implement InteractionManager and Zone classes**
3. **Integrate with Screen class**
4. **Write basic unit tests**
5. **Test the integration works**
6. **Begin Phase 2 implementation**

## Testing Commands

```bash
# Run unit tests
crystal spec spec/unit/interaction/

# Run all tests
crystal spec

# Build and test examples
crystal build examples/simple_button.cr
./simple_button
```

## Success Criteria for Phase 1

- [ ] InteractionManager can be instantiated
- [ ] Zones can be registered and found
- [ ] Mouse events are processed in zones
- [ ] Screen integration works
- [ ] Unit tests pass
- [ ] Basic example runs without errors

This quick start guide provides the minimal implementation needed to get the core bubblezone integration working within term2. Each subsequent phase builds on this foundation.