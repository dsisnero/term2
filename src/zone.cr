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

require "uniwidth"

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

    def in_bounds?(event : UVMouseEvent) : Bool
      in_bounds?(event.mouse.x, event.mouse.y)
    end

    def in_bounds?(x : Int32, y : Int32) : Bool
      # For zero-sized zones (width or height <= 0), nothing is in bounds
      return false if width <= 0 || height <= 0
      x >= @start_x && x <= @end_x && y >= @start_y && y <= @end_y
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

    def pos(event : UVMouseEvent) : Tuple(Int32, Int32)
      pos(event.mouse.x, event.mouse.y)
    end

    def width : Int32
      @end_x - @start_x + 1
    end

    def height : Int32
      @end_y - @start_y + 1
    end
  end

  class ZoneClickMsg < ControlMsg
    getter id : String
    getter x : Int32 # relative to zone
    getter y : Int32 # relative to zone
    getter button : ZoneMouseButton
    getter action : ZoneMouseAction

    def initialize(@id : String, @x : Int32, @y : Int32, @button : ZoneMouseButton, @action : ZoneMouseAction)
    end
  end

  class ZoneInBoundsMsg < ControlMsg
    getter zone : ZoneInfo
    getter event : UVMouseEvent

    def initialize(@zone : ZoneInfo, @event : UVMouseEvent)
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
    @@ids = Hash(String, String).new      # id -> generated marker
    @@rids = Hash(String, String).new     # generated marker -> id
    @@ids_num = Hash(String, UInt64).new  # id -> numeric marker
    @@rids_num = Hash(UInt64, String).new # numeric marker -> id
    @@marker_counter = 1000_u64
    @@prefix_counter = 0_i64
    @@enabled = true
    @@current_x = 0
    @@current_y = 0

    # Enable/disable zone tracking
    def self.enabled? : Bool
      @@enabled
    end

    def self.enabled=(value : Bool)
      @@enabled = value
      unless value
        @@zones.clear
        @@ids.clear
        @@rids.clear
        @@ids_num.clear
        @@rids_num.clear
      end
    end

    # Clear all registered zones
    def self.clear
      @@zones.clear
      @@ids.clear
      @@rids.clear
      @@ids_num.clear
      @@rids_num.clear
    end

    # Clear only zone geometry for a new frame, while preserving marker mappings.
    # This allows `scan()` to resolve markers embedded in the rendered frame.
    def self.clear_zones
      @@zones.clear
    end

    # Reset all zone state (used in tests)
    def self.reset
      clear
      @@marker_counter = 1000_u64
      @@prefix_counter = 0_i64
      @@current_x = 0
      @@current_y = 0
      @@enabled = true
    end

    # Get zone by ID
    def self.get(id : String) : ZoneInfo
      @@zones[id]? || ZoneInfo.new("", 0, 0, -1, -1)
    end

    # Get all registered zones
    def self.zones : Hash(String, ZoneInfo)
      @@zones
    end

    # Check if a zone is focused
    # DEPRECATED: Focus management removed - components should manage focus internally
    def self.focused?(id : String) : Bool
      false
    end

    # DEPRECATED: Focus management removed
    def self.focused_id : String?
      nil
    end

    # DEPRECATED: Focus management removed
    def self.focused_id=(id : String?)
      # no-op
    end

    # DEPRECATED: Focus management removed - components should manage focus internally
    def self.focus(id : String)
      # no-op
    end

    # DEPRECATED: Focus management removed
    def self.blur(id : String)
      # no-op
    end

    # Register a zone manually (for testing)
    def self.register(id : String, x : Int32, y : Int32, width : Int32, height : Int32, z_index : Int32 = 0)
      end_x = x + width - 1
      end_y = y + height - 1
      @@zones[id] = ZoneInfo.new(id, x, y, end_x, end_y, z_index)
    end

    def self.close
      clear
      @@enabled = false
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
      num = @@marker_counter
      marker = "#{IDENT_START}#{IDENT_BRACKET}#{num}#{IDENT_END}"
      @@marker_counter += 1

      # Store the mapping
      @@ids[id] = marker
      @@rids[marker] = id
      @@ids_num[id] = num
      @@rids_num[num] = id

      marker + content + marker
    end

    # Scan output and extract zones
    def self.scan(output : String) : String
      enabled = @@enabled

      open_zones = Hash(String, Tuple(Int32, Int32)).new # id -> (start_x, start_y)
      completed_zones = [] of Tuple(String, Int32, Int32, Int32, Int32)
      result = String.build do |str|
        x = 0
        y = 0
        bytes = output.to_slice
        i = 0 # byte index

        while i < bytes.size
          # Check for marker start
          if bytes[i] == IDENT_START.ord.to_u8 && i + 1 < bytes.size && bytes[i + 1] == IDENT_BRACKET.ord.to_u8
            j = i + 2
            num = 0_u64
            has_digits = false
            while j < bytes.size
              b = bytes[j]
              break unless b >= '0'.ord.to_u8 && b <= '9'.ord.to_u8
              has_digits = true
              num = (num * 10_u64) + (b - '0'.ord.to_u8)
              j += 1
            end

            if has_digits && j < bytes.size && bytes[j] == IDENT_END.ord.to_u8
              if id = @@rids_num[num]?
                if open_zones.has_key?(id)
                  start_x, start_y = open_zones[id]
                  completed_zones << {id, start_x, start_y, x - 1, y}
                  open_zones.delete(id)
                else
                  open_zones[id] = {x, y}
                end

                i = j + 1
                next
              elsif !enabled
                i = j + 1
                next
              end
            end
          end

          # Handle regular bytes/characters
          b0 = bytes[i]
          case b0
          when '\n'.ord.to_u8
            x = 0
            y += 1
            str.write_byte(b0)
            i += 1
            next
          when '\r'.ord.to_u8
            x = 0
            str.write_byte(b0)
            i += 1
            next
          when IDENT_START.ord.to_u8
            # Preserve ANSI escape sequences but treat them as zero-width.
            if i + 1 < bytes.size && bytes[i + 1] == '['.ord.to_u8
              k = i + 2
              while k < bytes.size
                final = bytes[k]
                k += 1
                break if final >= 0x40_u8 && final <= 0x7E_u8
              end
              str.write(bytes[i, k - i])
              i = k
              next
            end
          end

          # UTF-8 decode just enough to get width and advance bytes.
          if b0 < 0x80_u8
            x += 1
            str.write_byte(b0)
            i += 1
            next
          end

          len =
            if (b0 & 0xE0_u8) == 0xC0_u8
              2
            elsif (b0 & 0xF0_u8) == 0xE0_u8
              3
            elsif (b0 & 0xF8_u8) == 0xF0_u8
              4
            else
              1
            end
          len = 1 if i + len > bytes.size

          codepoint = 0_i32
          case len
          when 2
            codepoint = ((b0 & 0x1F_u8).to_i32 << 6) | (bytes[i + 1] & 0x3F_u8).to_i32
          when 3
            codepoint = ((b0 & 0x0F_u8).to_i32 << 12) |
                        ((bytes[i + 1] & 0x3F_u8).to_i32 << 6) |
                        (bytes[i + 2] & 0x3F_u8).to_i32
          when 4
            codepoint = ((b0 & 0x07_u8).to_i32 << 18) |
                        ((bytes[i + 1] & 0x3F_u8).to_i32 << 12) |
                        ((bytes[i + 2] & 0x3F_u8).to_i32 << 6) |
                        (bytes[i + 3] & 0x3F_u8).to_i32
          else
            codepoint = b0.to_i32
          end

          x += UnicodeCharWidth.width(codepoint.chr)
          str.write(bytes[i, len])
          i += len
        end
      end

      @@zones.clear
      if enabled
        completed_zones.each do |(id, start_x, start_y, end_x, end_y)|
          @@zones[id] = ZoneInfo.new(id, start_x, start_y, end_x, end_y, 0)
        end
      end

      result
    end

    # Scan a View and extract zones, returning a new View with markers stripped
    def self.scan(view : View) : View
      scanned_content = scan(view.content)
      View.new(
        content: scanned_content,
        cursor: view.cursor,
        background_color: view.background_color,
        foreground_color: view.foreground_color,
        window_title: view.window_title,
        progress_bar: view.progress_bar,
        alt_screen: view.alt_screen,
        report_focus: view.report_focus,
        disable_bracketed_paste_mode: view.disable_bracketed_paste_mode,
        mouse_mode: view.mouse_mode,
        keyboard_enhancements: view.keyboard_enhancements,
        on_mouse: view.on_mouse
      )
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

    # Handle mouse event (legacy method - use any_in_bounds instead)
    def self.handle_mouse(event : UVMouseEvent) : ZoneClickMsg?
      return unless @@enabled

      if zone = find_at(event.mouse.x, event.mouse.y)
        rel_x = event.mouse.x - zone.start_x
        rel_y = event.mouse.y - zone.start_y

        # Convert UV mouse event to ZoneMouseButton/ZoneMouseAction
        button = case event.mouse.button
                 when UV::MouseButton::Left   then ZoneMouseButton::Left
                 when UV::MouseButton::Right  then ZoneMouseButton::Right
                 when UV::MouseButton::Middle then ZoneMouseButton::Middle
                 else                             ZoneMouseButton::None
                 end

        action = case event
                 when UV::MouseClickEvent
                   ZoneMouseAction::Press
                 when UV::MouseReleaseEvent
                   ZoneMouseAction::Release
                 else
                   ZoneMouseAction::Motion
                 end

        ZoneClickMsg.new(zone.id, rel_x, rel_y, button, action)
      end
    end

    # DEPRECATED: Focus management removed - tab navigation disabled
    def self.focus_next : String?
      nil
    end

    # DEPRECATED: Focus management removed - tab navigation disabled
    def self.focus_prev : String?
      nil
    end

    # Clear a specific zone
    def self.clear(id : String)
      @@zones.delete(id)
      if marker = @@ids.delete(id)
        @@rids.delete(marker)
      end
      if num = @@ids_num.delete(id)
        @@rids_num.delete(num)
      end
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
      return false unless @@enabled
      @@zones.values.any? do |zone|
        zone.in_bounds?(x, y)
      end
    end

    # Call `update` with `ZoneInBoundsMsg` for any zones under the mouse.
    #
    # Note: we intentionally accept any concrete model type here rather than
    # `Model` directly. Calling abstract methods on a module-typed value can
    # fail to compile in some contexts; using a generic receiver keeps the
    # dispatch concrete.
    def self.any_in_bounds(model : M, event : UVMouseEvent) : Nil forall M
      return unless @@enabled
      find_all_at(event.mouse.x, event.mouse.y).each do |zone|
        model.update(ZoneInBoundsMsg.new(zone, event))
      end
    end

    def self.any_in_bounds_and_update(model : M, event : UVMouseEvent) : {M, Cmd} forall M
      return {model, nil} unless @@enabled
      current = model
      last_cmd = nil.as(Cmd)

      find_all_at(event.mouse.x, event.mouse.y).each do |zone|
        updated, last_cmd = current.update(ZoneInBoundsMsg.new(zone, event))
        current = updated.as(M)
      end

      {current, last_cmd}
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
  end
end
