require "../src/bubblezone"

# Example demonstrating bubble detection in grids
module BubbleZoneBubbleDetectionExample
  def self.run
    puts "=== BubbleZone Bubble Detection Example ===\n"

    # Example 1: Simple grid with two bubbles
    puts "Example 1: Simple grid with two bubbles"
    grid1 = [
      [0, 0, 0, 0, 0, 0],
      [0, 1, 1, 1, 0, 0],
      [0, 1, 1, 1, 0, 0],
      [0, 1, 1, 1, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 2, 2],
      [0, 0, 0, 0, 2, 2],
    ]

    detector = BubbleZone::BubbleDetector.new
    bubbles1 = detector.detect(grid1)

    puts "Detected #{bubbles1.size} bubbles:"
    bubbles1.each do |bubble|
      puts "  Bubble #{bubble.id}: (#{bubble.start_x},#{bubble.start_y})-(#{bubble.end_x},#{bubble.end_y})"
    end
    puts

    # Example 2: Complex grid with multiple bubbles
    puts "Example 2: Complex grid with multiple bubbles"
    grid2 = [
      [1, 1, 0, 0, 2, 2, 0],
      [1, 1, 0, 0, 2, 2, 0],
      [0, 0, 0, 0, 0, 0, 0],
      [3, 3, 3, 0, 4, 4, 4],
      [3, 3, 3, 0, 4, 4, 4],
      [0, 0, 0, 0, 0, 0, 0],
      [5, 5, 0, 6, 6, 0, 7],
      [5, 5, 0, 6, 6, 0, 7],
    ]

    bubbles2 = detector.detect(grid2)

    puts "Detected #{bubbles2.size} bubbles:"
    bubbles2.each do |bubble|
      puts "  Bubble #{bubble.id}: (#{bubble.start_x},#{bubble.start_y})-(#{bubble.end_x},#{bubble.end_y})"
    end
    puts

    # Example 3: Render the detected bubbles
    puts "Example 3: Rendering detected bubbles"
    renderer = BubbleZone::ZoneRenderer.new

    puts "Grid 1 rendering:"
    rendered1 = renderer.render(bubbles1, 7, 6)
    puts rendered1
    puts

    puts "Grid 2 rendering:"
    rendered2 = renderer.render(bubbles2, 8, 7)
    puts rendered2
  end
end

BubbleZoneBubbleDetectionExample.run
