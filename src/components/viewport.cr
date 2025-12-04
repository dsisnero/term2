require "../term2"
require "./key"

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
      property longest_line_width : Int32 = 0
      property? initialized : Bool = false
      property? mouse_wheel_enabled : Bool = true
      property mouse_wheel_delta : Int32 = 3
      property horizontal_step : Int32 = 0

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
        @mouse_wheel_enabled = true
        @mouse_wheel_delta = 3
        @initialized = true
        set_initial_values
      end

      def set_initial_values
        @key_map = KeyMap.new
        @mouse_wheel_enabled = true
        @mouse_wheel_delta = 3
        @initialized = true
        # horizontal_step intentionally left unchanged (parity with bubbles)
      end

      def content=(content : String)
        @content = content
        @lines = content.split("\n")
        @longest_line_width = @lines.max_of? { |l| Term2::Text.width(l) } || 0
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

      def set_horizontal_step(n : Int32)
        @horizontal_step = {n, 0}.max
      end

      def set_y_offset(n : Int32)
        @y_offset = n.clamp(0, max_y_offset)
      end

      def set_x_offset(n : Int32)
        max_offset = (@longest_line_width - @width)
        max_offset = 0 if max_offset < 0
        @x_offset = n.clamp(0, max_offset)
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

      def scroll_percent : Float64
        total_scrollable = max_y_offset
        return 0.0 if total_scrollable == 0
        (@y_offset.to_f / total_scrollable).clamp(0.0, 1.0)
      end

      def max_y_offset
        [@lines.size - @height, 0].max
      end

      # Helper to render as a string
      def view : String
        visible_lines = [] of String

        unless @lines.empty?
          end_index = [@y_offset + @height, @lines.size].min
          visible_lines = @lines[@y_offset...end_index]
        end

        result = String.build do |io|
          visible_lines.each_with_index do |line, i|
            # Handle x_offset and width clipping
            clipped_line = line
            if @x_offset > 0
              if line.size > @x_offset
                clipped_line = line[@x_offset..-1]
              else
                clipped_line = ""
              end
            end

            # Clip width
            # Note: This is simple char slicing, doesn't handle wide chars yet
            if clipped_line.size > @width
              clipped_line = clipped_line[0...@width]
            end

            io << clipped_line
            io << "\n" if i < visible_lines.size - 1
          end
        end

        result
      end

      # Return visible lines (used in specs)
      def visible_lines : Array(String)
        h = @height
        w = @width

        lines = [] of String
        unless @lines.empty?
          top = {@y_offset, 0}.max
          bottom = {@y_offset + h, @lines.size}.min
          lines = @lines[top...bottom]
        end

        if (@x_offset == 0 && @longest_line_width <= w) || w == 0
          return lines
        end

        lines.map { |line| cut_line(line, @x_offset, w) }
      end

      def scroll_left(n : Int32)
        set_x_offset(@x_offset - n)
      end

      def scroll_right(n : Int32)
        set_x_offset(@x_offset + n)
      end

      def set_content(s : String)
        # Normalize \r\n to \n
        self.content = s.gsub("\r\n", "\n")
      end

      private def cut_line(line : String, offset : Int32, width : Int32) : String
        return "" if width <= 0
        chars = [] of Char
        accum = 0
        target_start = offset
        target_end = offset + width

        # Skip until offset
        line.each_char do |c|
          char_width = Term2::Text.char_width(c)
          break if accum >= target_end
          if accum + char_width <= target_start
            accum += char_width
            next
          end
          # in range
          if accum < target_end
            chars << c
          end
          accum += char_width
        end
        String.build do |io|
          chars.each { |c| io << c }
        end
      end
    end
  end
end
