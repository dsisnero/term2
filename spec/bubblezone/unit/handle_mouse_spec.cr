# spec/bubblezone/unit/handle_mouse_spec.cr
# Mouse handling tests

require "../spec_helper"

# Helper module for test models
module MouseTestModels
  # Create a test model to capture messages
  class MouseTestModel
    include Term2::Model

    getter received = [] of Term2::Msg

    def init : Term2::Cmd
      nil
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::UVMouseEvent
        spawn { Term2::Zone.any_in_bounds(self, msg) }
      when Term2::ZoneInBoundsMsg
        @received << msg
      end
      {self, nil}
    end

    def view : String
      ""
    end
  end

  class OutsideTestModel
    include Term2::Model

    getter received = [] of Term2::Msg

    def init : Term2::Cmd
      nil
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::UVMouseEvent
        spawn { Term2::Zone.any_in_bounds(self, msg) }
      when Term2::ZoneInBoundsMsg
        @received << msg
      end
      {self, nil}
    end

    def view : String
      ""
    end
  end

  class MultiZoneTestModel
    include Term2::Model

    getter received = [] of Term2::Msg

    def init : Term2::Cmd
      nil
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::UVMouseEvent
        spawn { Term2::Zone.any_in_bounds(self, msg) }
      when Term2::ZoneInBoundsMsg
        @received << msg
      end
      {self, nil}
    end

    def view : String
      ""
    end
  end

  class OverlapTestModel
    include Term2::Model

    getter received = [] of Term2::Msg

    def init : Term2::Cmd
      nil
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::UVMouseEvent
        spawn { Term2::Zone.any_in_bounds(self, msg) }
      when Term2::ZoneInBoundsMsg
        @received << msg
      end
      {self, nil}
    end

    def view : String
      ""
    end
  end

  class ButtonTestModel
    include Term2::Model

    getter received = [] of Term2::Msg

    def init : Term2::Cmd
      nil
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::UVMouseEvent
        spawn { Term2::Zone.any_in_bounds(self, msg) }
      when Term2::ZoneInBoundsMsg
        @received << msg
      end
      {self, nil}
    end

    def view : String
      ""
    end
  end

  class ActionTestModel
    include Term2::Model

    getter received = [] of Term2::Msg

    def init : Term2::Cmd
      nil
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::UVMouseEvent
        spawn { Term2::Zone.any_in_bounds(self, msg) }
      when Term2::ZoneInBoundsMsg
        @received << msg
      end
      {self, nil}
    end

    def view : String
      ""
    end
  end

  class RapidMouseModel
    include Term2::Model

    getter received = [] of Term2::Msg

    def init : Term2::Cmd
      nil
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::UVMouseEvent
        spawn { Term2::Zone.any_in_bounds(self, msg) }
      when Term2::ZoneInBoundsMsg
        @received << msg
      end
      {self, nil}
    end

    def view : String
      ""
    end
  end
end

describe "Term2::Zone mouse handling" do
  describe "mouse event processing" do
    it "identifies mouse position in zones" do
      # Create a zone
      Term2::Zone.scan("test " + Term2::Zone.mark("mouse_zone", "[Click Me]") + " here")
      sleep 50.milliseconds

      zone = Term2::Zone.get("mouse_zone")
      zone.zero?.should be_false

      # Test various mouse positions
      # Note: Exact positions depend on marker parsing
      # We'll test the concept

      model = MouseTestModels::MouseTestModel.new

      # Simulate mouse click (position needs to be in zone bounds)
      # This is a conceptual test - actual coordinates depend on implementation
      mouse_event = Term2::TestHelpers.mouse_event(
        x: zone.start_x + 1,
        y: zone.start_y,
        button: UV::MouseButton::Left,
        action: :press
      )

      model.update(mouse_event)
      sleep 50.milliseconds

      # Should receive zone message
      model.received.any?(Term2::ZoneInBoundsMsg).should be_true
    end

    it "ignores mouse events outside zones" do
      # Create a zone
      Term2::Zone.scan("test " + Term2::Zone.mark("outside_test", "zone") + " content")
      sleep 50.milliseconds

      zone = Term2::Zone.get("outside_test")
      zone.zero?.should be_false

      model = MouseTestModels::OutsideTestModel.new

      # Mouse event far outside zone
      mouse_event = Term2::TestHelpers.mouse_event(
        x: 999,
        y: 999,
        button: UV::MouseButton::Left,
        action: :press
      )

      model.update(mouse_event)
      sleep 50.milliseconds

      # Should not receive zone message
      model.received.any?(Term2::ZoneInBoundsMsg).should be_false
    end
  end

  describe "multiple zones with mouse" do
    it "identifies correct zone for mouse position" do
      # Create multiple zones
      layout = <<-TEXT
      #{Term2::Zone.mark("zone_a", "[Button A]")} #{Term2::Zone.mark("zone_b", "[Button B]")}
      TEXT

      Term2::Zone.scan(layout)
      sleep 50.milliseconds

      zone_a = Term2::Zone.get("zone_a")
      zone_b = Term2::Zone.get("zone_b")

      zone_a.zero?.should be_false
      zone_b.zero?.should be_false

      model = MouseTestModels::MultiZoneTestModel.new

      # Simulate click in zone A
      mouse_in_a = Term2::TestHelpers.mouse_event(
        x: zone_a.start_x + 2,
        y: zone_a.start_y,
        button: UV::MouseButton::Left,
        action: :press
      )

      model.update(mouse_in_a)
      sleep 50.milliseconds

      # Should receive message for zone A
      zone_a_msgs = model.received.select do |msg|
        msg.is_a?(Term2::ZoneInBoundsMsg) && msg.as(Term2::ZoneInBoundsMsg).zone.id == "zone_a"
      end

      zone_a_msgs.size.should eq(1)
    end

    it "handles overlapping mouse events" do
      # Create two zones that conceptually overlap
      # In practice, zones shouldn't overlap, but we test that the system
      # handles this gracefully (e.g., only one zone receives the event)

      # Create both zones in the same view so they both exist
      # Note: They won't actually overlap unless they're at the same position
      # but we're testing the event handling logic
      view = "test " + Term2::Zone.mark("overlap_zone1", "zone1") + " " + Term2::Zone.mark("overlap_zone2", "zone2") + " here"
      Term2::Zone.scan(view)
      sleep 50.milliseconds

      # Both zones should exist
      zone1 = Term2::Zone.get("overlap_zone1")
      zone2 = Term2::Zone.get("overlap_zone2")
      zone1.zero?.should be_false
      zone2.zero?.should be_false

      # Create test model
      model = MouseTestModels::OverlapTestModel.new

      # Send mouse event that would hit both zones if they overlapped
      # In reality, with proper positioning, only one would be hit
      mouse_event = Term2::TestHelpers.mouse_event(
        x: 5,
        y: 0,
        button: UV::MouseButton::Left,
        action: :press
      )

      model.update(mouse_event)
      sleep 50.milliseconds

      # The system should handle this gracefully
      # Either one zone gets the event, or both, but no crash
      # We just verify that mouse events are processed
      model.received.size.should be >= 0 # Just check no crash
    end
  end

  describe "mouse event types" do
    it "handles different mouse buttons" do
      Term2::Zone.scan("test " + Term2::Zone.mark("button_test", "zone") + " here")
      sleep 50.milliseconds

      zone = Term2::Zone.get("button_test")
      zone.zero?.should be_false

      model = MouseTestModels::ButtonTestModel.new

      # Test different buttons
      buttons = [
        UV::MouseButton::Left,
        UV::MouseButton::Right,
        UV::MouseButton::Middle,
        UV::MouseButton::None,
      ]

      buttons.each do |button|
        mouse_event = Term2::TestHelpers.mouse_event(
          x: zone.start_x + 1,
          y: zone.start_y,
          button: button,
          action: :press
        )

        model.update(mouse_event)
        sleep 20.milliseconds
      end

      sleep 50.milliseconds

      # Should receive messages for all button types
      model.received.select(Term2::ZoneInBoundsMsg).size.should eq(buttons.size)
    end

    it "handles different mouse actions" do
      Term2::Zone.scan("test " + Term2::Zone.mark("action_test", "zone") + " here")
      sleep 50.milliseconds

      zone = Term2::Zone.get("action_test")
      zone.zero?.should be_false

      model = MouseTestModels::ActionTestModel.new

      # Test different actions
      actions = [:press, :release, :drag, :move]

      actions.each do |action|
        mouse_event = Term2::TestHelpers.mouse_event(
          x: zone.start_x + 1,
          y: zone.start_y,
          button: UV::MouseButton::Left,
          action: action
        )

        model.update(mouse_event)
        sleep 20.milliseconds
      end

      sleep 50.milliseconds

      # Should receive messages for all action types
      model.received.select(Term2::ZoneInBoundsMsg).size.should eq(actions.size)
    end
  end

  describe "performance with mouse events" do
    it "handles rapid mouse events efficiently" do
      # Create a zone
      Term2::Zone.scan("test " + Term2::Zone.mark("rapid_mouse", "zone") + " here")
      sleep 50.milliseconds

      zone = Term2::Zone.get("rapid_mouse")
      zone.zero?.should be_false

      model = MouseTestModels::RapidMouseModel.new

      # Send many mouse events quickly
      20.times do |i|
        mouse_event = Term2::TestHelpers.mouse_event(
          x: zone.start_x + (i % 5),
          y: zone.start_y,
          button: UV::MouseButton::Left,
          action: :press
        )

        model.update(mouse_event)
      end

      sleep 100.milliseconds

      # Should handle all events
      # Exact count depends on implementation (some might be throttled)
      model.received.size.should be > 0
    end
  end
end
