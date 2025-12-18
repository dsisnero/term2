# spec/bubblezone/support/bubblezone_helpers.cr
# Base helper file for bubblezone specs

module BubbleZoneHelpers
  # Shared setup and teardown methods

  def create_test_zone(x = 0, y = 0, width = 10, height = 5, id = nil)
    Zone.new(x, y, width, height, id)
  end

  def create_test_zones(count = 3)
    zones = [] of Zone
    count.times do |i|
      zones << create_test_zone(i * 15, i * 10, 10, 5, "zone_#{i}")
    end
    zones
  end

  def create_mouse_event(x = 0, y = 0, button = :left, action = :press)
    MouseEvent.new(x: x, y: y, button: button, action: action)
  end

  def create_key_event(key = "a", mods = [] of Symbol)
    KeyEvent.new(key: key, modifiers: mods)
  end

  # Custom matchers for bubblezone assertions

  class HaveZoneAt < Spec::Matchers::Matcher
    def initialize(@expected_x : Int32, @expected_y : Int32)
    end

    def description
      "have a zone at (#{@expected_x}, #{@expected_y})"
    end

    def match(actual : BubbleZone)
      actual.zone_at(@expected_x, @expected_y) != nil
    end

    def failure_message(actual)
      "expected bubblezone to have a zone at (#{@expected_x}, #{@expected_y}), but none found"
    end

    def negative_failure_message(actual)
      "expected bubblezone not to have a zone at (#{@expected_x}, #{@expected_y}), but found one"
    end
  end

  class ContainPoint < Spec::Matchers::Matcher
    def initialize(@x : Int32, @y : Int32)
    end

    def description
      "contain point (#{@x}, #{@y})"
    end

    def match(actual : Zone)
      actual.contains?(@x, @y)
    end

    def failure_message(actual)
      "expected zone #{actual} to contain point (#{@x}, #{@y})"
    end

    def negative_failure_message(actual)
      "expected zone #{actual} not to contain point (#{@x}, #{@y})"
    end
  end

  class OverlapWith < Spec::Matchers::Matcher
    def initialize(@other_zone : Zone)
    end

    def description
      "overlap with zone #{@other_zone}"
    end

    def match(actual : Zone)
      actual.overlaps?(@other_zone)
    end

    def failure_message(actual)
      "expected zone #{actual} to overlap with #{@other_zone}"
    end

    def negative_failure_message(actual)
      "expected zone #{actual} not to overlap with #{@other_zone}"
    end
  end

  # Helper methods for common test patterns

  def with_bubblezone(&)
    bz = BubbleZone.new
    yield bz
  end

  def with_registered_zone(bz, x = 0, y = 0, width = 10, height = 5, &)
    zone = bz.register(x, y, width, height)
    yield zone
  end

  # Performance testing helpers

  def benchmark_zone_lookup(bz, iterations = 1000)
    start_time = Time.monotonic
    iterations.times do |i|
      bz.zone_at(i % 100, i % 50)
    end
    elapsed = Time.monotonic - start_time
    elapsed
  end

  # Widget testing helpers

  def create_test_widget(x = 0, y = 0, width = 20, height = 10)
    TestWidget.new(x, y, width, height)
  end

  # Event simulation helpers

  def simulate_mouse_click(bz, x, y, button = :left)
    down_event = create_mouse_event(x, y, button, :press)
    up_event = create_mouse_event(x, y, button, :release)

    bz.process_event(down_event)
    bz.process_event(up_event)
  end

  def simulate_key_press(bz, key, mods = [] of Symbol)
    event = create_key_event(key, mods)
    bz.process_event(event)
  end
end

# Include helpers in spec context
Spec.before_each do
  extend BubbleZoneHelpers
end

# Custom matcher shortcuts
def have_zone_at(x, y)
  BubbleZoneHelpers::HaveZoneAt.new(x, y)
end

def contain_point(x, y)
  BubbleZoneHelpers::ContainPoint.new(x, y)
end

def overlap_with(zone)
  BubbleZoneHelpers::OverlapWith.new(zone)
end

# Test doubles and mocks

class TestWidget
  include InteractiveElement

  property x : Int32
  property y : Int32
  property width : Int32
  property height : Int32
  property focused : Bool = false
  property clicked : Bool = false

  def initialize(@x, @y, @width, @height)
  end

  def handle_mouse(event : MouseEvent) : Bool
    @clicked = true if event.action == :release
    true
  end

  def handle_key(event : KeyEvent) : Bool
    true
  end

  def focus
    @focused = true
  end

  def blur
    @focused = false
  end
end

# Event classes (simplified for testing)

abstract class Event
end

class MouseEvent < Event
  property x : Int32
  property y : Int32
  property button : Symbol
  property action : Symbol

  def initialize(@x, @y, @button, @action)
  end
end

class KeyEvent < Event
  property key : String
  property modifiers : Array(Symbol)

  def initialize(@key, @modifiers = [] of Symbol)
  end
end

# Base classes (to be replaced with actual implementations)

class Zone
  property x : Int32
  property y : Int32
  property width : Int32
  property height : Int32
  property id : String?

  def initialize(@x, @y, @width, @height, @id = nil)
  end

  def contains?(x, y) : Bool
    x >= @x && x < @x + @width && y >= @y && y < @y + @height
  end

  def overlaps?(other : Zone) : Bool
    !(x + width <= other.x || other.x + other.width <= x ||
      y + height <= other.y || other.y + other.height <= y)
  end

  def to_s
    "Zone(#{x},#{y} #{width}x#{height})"
  end
end

class BubbleZone
  def initialize
    @zones = [] of Zone
  end

  def register(x, y, width, height, id = nil) : Zone
    zone = Zone.new(x, y, width, height, id)
    @zones << zone
    zone
  end

  def zone_at(x, y) : Zone?
    @zones.find(&.contains?(x, y))
  end

  def process_event(event : Event) : Bool
    case event
    when MouseEvent
      handle_mouse_event(event)
    when KeyEvent
      handle_key_event(event)
    else
      false
    end
  end

  private def handle_mouse_event(event : MouseEvent) : Bool
    zone = zone_at(event.x, event.y)
    !!zone
  end

  private def handle_key_event(event : KeyEvent) : Bool
    false
  end
end

module InteractiveElement
  abstract def handle_mouse(event : MouseEvent) : Bool
  abstract def handle_key(event : KeyEvent) : Bool
  abstract def focus : Nil
  abstract def blur : Nil
end
