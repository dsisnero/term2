require "../term2"
require "../zone"
require "./viewport"
require "./cursor"
require "./key"

module Term2
  module Components
    class TextArea
      include Model

      property id : String = ""
      property value : String = ""
      property cursor_line : Int32 = 0
      property cursor_col : Int32 = 0
      property width : Int32 = 40
      property height : Int32 = 20
      property? show_line_numbers : Bool = true
      property prompt : String = "┃ "

      property viewport : Viewport
      property cursor : Cursor

      def initialize(@id : String = "")
        @viewport = Viewport.new(40, 20)
        @cursor = Cursor.new
        @cursor.mode = Cursor::Mode::Static
      end

      def focus : Cmd
        Zone.focus(@id) unless @id.empty?
        @cursor.focus_cmd
      end

      def blur
        Zone.blur(@id) unless @id.empty?
        @cursor.blur
      end

      def focused?
        return @cursor.focus? if @id.empty?
        Zone.focused?(@id)
      end

      def value=(val : String)
        @value = val
        update_viewport
      end

      def update(msg : Msg) : {TextArea, Cmd}
        new_cursor, cmd = @cursor.update(msg)
        @cursor = new_cursor

        case msg
        when ZoneClickMsg
          if !@id.empty? && msg.id == @id
            # Handle click - position cursor at click location if possible
            return {self, focus}
          end
        when KeyMsg
          if focused?
            handle_key(msg)
            update_viewport
            scroll_to_cursor
          end
        end

        {self, cmd}
      end

      def handle_key(msg : KeyMsg)
        lines = @value.split("\n", remove_empty: false)
        lines << "" if lines.empty?

        case msg.key.to_s
        when "up"
          @cursor_line = (@cursor_line - 1).clamp(0, lines.size - 1)
          @cursor_col = @cursor_col.clamp(0, lines[@cursor_line].size)
        when "down"
          @cursor_line = (@cursor_line + 1).clamp(0, lines.size - 1)
          @cursor_col = @cursor_col.clamp(0, lines[@cursor_line].size)
        when "left"
          if @cursor_col > 0
            @cursor_col -= 1
          elsif @cursor_line > 0
            @cursor_line -= 1
            @cursor_col = lines[@cursor_line].size
          end
        when "right"
          if @cursor_col < lines[@cursor_line].size
            @cursor_col += 1
          elsif @cursor_line < lines.size - 1
            @cursor_line += 1
            @cursor_col = 0
          end
        when "enter"
          insert_newline(lines)
        when "backspace"
          delete_char(lines)
        else
          if msg.key.type == KeyType::Runes && !msg.key.alt?
            insert_char(lines, msg.key.to_s)
          end
        end

        @value = lines.join("\n")
      end

      def insert_newline(lines : Array(String))
        current_line = lines[@cursor_line]
        left = current_line[0...@cursor_col]
        right = current_line[@cursor_col..-1]

        lines[@cursor_line] = left
        lines.insert(@cursor_line + 1, right)

        @cursor_line += 1
        @cursor_col = 0
      end

      def delete_char(lines : Array(String))
        if @cursor_col > 0
          line = lines[@cursor_line]
          left = line[0...(@cursor_col - 1)]
          right = line[@cursor_col..-1]
          lines[@cursor_line] = left + right
          @cursor_col -= 1
        elsif @cursor_line > 0
          # Merge with previous line
          current = lines.delete_at(@cursor_line)
          prev_len = lines[@cursor_line - 1].size
          lines[@cursor_line - 1] += current
          @cursor_line -= 1
          @cursor_col = prev_len
        end
      end

      def insert_char(lines : Array(String), char : String)
        line = lines[@cursor_line]
        left = line[0...@cursor_col]
        right = line[@cursor_col..-1]
        lines[@cursor_line] = left + char + right
        @cursor_col += char.size
      end

      def update_viewport
        lines = @value.split("\n", remove_empty: false)
        lines << "" if lines.empty?

        # Render cursor into lines
        # We need to handle the cursor character

        rendered_lines = lines.map_with_index do |line, i|
          prefix = ""
          if @show_line_numbers
            prefix = sprintf("%3d ", i + 1)
          end

          content = line
          if i == @cursor_line && focused?
            # Insert cursor
            char_at_cursor = " "
            if @cursor_col < line.size
              char_at_cursor = line[@cursor_col].to_s
            end

            @cursor.char = char_at_cursor
            cursor_str = @cursor.view

            left = line[0...@cursor_col]
            right = ""
            if @cursor_col < line.size
              right = line[(@cursor_col + 1)..-1]
            end

            content = left + cursor_str + right

            # If cursor is at end of line, append it
            if @cursor_col == line.size
              content = left + cursor_str
            end
          end

          prefix + @prompt + content
        end

        @viewport.content = rendered_lines.join("\n")
      end

      def scroll_to_cursor
        # Ensure cursor_line is visible in viewport
        # Viewport handles scrolling via y_offset

        if @cursor_line < @viewport.y_offset
          @viewport.y_offset = @cursor_line
        elsif @cursor_line >= @viewport.y_offset + @viewport.height
          @viewport.y_offset = @cursor_line - @viewport.height + 1
        end
      end

      def view : String
        content = @viewport.view
        return content if @id.empty?
        Zone.mark(@id, content)
      end
    end
  end
end
