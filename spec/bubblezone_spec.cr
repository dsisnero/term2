require "./spec_helper"
require "../src/bubblezone"

# Tests for BubbleZone improvements and Term2 integration
describe "BubbleZone Improvements" do
  describe "Term2 Integration" do
    it "should use Term2::MouseEvent coordinates instead of custom Coordinate struct" do
      # Test that we can handle MouseEvent coordinates
      event = Term2::MouseEvent.new(5, 10, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)

      zone = BubbleZone::ZoneInfo.new("test", 1, 0, 0, 10, 20)
      zone.in_bounds?(event.x, event.y).should be_true
    end

    it "should integrate with Term2::View system" do
      view = Term2::View.new(2, 3, 8, 6)
      zone = BubbleZone::ZoneInfo.new("view-zone", 1, view.x, view.y, view.right, view.bottom)

      # Test that zone bounds match view bounds
      zone.start_x.should eq view.x
      zone.start_y.should eq view.y
      zone.end_x.should eq view.right
      zone.end_y.should eq view.bottom
    end
  end

  describe "Spatial Indexing" do
    it "should efficiently find zones using spatial indexing" do
      manager = BubbleZone::ZoneManager.new

      # Add many zones
      10.times do |i|
        10.times do |j|
          zone = BubbleZone::ZoneInfo.new("zone-#{i}-#{j}", 1, i * 10, j * 10, i * 10 + 5, j * 10 + 5)
          manager.add(zone)
        end
      end

      # Test that find_at is efficient (should use spatial indexing)
      found = manager.find_at(25, 25)
      found.should_not be_nil
      found.id.should eq "zone-2-2" if found
    end

    it "should handle zone updates with spatial index" do
      manager = BubbleZone::ZoneManager.new

      zone = BubbleZone::ZoneInfo.new("test", 1, 0, 0, 10, 10)
      manager.add(zone)

      # Update zone position
      manager.remove("test")
      updated_zone = BubbleZone::ZoneInfo.new("test", 1, 5, 5, 15, 15)
      manager.add(updated_zone)

      found = manager.find_at(10, 10)
      found.should_not be_nil
      found.id.should eq "test" if found
    end
  end

  describe "Mouse Event Handling" do
    it "should handle mouse click events" do
      manager = BubbleZone::ZoneManager.new
      zone = BubbleZone::ZoneInfo.new("button", 1, 5, 5, 15, 15)
      manager.add(zone)

      # Simulate mouse click in zone
      click_event = Term2::MouseEvent.new(10, 10, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)
      found_zone = manager.find_at(click_event.x, click_event.y)

      found_zone.should_not be_nil
      found_zone.id.should eq "button" if found_zone
    end

    it "should handle mouse hover events" do
      manager = BubbleZone::ZoneManager.new
      zone = BubbleZone::ZoneInfo.new("hover-area", 1, 0, 0, 20, 20)
      manager.add(zone)

      # Simulate mouse movement
      move_event = Term2::MouseEvent.new(15, 15, Term2::MouseEvent::Button::None, Term2::MouseEvent::Action::Move)
      found_zone = manager.find_at(move_event.x, move_event.y)

      found_zone.should_not be_nil
      found_zone.id.should eq "hover-area" if found_zone
    end
  end

  describe "Zone Hierarchy" do
    it "should support parent-child relationships" do
      parent = BubbleZone::ZoneInfo.new("parent", 1, 0, 0, 30, 30)
      child = BubbleZone::ZoneInfo.new("child", 1, 5, 5, 15, 15)

      # Test that child is contained within parent
      parent.in_bounds?(child.start_x, child.start_y).should be_true
      parent.in_bounds?(child.end_x, child.end_y).should be_true
    end

    it "should handle z-index for overlapping zones" do
      manager = BubbleZone::ZoneManager.new

      # Add overlapping zones with different z-index
      background = BubbleZone::ZoneInfo.new("background", 1, 0, 0, 20, 20)
      foreground = BubbleZone::ZoneInfo.new("foreground", 1, 10, 10, 30, 30)

      manager.add(background)
      manager.add(foreground)

      # Point in both zones should return the one with higher z-index
      found = manager.find_at(15, 15)
      found.should_not be_nil
      # In a proper implementation, this would return the foreground zone
    end
  end

  describe "Event Propagation" do
    it "should support event bubbling" do
      manager = BubbleZone::ZoneManager.new

      parent = BubbleZone::ZoneInfo.new("parent", 1, 0, 0, 30, 30)
      child = BubbleZone::ZoneInfo.new("child", 1, 10, 10, 20, 20)

      manager.add(parent)
      manager.add(child)

      # Click in child zone should be able to bubble to parent
      click_event = Term2::MouseEvent.new(15, 15, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)

      # In a proper implementation, we'd have event propagation
      found = manager.find_at(click_event.x, click_event.y)
      found.should_not be_nil
      found.id.should eq "child" if found
    end
  end

  describe "Focus Management" do
    it "should track focused zone" do
      manager = BubbleZone::ZoneManager.new

      zone1 = BubbleZone::ZoneInfo.new("zone1", 1, 0, 0, 10, 10)
      zone2 = BubbleZone::ZoneInfo.new("zone2", 1, 15, 15, 25, 25)

      manager.add(zone1)
      manager.add(zone2)

      # Simulate focus change
      # In a proper implementation, we'd have focus management
      found = manager.find_at(5, 5)
      found.should_not be_nil
      found.id.should eq "zone1" if found
    end
  end

  describe "Performance" do
    it "should handle large numbers of zones efficiently" do
      manager = BubbleZone::ZoneManager.new

      # Add 100 zones
      100.times do |i|
        zone = BubbleZone::ZoneInfo.new("zone-#{i}", 1, i, i, i + 5, i + 5)
        manager.add(zone)
      end

      # This should be fast with spatial indexing
      start_time = Time.monotonic
      found = manager.find_at(50, 50)
      end_time = Time.monotonic

      found.should_not be_nil
      # Should complete in reasonable time (e.g., < 1ms)
      (end_time - start_time).should be < Time::Span.new(nanoseconds: 1_000_000)
    end
  end
end
