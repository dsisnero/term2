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
      property content : String = ""
      property lines : Array(String) = [] of String

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
      end

      def content=(content : String)
        @content = content
        @lines = content.split("\n")
        # Reset offset if content changes? Maybe not always.
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
    end
  end
end
