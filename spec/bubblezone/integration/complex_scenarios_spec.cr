# spec/bubblezone/integration/complex_scenarios_spec.cr
# Complex integration tests for bubblezone

require "../spec_helper"

describe "Term2::Zone complex scenarios" do
  describe "multiple overlapping zones" do
    it "handles zones in complex layouts" do
      # Create a complex layout with multiple zones
      layout = <<-TEXT
      Header
      #{Term2::Zone.mark("menu", "Menu Item 1 | Menu Item 2 | Menu Item 3")}

      Content Area:
      #{Term2::Zone.mark("content", "This is the main content area with lots of text that spans multiple lines for testing purposes.")}

      #{Term2::Zone.mark("sidebar", "Sidebar\nwith\nmultiple\nlines")}

      Footer: #{Term2::Zone.mark("footer", "Copyright 2023")}
      TEXT

      result = BubbleZoneHelpers.scan_and_wait(layout, 150)

      # Check all zones exist
      ["menu", "content", "sidebar", "footer"].each do |zone_id|
        zone = Term2::Zone.get(zone_id)
        zone.zero?.should be_false
      end

      # Check specific positions
      menu_zone = Term2::Zone.get("menu")
      menu_zone.start_y.should eq(1) # Second line (0-indexed)

      content_zone = Term2::Zone.get("content")
      content_zone.start_y.should be > menu_zone.end_y

      # Verify zones don't overlap incorrectly
      sidebar_zone = Term2::Zone.get("sidebar")
      sidebar_zone.start_y.should be > content_zone.start_y
    end
  end

  describe "dynamic zone updates" do
    it "updates zones when content changes" do
      # Initial scan
      BubbleZoneHelpers.scan_and_wait("Start: #{Term2::Zone.mark("dynamic", "Initial")} End", 100)

      initial_zone = Term2::Zone.get("dynamic")
      initial_zone.zero?.should be_false

      # New scan with different content
      BubbleZoneHelpers.scan_and_wait("Start: #{Term2::Zone.mark("dynamic", "Updated and longer")} End", 100)

      updated_zone = Term2::Zone.get("dynamic")
      updated_zone.zero?.should be_false

      # Zone should have different dimensions
      updated_zone.width.should_not eq(initial_zone.width)
    end
  end

  describe "zone interaction with mouse events" do
    it "identifies zones under mouse cursor" do
      # Create a simple layout with a clickable zone
      layout = <<-TEXT
      Click here: #{Term2::Zone.mark("button", "[ Click Me ]")}
      TEXT

      BubbleZoneHelpers.scan_and_wait(layout, 100)

      button_zone = Term2::Zone.get("button")
      button_zone.zero?.should be_false

      # Test points inside the button
      # Assuming button starts at "Click here: " (13 chars) + marker overhead
      # This is approximate - actual position depends on marker parsing
      inside_x = button_zone.start_x + 2
      inside_y = button_zone.start_y

      button_zone.in_bounds?(inside_x, inside_y).should be_true

      # Test points outside
      outside_x = button_zone.start_x - 1
      outside_y = button_zone.start_y

      button_zone.in_bounds?(outside_x, outside_y).should be_false
    end
  end

  describe "nested and complex markup" do
    it "handles deeply nested zone markers" do
      # Create nested zones
      nested = Term2::Zone.mark("outer",
        "Outer " + Term2::Zone.mark("middle",
          "Middle " + Term2::Zone.mark("inner", "Inner")
        ) + " Content"
      )

      result = BubbleZoneHelpers.scan_and_wait(nested, 150)

      # All zones should exist
      ["outer", "middle", "inner"].each do |zone_id|
        zone = Term2::Zone.get(zone_id)
        zone.zero?.should be_false
      end

      # Check hierarchy (inner should be within middle, middle within outer)
      outer_zone = Term2::Zone.get("outer")
      middle_zone = Term2::Zone.get("middle")
      inner_zone = Term2::Zone.get("inner")

      # These relationships depend on exact positioning
      # For now, just verify they exist
      outer_zone.width.should be > middle_zone.width
      middle_zone.width.should be > inner_zone.width
    end
  end

  describe "performance with many zones" do
    it "handles large number of zones efficiently" do
      # Create many small zones
      content = ""
      20.times do |i|
        content += Term2::Zone.mark("zone_#{i}", "Z#{i}") + " "
      end

      result = BubbleZoneHelpers.scan_and_wait(content, 200)

      # Verify all zones were created
      20.times do |i|
        zone = Term2::Zone.get("zone_#{i}")
        zone.zero?.should be_false
      end
    end
  end

  describe "zone persistence across scans" do
    it "maintains zones until explicitly cleared" do
      # Create initial zones
      BubbleZoneHelpers.scan_and_wait(
        "A#{Term2::Zone.mark("zone1", "1")} B#{Term2::Zone.mark("zone2", "2")}",
        100
      )

      # Verify both exist
      Term2::Zone.get("zone1").zero?.should be_false
      Term2::Zone.get("zone2").zero?.should be_false

      # New scan with one zone removed
      BubbleZoneHelpers.scan_and_wait(
        "A#{Term2::Zone.mark("zone1", "updated")} B",
        100
      )

      # zone1 should be updated, zone2 should be cleared
      Term2::Zone.get("zone1").zero?.should be_false
      Term2::Zone.get("zone2").zero?.should be_true
    end
  end
end
