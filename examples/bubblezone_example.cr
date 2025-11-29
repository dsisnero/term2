require "../src/bubblezone"

# Example demonstrating BubbleZone functionality
module BubbleZoneExample
  def self.run
    puts "=== BubbleZone Example ===\n"

    # Create a ZoneManager
    manager = BubbleZone::ZoneManager.new

    # Add some zones
    manager.add(BubbleZone::ZoneInfo.new("header", 1, 0, 0, 10, 2))
    manager.add(BubbleZone::ZoneInfo.new("sidebar", 1, 0, 3, 3, 20))
    manager.add(BubbleZone::ZoneInfo.new("content", 1, 4, 3, 15, 20))
    manager.add(BubbleZone::ZoneInfo.new("footer", 1, 0, 21, 15, 23))

    puts "Zones in manager:"
    manager.zones.each_value do |zone|
      puts "  - #{zone.id}: (#{zone.start_x},#{zone.start_y})-(#{zone.end_x},#{zone.end_y})"
    end
    puts

    # Test coordinate checking
    test_coordinates = [
      {5, 1},   # In header
      {1, 5},   # In sidebar
      {8, 10},  # In content
      {7, 22},  # In footer
      {20, 20}, # Outside all zones
    ]

    puts "Coordinate checks:"
    test_coordinates.each do |x, y|
      zone = manager.find_at(x, y)
      if zone
        puts "  (#{x},#{y}) -> #{zone.id}"
      else
        puts "  (#{x},#{y}) -> No zone"
      end
    end
    puts

    # Test bubble detection
    puts "Bubble Detection:"
    grid = [
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 1, 1, 1, 0, 0, 0, 0],
      [0, 1, 1, 1, 0, 0, 0, 0],
      [0, 1, 1, 1, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 2, 2, 0],
      [0, 0, 0, 0, 0, 2, 2, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
    ]

    detector = BubbleZone::BubbleDetector.new
    bubbles = detector.detect(grid)

    puts "Detected #{bubbles.size} bubbles:"
    bubbles.each do |bubble|
      puts "  - #{bubble.id}: (#{bubble.start_x},#{bubble.start_y})-(#{bubble.end_x},#{bubble.end_y})"
    end
    puts

    # Test zone rendering
    puts "Zone Rendering:"
    renderer = BubbleZone::ZoneRenderer.new
    rendered = renderer.render(bubbles, 8, 8)
    puts rendered

    # Test zone bounds checking
    puts "Zone Bounds Checking:"
    test_zone = BubbleZone::ZoneInfo.new("test", 1, 1, 1, 4, 4)
    test_points = [
      {2, 3}, # Inside
      {5, 7}, # Outside
      {0, 0}, # Outside
      {3, 3}, # Inside
    ]

    test_points.each do |x, y|
      in_bounds = test_zone.in_bounds?(x, y)
      puts "  Point (#{x},#{y}) in zone #{test_zone.id}: #{in_bounds}"
    end
  end
end

BubbleZoneExample.run
