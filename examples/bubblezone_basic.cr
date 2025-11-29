require "../src/bubblezone"

# Basic BubbleZone example demonstrating core functionality
module BubbleZoneBasicExample
  def self.run
    puts "=== BubbleZone Basic Example ===\n"

    # Create a ZoneManager
    manager = BubbleZone::ZoneManager.new

    # Add simple rectangular zones
    manager.add(BubbleZone::ZoneInfo.new("header", 1, 0, 0, 20, 2))
    manager.add(BubbleZone::ZoneInfo.new("sidebar", 1, 0, 3, 5, 15))
    manager.add(BubbleZone::ZoneInfo.new("main", 1, 6, 3, 20, 15))
    manager.add(BubbleZone::ZoneInfo.new("footer", 1, 0, 16, 20, 18))

    puts "Zones created:"
    manager.zones.each_value do |zone|
      puts "  #{zone.id}: (#{zone.start_x},#{zone.start_y}) to (#{zone.end_x},#{zone.end_y})"
    end
    puts

    # Test coordinate detection
    test_points = [
      {10, 1},  # header
      {2, 5},   # sidebar
      {15, 10}, # main
      {10, 17}, # footer
      {25, 25}, # outside
    ]

    puts "Coordinate detection:"
    test_points.each do |x, y|
      zone = manager.find_at(x, y)
      if zone
        puts "  (#{x}, #{y}) -> #{zone.id}"
      else
        puts "  (#{x}, #{y}) -> No zone"
      end
    end
    puts

    # Test zone removal
    puts "Removing 'sidebar' zone..."
    manager.remove("sidebar")
    puts "Zones after removal:"
    manager.zones.each_value do |zone|
      puts "  #{zone.id}"
    end
  end
end

BubbleZoneBasicExample.run
