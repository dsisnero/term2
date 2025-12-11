require "./base_types"

# Zone provides focus and mouse click management for Term2.
#
# Inspired by BubbleZone, this module allows components to register
# interactive zones and receive focus/click events automatically.
#
# Usage:
#   1. Components define a `zone_id` to participate in zone tracking
#   2. Wrap output in `Zone.mark` to register clickable areas
#   3. Use `Zone.focused?` to check focus state
#   4. Mouse clicks automatically dispatch to the right zone
#
# ```
# class Button
#   include Term2::Model
#
#   getter label : String
#   getter id : String
#
#   def zone_id : String
#     @id
#   end
#
#   def view : String
#     style = focused? ? Style.reverse : Style.new
#     Zone.mark(@id, style.apply("[#{@label}]"))
#   end
# end
# ```

module Term2
  # Zone info for tracking interactive regions
  struct ZoneInfo
    getter id : String
    getter start_x : Int32
    getter start_y : Int32
    getter end_x : Int32
    getter end_y : Int32
    getter z_index : Int32

    def initialize(@id, @start_x, @start_y, @end_x, @end_y, @z_index = 0)
    end

    # Returns true if the zone isn't known yet (is zero)
    def zero? : Bool
      @id.empty?
    end

    def in_bounds?(x : Int32, y : Int32) : Bool
      # For zero-sized zones (width or height <= 0), nothing is in bounds
      return false if zero?
      return false if width <= 0 || height <= 0
      x >= @start_x && x <= @end_x && y >= @start_y && y <= @end_y
    end

    def in_bounds?(event : MouseEvent) : Bool
      in_bounds?(event.x, event.y)
    end

    # Returns the coordinates relative to the zone, with a basis of (0, 0)
    # being the top left cell of the zone. If the zone is not known,
    # or the coordinates are not in the bounds of the zone, returns (-1, -1).
    def pos(x : Int32, y : Int32) : Tuple(Int32, Int32)
      if zero? || !in_bounds?(x, y)
        return {-1, -1}
      end
      {x - @start_x, y - @start_y}
    end

    def pos(event : MouseEvent) : Tuple(Int32, Int32)
      pos(event.x, event.y)
    end

    def width : Int32
      val = @end_x - @start_x + 1
      val < 0 ? 0 : val
    end

    def height : Int32
      val = @end_y - @start_y + 1
      val < 0 ? 0 : val
    end
  end

  class ZoneClickMsg < Message
    getter id : String
    getter x : Int32 # relative to zone
    getter y : Int32 # relative to zone
    getter button : ZoneMouseButton
    getter action : ZoneMouseAction

    def initialize(@id : String, @x : Int32, @y : Int32, @button : ZoneMouseButton, @action : ZoneMouseAction)
    end
  end

  # Message sent when a mouse event is in bounds of a zone.
  class ZoneInBoundsMsg < Message
    getter zone : ZoneInfo
    getter event : MouseEvent

    def initialize(@zone : ZoneInfo, @event : MouseEvent)
    end
  end

  enum ZoneMouseButton
    Left
    Right
    Middle
    None
  end

  enum ZoneMouseAction
    Press
    Release
    Motion
  end

  record ZoneMouseEvent,
    x : Int32,
    y : Int32,
    button : ZoneMouseButton,
    action : ZoneMouseAction

  module Zone
    # ANSI escape sequence for zone markers
    # Format: \x1B[<number>z
    IDENT_START   = '\u001B'
    IDENT_BRACKET = '['
    IDENT_END     = 'z'

    @@zones = Hash(String, ZoneInfo).new
    @@ids = Hash(String, String).new  # id -> generated marker
    @@rids = Hash(String, String).new # generated marker -> id
    @@marker_counter = 1000_u64
    @@prefix_counter = 0_u64
    @@enabled = true
    @@closed = false
    @@focused_id : String? = nil
    @@current_x = 0
    @@current_y = 0

    # Enable/disable zone tracking
    def self.enabled? : Bool
      @@enabled
    end

    def self.enabled=(value : Bool)
      @@enabled = value
      @@zones.clear unless value
    end

    # Reset all internal state (used by specs)
    def self.reset
      @@zones.clear
      @@ids.clear
      @@rids.clear
      @@marker_counter = 1000_u64
      @@prefix_counter = 0_u64
      @@enabled = true
      @@closed = false
      @@focused_id = nil
      @@current_x = 0
      @@current_y = 0
    end

    # Close the manager and stop tracking zones
    def self.close
      @@closed = true
      @@zones.clear
      @@focused_id = nil
    end

    # Clear all registered zones
    def self.clear
      @@zones.clear
      @@focused_id = nil
    end

    # Get zone by ID
    def self.get(id : String) : ZoneInfo
      @@zones[id]? || zero_zone
    end

    # Get all registered zones
    def self.zones : Hash(String, ZoneInfo)
      @@zones
    end

    # Check if a zone is focused
    def self.focused?(id : String) : Bool
      @@focused_id == id
    end

    # Get focused zone ID
    def self.focused_id : String?
      @@focused_id
    end

    # Set focused zone ID
    def self.focused_id=(id : String?)
      @@focused_id = id
    end

    # Focus a zone
    def self.focus(id : String)
      @@focused_id = id
    end

    # Blur a zone
    def self.blur(id : String)
      @@focused_id = nil if @@focused_id == id
    end

    # Register a zone manually (for testing)
    def self.register(id : String, x : Int32, y : Int32, width : Int32, height : Int32, z_index : Int32 = 0)
      end_x = x + width - 1
      end_y = y + height - 1
      @@zones[id] = ZoneInfo.new(id, x, y, end_x, end_y, z_index)
    end

    # Mark content with zone markers
    def self.mark(id : String, content : String) : String
      return content unless @@enabled
      return content if id.empty? || content.empty?

      # Check if we already have a marker for this ID
      if marker = @@ids[id]?
        return marker + content + marker
      end

      # Generate a new marker
      marker = "#{IDENT_START}#{IDENT_BRACKET}#{@@marker_counter}#{IDENT_END}"
      @@marker_counter += 1

      # Store the mapping
      @@ids[id] = marker
      @@rids[marker] = id

      marker + content + marker
    end

    # Scan output and extract zones
    # ameba:disable Metrics/CyclomaticComplexity
    def self.scan(output : String) : String
      open_zones = Hash(String, Tuple(Int32, Int32)).new                # marker -> (start_x, start_y)
      completed_zones = [] of Tuple(String, Int32, Int32, Int32, Int32) # marker, coords
      result = String.build do |str|
        x = 0
        y = 0
        i = 0

        while i < output.size
          # Check for marker start
          if output[i] == IDENT_START && i + 1 < output.size && output[i + 1] == IDENT_BRACKET
            # Parse marker
            j = i + 2
            while j < output.size && output[j].ascii_number?
              j += 1
            end

            if j < output.size && output[j] == IDENT_END
              marker = output[i..j]

              if open_zones.has_key?(marker)
                # End of zone
                start_x, start_y = open_zones[marker]
                completed_zones << {marker, start_x, start_y, x - 1, y}
                open_zones.delete(marker)
              else
                # Start of zone
                open_zones[marker] = {x, y}
              end

              # Skip marker (don't add to output)
              i = j + 1
              next
            end
          end

          # Handle regular characters
          case output[i]
          when '\n'
            x = 0
            y += 1
          when '\r'
            x = 0
          when '\e'
            # Skip ANSI escape sequences
            k = i + 1
            if k < output.size && output[k] == '['
              k += 1
              while k < output.size
                c = output[k]
                k += 1
                break if c.ascii_letter?
              end
              # Keep ANSI sequences in the result but don't advance x/y
              str << output[i...(k)]
              i = k
              next
            end
          else
            x += 1
          end

          str << output[i]
          i += 1
        end
      end

      # Register zones
      @@zones.clear

      return result if @@closed
      completed_zones.each do |(marker, start_x, start_y, end_x, end_y)|
        if id = @@rids[marker]?
          @@zones[id] = ZoneInfo.new(id, start_x, start_y, end_x, end_y, 0)
        end
      end

      result
    end

    # Find zone at coordinates
    def self.find_at(x : Int32, y : Int32) : ZoneInfo?
      # Find all zones at coordinates
      zones_at_point = @@zones.values.select do |zone|
        zone.in_bounds?(x, y)
      end

      # Return nil if no zones found
      return if zones_at_point.empty?

      # Return smallest zone by area, then highest z-index
      zones_at_point.min_by do |zone|
        area = zone.width * zone.height
        {-zone.z_index, area} # Negative z-index for descending order
      end
    end

    # Handle mouse event
    def self.handle_mouse(event : MouseEvent) : ZoneClickMsg?
      return unless @@enabled

      if zone = find_at(event.x, event.y)
        rel_x = event.x - zone.start_x
        rel_y = event.y - zone.start_y

        # Convert MouseEvent button/action to ZoneMouseButton/ZoneMouseAction
        button = case event.button
                 when MouseEvent::Button::Left   then ZoneMouseButton::Left
                 when MouseEvent::Button::Right  then ZoneMouseButton::Right
                 when MouseEvent::Button::Middle then ZoneMouseButton::Middle
                 else                                 ZoneMouseButton::None
                 end

        action = case event.action
                 when MouseEvent::Action::Press                          then ZoneMouseAction::Press
                 when MouseEvent::Action::Release                        then ZoneMouseAction::Release
                 when MouseEvent::Action::Drag, MouseEvent::Action::Move then ZoneMouseAction::Motion
                 else                                                         ZoneMouseAction::Press
                 end

        ZoneClickMsg.new(zone.id, rel_x, rel_y, button, action)
      end
    end

    # Tab to next zone
    def self.focus_next : String?
      ids = @@zones.keys.sort!
      return if ids.empty?

      current_idx = @@focused_id.try { |id| ids.index(id) }
      next_idx = current_idx ? (current_idx + 1) % ids.size : 0

      @@focused_id = ids[next_idx]
      @@focused_id
    end

    # Tab to previous zone
    def self.focus_prev : String?
      ids = @@zones.keys.sort!
      return if ids.empty?

      current_idx = @@focused_id.try { |id| ids.index(id) }
      prev_idx = current_idx ? (current_idx - 1 + ids.size) % ids.size : ids.size - 1

      @@focused_id = ids[prev_idx]
      @@focused_id
    end

    # Clear a specific zone
    def self.clear(id : String)
      @@zones.delete(id)
      @@focused_id = nil if @@focused_id == id
    end

    # Clear all zones (alias for clear method)
    def self.clear_all
      clear
    end

    # Register a zone directly (for testing)
    def self.register(id : String, start_x : Int32, start_y : Int32, end_x : Int32, end_y : Int32, z_index : Int32 = 0)
      @@zones[id] = ZoneInfo.new(id, start_x, start_y, end_x, end_y, z_index)
    end

    # Generate a new unique prefix for markers
    def self.new_prefix : String
      @@prefix_counter += 1
      "zone_#{@@prefix_counter}__"
    end

    # Get the current marker counter (for testing)
    def self.marker_counter : UInt64
      @@marker_counter
    end

    # Check if any zone is in bounds for the given coordinates
    def self.any_in_bounds?(x : Int32, y : Int32) : Bool
      @@zones.values.any? do |zone|
        zone.in_bounds?(x, y)
      end
    end

    # Find all zones at the given coordinates
    def self.find_all_at(x : Int32, y : Int32) : Array(ZoneInfo)
      @@zones.values.select do |zone|
        zone.in_bounds?(x, y)
      end
    end

    # Get the smallest zone at the given coordinates (by area, then z-index)
    def self.find_smallest_at(x : Int32, y : Int32) : ZoneInfo?
      zones = find_all_at(x, y)
      return if zones.empty?

      zones.min_by do |zone|
        area = zone.width * zone.height
        {-zone.z_index, area} # Negative z-index for descending order
      end
    end

    # Send ZoneInBoundsMsg for each zone under the mouse to the provided model
    def self.any_in_bounds(model : Model, mouse : MouseEvent)
      return if @@closed

      find_in_bounds(mouse).each do |zone|
        model.update(ZoneInBoundsMsg.new(zone, mouse))
      end
    end

    # Same as any_in_bounds, but returns updated model and batched command result
    def self.any_in_bounds_and_update(model : Model, mouse : MouseEvent) : {Model, Cmd}
      return {model, nil} if @@closed

      cmds = [] of Cmd
      find_in_bounds(mouse).each do |zone|
        model, cmd = model.update(ZoneInBoundsMsg.new(zone, mouse))
        cmds << cmd if cmd
      end

      compacted = cmds.compact
      batched = case compacted.size
                when 0 then nil
                when 1 then compacted.first
                else        Proc(Msg?).new { BatchMsg.new(compacted).as(Msg) }
                end

      {model, batched}
    end

    private def self.find_in_bounds(mouse : MouseEvent) : Array(ZoneInfo)
      ids = @@zones.keys.sort!
      ids.compact_map do |id|
        if zone = @@zones[id]?
          zone if zone.in_bounds?(mouse.x, mouse.y)
        end
      end
    end

    private def self.zero_zone : ZoneInfo
      ZoneInfo.new("", 0, 0, -1, -1, 0)
    end
  end
end