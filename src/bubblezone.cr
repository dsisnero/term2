# Copyright (c) Liam Stanley <liam@liam.sh>. All rights reserved. Use of
# this source code is governed by the MIT license that can be found in
# the LICENSE file.

require "./mouse"
require "./view"

module BubbleZone
  # Enhanced ZoneInfo with hierarchy and z-index support
  struct ZoneInfo
    property id : String
    property iteration : Int32
    property start_x : Int32
    property start_y : Int32
    property end_x : Int32
    property end_y : Int32
    property parent : String? = nil
    property children : Array(String) = [] of String
    property z_index : Int32 = 0
    property? focused : Bool = false

    def initialize(@id : String, @iteration : Int32, @start_x : Int32, @start_y : Int32, @end_x : Int32, @end_y : Int32)
    end

    # Create ZoneInfo from Term2::View
    def self.from_view(view : Term2::View, id : String, iteration : Int32 = 1) : ZoneInfo
      ZoneInfo.new(id, iteration, view.x, view.y, view.right, view.bottom)
    end

    # IsZero returns true if the zone isn't known yet (is nil).
    def zero? : Bool
      @id.empty?
    end

    # InBounds returns true if the mouse event was in the bounds of the zones
    # coordinates. If the zone is not known, it returns false. It calculates this
    # using a box between the start and end coordinates. If you're looking to check
    # for abnormal shapes (e.g. something that might wrap a line, but can't be
    # determined using a box), you'll likely have to implement this yourself.
    def in_bounds?(x : Int32, y : Int32) : Bool
      return false if zero?

      # Check if coordinates are valid (start <= end)
      return false if @start_x > @end_x || @start_y > @end_y

      # Check if coordinates are within bounds
      return false if x < @start_x || y < @start_y
      return false if x > @end_x || y > @end_y

      true
    end

    # Check if this zone contains another zone
    def contains?(other : ZoneInfo) : Bool
      in_bounds?(other.start_x, other.start_y) && in_bounds?(other.end_x, other.end_y)
    end

    # Pos returns the coordinates of the mouse event relative to the zone, with a
    # basis of (0, 0) being the top left cell of the zone. If the zone is not known,
    # or the mouse event is not in the bounds of the zone, this will return (-1, -1).
    def pos(x : Int32, y : Int32) : Tuple(Int32, Int32)
      return {-1, -1} if zero? || !in_bounds?(x, y)

      {x - @start_x, y - @start_y}
    end

    # Area of the zone
    def area : Int32
      return 0 if @start_x > @end_x || @start_y > @end_y
      (end_x - start_x + 1) * (end_y - start_y + 1)
    end

    # Width of the zone
    def width : Int32
      return 0 if @start_x > @end_x
      end_x - start_x + 1
    end

    # Height of the zone
    def height : Int32
      return 0 if @start_y > @end_y
      end_y - start_y + 1
    end
  end

  # Simple spatial index using grid partitioning
  class SpatialIndex
    @grid_size : Int32
    @grid : Hash(Tuple(Int32, Int32), Array(ZoneInfo))

    def initialize(grid_size : Int32 = 10)
      @grid_size = grid_size
      @grid = Hash(Tuple(Int32, Int32), Array(ZoneInfo)).new { |hash, key| hash[key] = [] of ZoneInfo }
    end

    def add(zone : ZoneInfo)
      grid_cells_for_zone(zone).each do |cell|
        @grid[cell] << zone
      end
    end

    def remove(zone : ZoneInfo)
      grid_cells_for_zone(zone).each do |cell|
        @grid[cell].delete(zone)
      end
    end

    def query(x : Int32, y : Int32) : Array(ZoneInfo)
      cell_x = x // @grid_size
      cell_y = y // @grid_size
      @grid[{cell_x, cell_y}]? || [] of ZoneInfo
    end

    private def grid_cells_for_zone(zone : ZoneInfo) : Array(Tuple(Int32, Int32))
      cells = [] of Tuple(Int32, Int32)

      start_cell_x = zone.start_x // @grid_size
      start_cell_y = zone.start_y // @grid_size
      end_cell_x = zone.end_x // @grid_size
      end_cell_y = zone.end_y // @grid_size

      (start_cell_x..end_cell_x).each do |cell_x|
        (start_cell_y..end_cell_y).each do |cell_y|
          cells << {cell_x, cell_y}
        end
      end

      cells
    end
  end

  # Enhanced ZoneManager with spatial indexing and event handling
  class ZoneManager
    property zones : Hash(String, ZoneInfo)
    @spatial_index : SpatialIndex
    @focused_zone : ZoneInfo?

    def initialize(grid_size : Int32 = 10)
      @zones = Hash(String, ZoneInfo).new
      @spatial_index = SpatialIndex.new(grid_size)
      @focused_zone = nil
    end

    # Add adds a zone to the manager.
    def add(zone : ZoneInfo)
      @zones[zone.id] = zone
      @spatial_index.add(zone)
    end

    # Register a Term2::View as a zone
    def register_view(view : Term2::View, id : String, iteration : Int32 = 1)
      zone = ZoneInfo.from_view(view, id, iteration)
      add(zone)
    end

    # Get returns a zone by its ID, or nil if not found.
    def get(id : String) : ZoneInfo?
      @zones[id]?
    end

    # Remove removes a zone by its ID.
    def remove(id : String)
      if zone = @zones[id]?
        @spatial_index.remove(zone)
        @zones.delete(id)

        # Clear focus if focused zone is removed
        if @focused_zone == zone
          @focused_zone = nil
        end
      end
    end

    # Clear removes all zones.
    def clear
      @zones.clear
      @spatial_index = SpatialIndex.new
      @focused_zone = nil
    end

    # FindAt returns the zone that contains the given coordinates, or nil if no
    # zone contains the coordinates. Uses spatial indexing for efficiency.
    def find_at(x : Int32, y : Int32) : ZoneInfo?
      # First check spatial index for potential zones
      candidates = @spatial_index.query(x, y)

      # Find the zone with highest z-index that contains the point
      best_zone : ZoneInfo? = nil
      candidates.each do |zone|
        if zone.in_bounds?(x, y)
          if best_zone.nil? || zone.z_index > best_zone.z_index
            best_zone = zone
          elsif zone.z_index == best_zone.z_index
            # If same z-index, prefer smaller zones (child zones)
            if zone.area < best_zone.area
              best_zone = zone
            end
          end
        end
      end

      best_zone
    end

    # Handle mouse event and return the zone at the event coordinates
    def handle_mouse_event(event : Term2::MouseEvent) : ZoneInfo?
      find_at(event.x, event.y)
    end

    # Focus management
    def focus(zone : ZoneInfo)
      # Blur current focused zone
      if current = @focused_zone
        current.focused = false
      end

      # Focus new zone
      zone.focused = true
      @focused_zone = zone
    end

    def blur
      if current = @focused_zone
        current.focused = false
        @focused_zone = nil
      end
    end

    def focused_zone : ZoneInfo?
      @focused_zone
    end

    # Event propagation
    def handle_event_with_propagation(event : Term2::MouseEvent, phase : Symbol = :bubble) : Array(ZoneInfo)
      target_zone = find_at(event.x, event.y)
      return [] of ZoneInfo unless target_zone

      zones_in_order = [] of ZoneInfo

      case phase
      when :capture
        # Capture phase: from root to target
        # For now, just return target zone
        zones_in_order << target_zone
      when :bubble
        # Bubble phase: from target to root
        zones_in_order << target_zone
        # In a full implementation, we'd traverse up the parent chain
      end

      zones_in_order
    end
  end

  # EventPhase enum for event propagation
  enum EventPhase
    Capture
    Bubble
  end

  # Global zone manager instance
  class_property manager : ZoneManager = ZoneManager.new

  # Convenience methods for global manager
  def self.add(zone : ZoneInfo)
    manager.add(zone)
  end

  def self.register_view(view : Term2::View, id : String, iteration : Int32 = 1)
    manager.register_view(view, id, iteration)
  end

  def self.find_at(x : Int32, y : Int32) : ZoneInfo?
    manager.find_at(x, y)
  end

  def self.handle_mouse_event(event : Term2::MouseEvent) : ZoneInfo?
    manager.handle_mouse_event(event)
  end

  def self.clear
    manager.clear
  end

  # Keep original classes for backward compatibility
  class BubbleDetector
    # Detect finds all contiguous regions (bubbles) in the grid.
    # A bubble is defined as a group of connected non-zero cells.
    def detect(grid : Array(Array(Int32))) : Array(ZoneInfo)
      return [] of ZoneInfo if grid.empty? || grid[0].empty?

      height = grid.size
      width = grid[0].size
      visited = Array.new(height) { Array.new(width, false) }
      bubbles = [] of ZoneInfo
      iteration = 0

      (0...height).each do |y|
        (0...width).each do |x|
          if !visited[y][x] && grid[y][x] != 0
            iteration += 1
            bubble = explore_bubble(grid, visited, x, y, iteration)
            # Only add bubbles that have area > 1 (not single isolated cells)
            area = (bubble.end_x - bubble.start_x + 1) * (bubble.end_y - bubble.start_y + 1)
            bubbles << bubble if area > 1
          end
        end
      end

      bubbles
    end

    private def explore_bubble(grid : Array(Array(Int32)), visited : Array(Array(Bool)),
                               start_x : Int32, start_y : Int32, iteration : Int32) : ZoneInfo
      height = grid.size
      width = grid[0].size

      min_x = start_x
      max_x = start_x
      min_y = start_y
      max_y = start_y

      stack = [{start_x, start_y}]
      visited[start_y][start_x] = true

      while !stack.empty?
        x, y = stack.pop

        # Update bounds
        min_x = Math.min(min_x, x)
        max_x = Math.max(max_x, x)
        min_y = Math.min(min_y, y)
        max_y = Math.max(max_y, y)

        # Check neighbors
        neighbors = [
          {x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1},
        ]

        neighbors.each do |neighbor_x, neighbor_y|
          if neighbor_x >= 0 && neighbor_x < width && neighbor_y >= 0 && neighbor_y < height &&
             !visited[neighbor_y][neighbor_x] && grid[neighbor_y][neighbor_x] != 0
            visited[neighbor_y][neighbor_x] = true
            stack.push({neighbor_x, neighbor_y})
          end
        end
      end

      ZoneInfo.new("bubble-#{iteration}", iteration, min_x, min_y, max_x, max_y)
    end
  end

  class ZoneRenderer
    # Render creates an ASCII art representation of zones within the specified bounds.
    def render(zones : Array(ZoneInfo), width : Int32, height : Int32) : String
      return "No zones to render" if zones.empty?

      # Create a grid to represent the display
      grid = Array.new(height) { Array.new(width, '.') }

      # Mark zone areas
      zones.each_with_index do |zone, idx|
        char = ('A'.ord + idx).chr

        # Only mark zones that are at least partially within bounds
        zone_start_x = Math.max(0, zone.start_x)
        zone_start_y = Math.max(0, zone.start_y)
        zone_end_x = Math.min(width - 1, zone.end_x)
        zone_end_y = Math.min(height - 1, zone.end_y)

        (zone_start_y..zone_end_y).each do |y|
          (zone_start_x..zone_end_x).each do |x|
            grid[y][x] = char if y < height && x < width
          end
        end
      end

      # Build the output
      output = String.build do |str|
        str << "Zones:\n"

        # Add legend
        zones.each_with_index do |zone, idx|
          char = ('A'.ord + idx).chr
          str << "  #{char}: #{zone.id} (#{zone.start_x},#{zone.start_y})-(#{zone.end_x},#{zone.end_y})\n"
        end

        str << "\nGrid (#{width}x#{height}):\n"

        # Add coordinate labels for x-axis
        str << "   "
        (0...width).each { |x| str << "#{x % 10}" }
        str << "\n"

        # Add grid with y-axis labels
        grid.each_with_index do |row, y|
          str << "#{y % 10} "
          row.each { |cell| str << cell }
          str << "\n"
        end
      end

      output
    end
  end
end
