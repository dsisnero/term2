require "../term2"
require "./key"
require "uniwidth"

module Term2
  module Components
    class Viewport
      include Model

      property width : Int32
      property height : Int32
      property x_offset : Int32 = 0
      property y_offset : Int32 = 0
      property y_position : Int32 = 0
      property content : String = ""
      property lines : Array(String) = [] of String

      # Additional properties from Go implementation
      property mouse_wheel_enabled : Bool = true
      property mouse_wheel_delta : Int32 = 3
      property initialized : Bool = false
      property longest_line_width : Int32 = 0

      # Horizontal step with clamping
      def horizontal_step : Int32
        @horizontal_step
      end

      def horizontal_step=(value : Int32)
        @horizontal_step = value.clamp(0, Int32::MAX)
      end

      # Initialize horizontal_step
      @horizontal_step : Int32 = 0

      # Query methods
      def mouse_wheel_enabled? : Bool
        @mouse_wheel_enabled
      end

      def initialized? : Bool
        @initialized
      end

      # Key bindings
      property key_map : KeyMap

      struct KeyMap
        getter up : Key::Binding
        getter down : Key::Binding
        getter page_up : Key::Binding
        getter page_down : Key::Binding
        getter half_page_up : Key::Binding
        getter half_page_down : Key::Binding

        def initialize
          @up = Key::Binding.new(["k", "up"], "k/↑", "up")
          @down = Key::Binding.new(["j", "down"], "j/↓", "down")
          @page_up = Key::Binding.new(["pgup"], "pgup", "page up")
          @page_down = Key::Binding.new(["pgdown", " "], "pgdn", "page down")
          @half_page_up = Key::Binding.new(["ctrl+u"], "ctrl+u", "½ page up")
          @half_page_down = Key::Binding.new(["ctrl+d"], "ctrl+d", "½ page down")
        end
      end

      def initialize(@width : Int32, @height : Int32)
        @key_map = KeyMap.new
        set_initial_values
      end

      def set_initial_values
        @mouse_wheel_enabled = true
        @mouse_wheel_delta = 3
        # Set default horizontal step only if not already set
        @horizontal_step = 2 if @horizontal_step == 0
        @initialized = true
      end

      def content=(content : String)
        @content = content.gsub("\r\n", "\n") # normalize line endings
        @lines = @content.split("\n")
        @longest_line_width = find_longest_line_width(@lines)

        # Reset offset if content changes beyond bounds
        if @y_offset > @lines.size - 1
          goto_bottom
        end
      end

      def update(msg : Message) : {Viewport, Cmd}
        case msg
        when KeyMsg
          case
          when @key_map.up.matches?(msg)
            line_up
          when @key_map.down.matches?(msg)
            line_down
          when @key_map.page_up.matches?(msg)
            page_up
          when @key_map.page_down.matches?(msg)
            page_down
          when @key_map.half_page_up.matches?(msg)
            half_page_up
          when @key_map.half_page_down.matches?(msg)
            half_page_down
          end
        end
        {self, Cmds.none}
      end

      def line_up
        @y_offset = (@y_offset - 1).clamp(0, max_y_offset)
      end

      def line_down
        @y_offset = (@y_offset + 1).clamp(0, max_y_offset)
      end

      def page_up
        @y_offset = (@y_offset - @height).clamp(0, max_y_offset)
      end

      def page_down
        @y_offset = (@y_offset + @height).clamp(0, max_y_offset)
      end

      def half_page_up
        @y_offset = (@y_offset - @height // 2).clamp(0, max_y_offset)
      end

      def half_page_down
        @y_offset = (@y_offset + @height // 2).clamp(0, max_y_offset)
      end

      def goto_top
        @y_offset = 0
      end

      def goto_bottom
        @y_offset = max_y_offset
      end

      def max_y_offset
        [@lines.size - @height, 0].max
      end

      def scroll_percent : Float64
        max = max_y_offset
        return 1.0 if max <= 0
        (@y_offset.to_f / max.to_f).clamp(0.0, 1.0)
      end

      def find_longest_line_width(lines : Array(String)) : Int32
        w = 0
        lines.each do |line|
          line_width = Term2::Text.width(line)
          w = line_width if line_width > w
        end
        w
      end

      def set_x_offset(n : Int32)
        max_x_offset = [@longest_line_width - @width, 0].max
        @x_offset = n.clamp(0, max_x_offset)
      end

      def scroll_left(n : Int32 = @horizontal_step)
        set_x_offset(@x_offset - n)
      end

      def scroll_right(n : Int32 = @horizontal_step)
        set_x_offset(@x_offset + n)
      end

      def visible_lines : Array(String)
        h = @height
        w = @width

        if @lines.empty?
          return [] of String
        end

        top = [@y_offset, 0].max
        bottom = [@y_offset + h, top].max.clamp(top, @lines.size)
        lines = @lines[top...bottom]

        return lines if w == 0

        # Fast path: no horizontal scrolling and no need to cut.
        if @x_offset == 0 && @longest_line_width <= w
          return lines
        end

        lines.map { |line| cut_string_by_width(line, @x_offset, w) }
      end

      # Cut a string based on display width (handles double-width characters)
      private def cut_string_by_width(str : String, x_offset : Int32, width : Int32) : String
        return "" if str.empty? || width <= 0

        visible_width = 0
        captured_width = 0
        result = String::Builder.new
        in_escape = false
        esc_buf = String::Builder.new

        str.each_char do |c|
          if in_escape
            esc_buf << c
            # CSI sequences end with a letter (SGR ends with 'm', but we keep it generic).
            if c.ascii_letter?
              result << esc_buf.to_s
              esc_buf = String::Builder.new
              in_escape = false
            end
            next
          end

          if c == '\e'
            in_escape = true
            esc_buf << c
            next
          end

          cw = Term2::Text.char_width(c)

          if visible_width + cw <= x_offset
            visible_width += cw
            next
          end

          break if captured_width + cw > width

          result << c
          visible_width += cw
          captured_width += cw
        end

        result.to_s
      end

      # Helper to render as a string
      def view : String
        lines = visible_lines

        # Pad to full height (Bubble Tea viewport parity).
        if lines.size < @height
          (@height - lines.size).times { lines << "" }
        end

        # Pad each line to the viewport width. Bubble Tea pads even when
        # width is 0 by using the content's longest line width.
        target_width = @width > 0 ? @width : @longest_line_width
        if target_width > 0
          lines = lines.map do |line|
            pad = target_width - Term2::Text.width(line)
            pad > 0 ? (line + (" " * pad)) : line
          end
        end

        result = String.build do |io|
          lines.each_with_index do |line, i|
            io << line
            io << "\n" if i < lines.size - 1
          end
        end

        result
      end
    end
  end
end
