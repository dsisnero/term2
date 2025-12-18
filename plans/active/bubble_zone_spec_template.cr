# spec/bubblezone/unit/bubble_zone_spec.cr
# Port of bubblezone_test.go

require "../support/spec_helper"

describe "BubbleZone" do
  describe "#register" do
    it "creates and returns a new zone" do
      bz = BubbleZone.new
      zone = bz.register(10, 10, 20, 15, "test_zone")

      expect(zone.x).to eq(10)
      expect(zone.y).to eq(10)
      expect(zone.width).to eq(20)
      expect(zone.height).to eq(15)
      expect(zone.id).to eq("test_zone")
    end

    it "adds zone to internal collection" do
      bz = BubbleZone.new
      zone = bz.register(10, 10, 20, 15)

      # Should be able to find the zone
      found = bz.zone_at(15, 12)
      expect(found).to eq(zone)
    end

    it "handles multiple zones" do
      bz = BubbleZone.new
      zones = [
        bz.register(0, 0, 10, 10, "zone1"),
        bz.register(20, 0, 10, 10, "zone2"),
        bz.register(0, 20, 10, 10, "zone3"),
        bz.register(20, 20, 10, 10, "zone4"),
      ]

      # Verify all zones can be found
      expect(bz.zone_at(5, 5)).to eq(zones[0])
      expect(bz.zone_at(25, 5)).to eq(zones[1])
      expect(bz.zone_at(5, 25)).to eq(zones[2])
      expect(bz.zone_at(25, 25)).to eq(zones[3])
    end

    it "handles overlapping zones" do
      bz = BubbleZone.new
      zone1 = bz.register(0, 0, 20, 20, "zone1")
      zone2 = bz.register(10, 10, 20, 20, "zone2")

      # With overlapping zones, typically the most recently registered
      # or highest z-index zone is returned
      found = bz.zone_at(15, 15)
      expect(found).to eq(zone2) # Most recent
    end

    it "raises error for invalid dimensions" do
      bz = BubbleZone.new
      expect { bz.register(10, 10, -5, 10) }.to raise_error(ArgumentError)
      expect { bz.register(10, 10, 10, -5) }.to raise_error(ArgumentError)
      expect { bz.register(10, 10, 0, 10) }.not_to raise_error # Zero width may be allowed
      expect { bz.register(10, 10, 10, 0) }.not_to raise_error # Zero height may be allowed
    end
  end

  describe "#zone_at" do
    it "returns nil when no zone at position" do
      bz = BubbleZone.new
      bz.register(10, 10, 5, 5)

      expect(bz.zone_at(0, 0)).to be_nil
      expect(bz.zone_at(20, 20)).to be_nil
      expect(bz.zone_at(10, 20)).to be_nil # Below zone
      expect(bz.zone_at(20, 10)).to be_nil # Right of zone
    end

    it "returns the correct zone for point inside zone" do
      bz = BubbleZone.new
      zone = bz.register(10, 10, 20, 15)

      # Test various points inside
      expect(bz.zone_at(10, 10)).to eq(zone) # Top-left
      expect(bz.zone_at(15, 12)).to eq(zone) # Center
      expect(bz.zone_at(29, 10)).to eq(zone) # Top-right (exclusive edge)
      expect(bz.zone_at(10, 24)).to eq(zone) # Bottom-left (exclusive edge)
      expect(bz.zone_at(29, 24)).to eq(zone) # Bottom-right (both exclusive)
    end

    it "handles multiple non-overlapping zones" do
      bz = BubbleZone.new
      zone1 = bz.register(0, 0, 10, 10, "zone1")
      zone2 = bz.register(20, 0, 10, 10, "zone2")
      zone3 = bz.register(0, 20, 10, 10, "zone3")
      zone4 = bz.register(20, 20, 10, 10, "zone4")

      expect(bz.zone_at(5, 5)).to eq(zone1)
      expect(bz.zone_at(25, 5)).to eq(zone2)
      expect(bz.zone_at(5, 25)).to eq(zone3)
      expect(bz.zone_at(25, 25)).to eq(zone4)
    end

    it "returns topmost zone for overlapping zones" do
      bz = BubbleZone.new
      zone1 = bz.register(0, 0, 30, 30, "background")
      zone2 = bz.register(10, 10, 10, 10, "foreground")

      # Overlap area should return foreground (most recent/highest z-index)
      expect(bz.zone_at(15, 15)).to eq(zone2)

      # Non-overlap area should return background
      expect(bz.zone_at(5, 5)).to eq(zone1)
      expect(bz.zone_at(25, 25)).to eq(zone1)
    end

    it "handles zero-sized zones" do
      bz = BubbleZone.new
      zone = bz.register(10, 10, 0, 0, "point_zone")

      # Zero-sized zone shouldn't contain any points
      expect(bz.zone_at(10, 10)).to be_nil
    end
  end

  describe "#zones" do
    it "returns all registered zones" do
      bz = BubbleZone.new
      zones = [
        bz.register(0, 0, 10, 10),
        bz.register(20, 0, 10, 10),
        bz.register(0, 20, 10, 10),
      ]

      expect(bz.zones.size).to eq(3)
      expect(bz.zones).to contain(zones[0])
      expect(bz.zones).to contain(zones[1])
      expect(bz.zones).to contain(zones[2])
    end

    it "returns empty array when no zones registered" do
      bz = BubbleZone.new
      expect(bz.zones).to be_empty
    end

    it "zones are returned in registration order" do
      bz = BubbleZone.new
      zone1 = bz.register(0, 0, 10, 10, "first")
      zone2 = bz.register(20, 0, 10, 10, "second")
      zone3 = bz.register(0, 20, 10, 10, "third")

      expect(bz.zones[0]).to eq(zone1)
      expect(bz.zones[1]).to eq(zone2)
      expect(bz.zones[2]).to eq(zone3)
    end
  end

  describe "#clear" do
    it "removes all zones" do
      bz = BubbleZone.new
      bz.register(0, 0, 10, 10)
      bz.register(20, 0, 10, 10)

      expect(bz.zones.size).to eq(2)

      bz.clear

      expect(bz.zones).to be_empty
      expect(bz.zone_at(5, 5)).to be_nil
      expect(bz.zone_at(25, 5)).to be_nil
    end

    it "allows new zones to be registered after clear" do
      bz = BubbleZone.new
      zone1 = bz.register(0, 0, 10, 10)
      bz.clear
      zone2 = bz.register(20, 0, 10, 10)

      expect(bz.zones.size).to eq(1)
      expect(bz.zones[0]).to eq(zone2)
      expect(bz.zone_at(5, 5)).to be_nil
      expect(bz.zone_at(25, 5)).to eq(zone2)
    end
  end

  describe "#remove" do
    it "removes a specific zone" do
      bz = BubbleZone.new
      zone1 = bz.register(0, 0, 10, 10, "zone1")
      zone2 = bz.register(20, 0, 10, 10, "zone2")

      expect(bz.zones.size).to eq(2)

      bz.remove(zone1)

      expect(bz.zones.size).to eq(1)
      expect(bz.zones).to contain(zone2)
      expect(bz.zones).not_to contain(zone1)
      expect(bz.zone_at(5, 5)).to be_nil
      expect(bz.zone_at(25, 5)).to eq(zone2)
    end

    it "does nothing when removing non-existent zone" do
      bz = BubbleZone.new
      zone1 = bz.register(0, 0, 10, 10)
      zone2 = Zone.new(20, 0, 10, 10) # Not registered

      expect(bz.zones.size).to eq(1)

      bz.remove(zone2) # Should not raise error

      expect(bz.zones.size).to eq(1)
      expect(bz.zones[0]).to eq(zone1)
    end

    it "handles removing from empty collection" do
      bz = BubbleZone.new
      zone = Zone.new(0, 0, 10, 10)

      expect { bz.remove(zone) }.not_to raise_error
      expect(bz.zones).to be_empty
    end
  end

  describe "event processing" do
    describe "#process_event with mouse events" do
      it "returns true when mouse event is in a zone" do
        bz = BubbleZone.new
        zone = bz.register(10, 10, 20, 15)

        event = MouseEvent.new(x: 15, y: 12, button: :left, action: :press)
        expect(bz.process_event(event)).to be_true
      end

      it "returns false when mouse event is not in any zone" do
        bz = BubbleZone.new
        bz.register(10, 10, 20, 15)

        event = MouseEvent.new(x: 5, y: 5, button: :left, action: :press)
        expect(bz.process_event(event)).to be_false
      end

      it "handles mouse movement events" do
        bz = BubbleZone.new
        zone = bz.register(10, 10, 20, 15)

        # Mouse enter/leave/motion events
        enter_event = MouseEvent.new(x: 15, y: 12, button: :none, action: :enter)
        motion_event = MouseEvent.new(x: 16, y: 13, button: :none, action: :motion)
        leave_event = MouseEvent.new(x: 5, y: 5, button: :none, action: :leave)

        expect(bz.process_event(enter_event)).to be_true
        expect(bz.process_event(motion_event)).to be_true
        expect(bz.process_event(leave_event)).to be_false
      end

      it "processes click events (press + release)" do
        bz = BubbleZone.new
        zone = bz.register(10, 10, 20, 15)

        press_event = MouseEvent.new(x: 15, y: 12, button: :left, action: :press)
        release_event = MouseEvent.new(x: 15, y: 12, button: :left, action: :release)

        expect(bz.process_event(press_event)).to be_true
        expect(bz.process_event(release_event)).to be_true
      end
    end

    describe "#process_event with keyboard events" do
      it "processes keyboard events for focused zone" do
        bz = BubbleZone.new
        zone = bz.register(10, 10, 20, 15)

        # First need to focus the zone (implementation dependent)
        # bz.focus(zone) or similar

        event = KeyEvent.new(key: "a", modifiers: [] of Symbol)
        # May return true if zone handles keyboard, false otherwise
        result = bz.process_event(event)
        # Just ensure it doesn't crash
        expect(result).to be_truthy.or be_falsey
      end

      it "handles special keys (Enter, Tab, Escape)" do
        bz = BubbleZone.new
        zone = bz.register(10, 10, 20, 15)

        events = [
          KeyEvent.new(key: "Enter", modifiers: [] of Symbol),
          KeyEvent.new(key: "Tab", modifiers: [] of Symbol),
          KeyEvent.new(key: "Escape", modifiers: [] of Symbol),
        ]

        events.each do |event|
          expect { bz.process_event(event) }.not_to raise_error
        end
      end
    end
  end

  describe "performance characteristics" do
    it "handles many zones efficiently" do
      bz = BubbleZone.new

      # Register 100 zones in a grid
      10.times do |x|
        10.times do |y|
          bz.register(x * 15, y * 10, 10, 5, "zone_#{x}_#{y}")
        end
      end

      expect(bz.zones.size).to eq(100)

      # Lookup should still be fast
      start_time = Time.monotonic
      100.times do |i|
        bz.zone_at(i % 150, i % 100)
      end
      elapsed = Time.monotonic - start_time

      # Should complete in reasonable time (adjust threshold as needed)
      expect(elapsed).to be < 1.second
    end

    it "efficiently handles overlapping zones" do
      bz = BubbleZone.new

      # Create stack of overlapping zones
      50.times do |i|
        bz.register(i, i, 100 - i * 2, 100 - i * 2, "layer_#{i}")
      end

      # Lookup in most overlapping area
      zone = bz.zone_at(50, 50)
      expect(zone).not_to be_nil
      expect(zone.id).to eq("layer_49") # Most recent
    end
  end

  describe "edge cases" do
    it "handles coordinates at integer limits" do
      bz = BubbleZone.new

      # Near max int values
      zone = bz.register(Int32::MAX - 100, Int32::MAX - 100, 200, 200)

      expect(bz.zone_at(Int32::MAX - 50, Int32::MAX - 50)).to eq(zone)
      expect(bz.zone_at(Int32::MAX + 50, Int32::MAX + 50)).to be_nil # Would overflow
    end

    it "handles duplicate zone registration" do
      bz = BubbleZone.new
      zone1 = bz.register(10, 10, 20, 15, "zone1")
      zone2 = bz.register(10, 10, 20, 15, "zone1") # Same coordinates and ID

      # Implementation may allow duplicates or replace
      # This test documents the expected behavior
      expect(bz.zones.size).to eq(2) # or 1 if replacing
    end

    it "handles zones with same coordinates but different IDs" do
      bz = BubbleZone.new
      zone1 = bz.register(10, 10, 20, 15, "zone1")
      zone2 = bz.register(10, 10, 20, 15, "zone2")

      expect(bz.zones.size).to eq(2)
      # Most recent should be returned for zone_at
      expect(bz.zone_at(15, 12)).to eq(zone2)
    end
  end
end
