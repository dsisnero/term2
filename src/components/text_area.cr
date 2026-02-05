require "../term2"
require "../zone"
require "./viewport"
require "./cursor"
require "./key"
require "uniwidth"

module Term2
  module Components
    class TextArea
      include Model

      struct KeyMap
        getter character_backward : Key::Binding
        getter character_forward : Key::Binding
        getter line_next : Key::Binding
        getter line_previous : Key::Binding
        getter delete_character_backward : Key::Binding
        getter delete_word_backward : Key::Binding
        getter insert_newline : Key::Binding

        def initialize
          @character_forward = Key::Binding.new(["right", "ctrl+f"], "right", "character forward")
          @character_backward = Key::Binding.new(["left", "ctrl+b"], "left", "character backward")
          @line_next = Key::Binding.new(["down", "ctrl+n"], "down", "next line")
          @line_previous = Key::Binding.new(["up", "ctrl+p"], "up", "previous line")
          @delete_word_backward = Key::Binding.new(["alt+backspace", "ctrl+w"], "alt+backspace", "delete word backward")
          @delete_character_backward = Key::Binding.new(["backspace", "ctrl+h"], "backspace", "delete character backward")
          @insert_newline = Key::Binding.new(["enter", "ctrl+m"], "enter", "insert newline")
        end
      end

      def self.default_key_map : KeyMap
        KeyMap.new
      end

      # Properties matching Go implementation
      property id : String = ""
      property value : String = ""
      property cursor_line : Int32 = 0
      property cursor_col : Int32 = 0

      property? show_line_numbers : Bool = true
      property prompt : String = "┃ "
      property placeholder : String = ""

      # End-of-buffer marker, rendered on otherwise blank lines.
      # Allows ANSI styling like the Go textarea's `Lipgloss::Style.EndOfBuffer`.
      property end_of_buffer_char : String = "~"

      property char_limit : Int32 = 0
      property max_height : Int32 = 99
      property max_width : Int32 = 500

      property viewport : Viewport
      property cursor : Cursor
      property key_map : KeyMap

      # Styles (Placeholder for future expansion)
      property style : Lipgloss::Style = Lipgloss::Style.new

      # Internal state
      @width : Int32 = 40
      @height : Int32 = 6
      @preferred_x : Int32 = 0
      @last_move_vertical : Bool = false

      def initialize(@id : String = "")
        @viewport = Viewport.new(40, 6)
        @cursor = Cursor.new
        @cursor.mode = Cursor::Mode::Blink
        @key_map = TextArea.default_key_map
      end

      # Getters/Setters for width/height that update viewport
      def width
        @width
      end

      def width=(w : Int32)
        @width = w
        @viewport.width = w
        # Logic to adjust based on prompt width, line numbers, etc.
        # (Simplified for now, Go version does complex calculation)
      end

      def height
        @height
      end

      def height=(h : Int32)
        @height = h
        @viewport.height = h
      end

      # Line metadata for navigation calculations
      record LineInfo, width : Int32, char_offset : Int32, column_offset : Int32

      # Alias for Go-style setters
      def set_width(w : Int32)
        self.width = w
      end

      def set_height(h : Int32)
        self.height = h
      end

      def focus : Cmd
        Zone.focus(@id) unless @id.empty?
        @cursor.focus
      end

      def blur
        Zone.blur(@id) unless @id.empty?
        @cursor.blur
      end

      def blink : Cmd
        @cursor.blink_cmd
      end

      def focused?
        return @cursor.focus? if @id.empty?
        Zone.focused?(@id)
      end

      # Update logic
      def update(msg : Msg) : {TextArea, Cmd}
        new_cursor, cmd = @cursor.update(msg)
        @cursor = new_cursor

        case msg
        when ZoneClickMsg
          if !@id.empty? && msg.id == @id
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
        lines = split_lines(@value)

        # Ensure we always have at least one line
        lines = [""] if lines.empty?

        @cursor_line = @cursor_line.clamp(0, lines.size - 1)
        @cursor_col = @cursor_col.clamp(0, lines[@cursor_line].size)

        current_display_x = display_width(lines[@cursor_line][0...@cursor_col])
        if !@last_move_vertical && @preferred_x != current_display_x
          @preferred_x = current_display_x
        end
        target_x = @preferred_x
        target_x = current_display_x if target_x <= 0

        case
        when @key_map.line_previous.matches?(msg)
          @cursor_line = (@cursor_line - 1).clamp(0, lines.size - 1)
          @cursor_col = column_for_display(lines[@cursor_line], target_x)
          @last_move_vertical = true
        when @key_map.line_next.matches?(msg)
          @cursor_line = (@cursor_line + 1).clamp(0, lines.size - 1)
          @cursor_col = column_for_display(lines[@cursor_line], target_x)
          @last_move_vertical = true
        when @key_map.character_backward.matches?(msg)
          if @cursor_col > 0
            @cursor_col -= 1
          elsif @cursor_line > 0
            @cursor_line -= 1
            @cursor_col = lines[@cursor_line].size
          end
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.character_forward.matches?(msg)
          if @cursor_col < lines[@cursor_line].size
            @cursor_col += 1
          elsif @cursor_line < lines.size - 1
            @cursor_line += 1
            @cursor_col = 0
          end
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.insert_newline.matches?(msg)
          insert_newline(lines)
          @preferred_x = 0
          @last_move_vertical = false
        when @key_map.delete_word_backward.matches?(msg)
          if @cursor_col <= 0
            delete_char(lines) # merges with previous line
          else
            delete_word_left(lines)
          end
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.delete_character_backward.matches?(msg)
          delete_char(lines)
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        else
          # Check for regular typing
          if msg.key.type == KeyType::Runes && !msg.key.alt? && !msg.key.type.control?
            if @char_limit > 0 && @value.size >= @char_limit
              return
            end
            insert_char(lines, msg.key.to_s)
            @last_move_vertical = false
          end
        end

        @value = lines.join("\n")
        @preferred_x = display_width(lines[@cursor_line][0...@cursor_col]) unless @last_move_vertical
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

      def delete_word_left(lines : Array(String))
        line = lines[@cursor_line]
        chars = line.chars
        return if @cursor_col <= 0 || chars.empty?

        old_col = @cursor_col.clamp(0, chars.size)
        cursor = (old_col - 1).clamp(0, chars.size - 1)

        while cursor > 0 && chars[cursor].whitespace?
          cursor -= 1
        end

        while cursor > 0
          if !chars[cursor].whitespace?
            cursor -= 1
          else
            cursor += 1
            break
          end
        end

        start_col = cursor
        start_col = start_col.clamp(0, old_col)

        new_chars = [] of Char
        new_chars.concat(chars[0...start_col]) if start_col > 0
        new_chars.concat(chars[old_col..-1]) if old_col < chars.size

        lines[@cursor_line] = new_chars.join
        @cursor_col = start_col
      end

      def insert_char(lines : Array(String), char : String)
        line = lines[@cursor_line]
        left = line[0...@cursor_col]
        right = line[@cursor_col..-1]
        lines[@cursor_line] = left + char + right
        @cursor_col += char.size
        @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
      end

      def reset
        @value = ""
        @cursor_line = 0
        @cursor_col = 0
        update_viewport
        scroll_to_cursor
      end

      def insert_string(str : String)
        lines = split_lines(@value)
        lines = [""] if lines.empty?

        @cursor_line = @cursor_line.clamp(0, lines.size - 1)
        @cursor_col = @cursor_col.clamp(0, lines[@cursor_line].size)

        line = lines[@cursor_line]
        left = line[0...@cursor_col]
        right = line[@cursor_col..-1]
        new_val = left + str + right
        if @char_limit > 0 && new_val.size > @char_limit
          new_val = new_val[0...@char_limit]
        end
        lines[@cursor_line] = new_val
        @value = lines.join("\n")
        @cursor_col = left.size + str.size
        @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
        update_viewport
        scroll_to_cursor
      end

      def line_info : LineInfo
        lines = split_lines(@value)
        lines = [""] if lines.empty?
        line = lines[@cursor_line]?
        line ||= ""
        available = [@width - visible_prefix_width, 0].max
        width = display_width(line).clamp(0, available)
        char_offset = display_width(line[0...@cursor_col])
        LineInfo.new(width, char_offset, @cursor_col)
      end

      def update_viewport
        lines = split_lines(@value)
        lines = [""] if lines.empty?

        rendered_lines = [] of String

        lines.each_with_index do |line, i|
          base_prefix = ""
          if @show_line_numbers
            base_prefix = sprintf("%3d ", i + 1)
          end
          base_prefix += @prompt
          available = [@width - Lipgloss::Text.width(base_prefix), 1].max
          wrapped =
            if @value.empty? && i == 0 && !@placeholder.empty? && line.empty?
              [Lipgloss::Text.truncate(@placeholder, available)]
            else
              wrap_line(line, available)
            end
          wrapped.each_with_index do |wrapped_line, wl_idx|
            rendered = base_prefix + wrapped_line

            # Cursor at end of logical line: append it to the end of the last wrapped line.
            if i == @cursor_line && focused? && @cursor_col >= line.size && wl_idx == wrapped.size - 1
              @cursor.char = " "
              rendered += @cursor.view.content
            end

            rendered_lines << rendered
          end
        end

        # Add End of Buffer markers for empty space
        visible_lines = rendered_lines.size
        if visible_lines < @height
          (visible_lines...@height).each do
            rendered_lines << @end_of_buffer_char
          end
        end

        @viewport.content = rendered_lines.join("\n")
      end

      private def wrap_line(line : String, width : Int32) : Array(String)
        return [line] if width <= 0

        lines = [([] of Char)]
        row = 0

        current_word = [] of Char
        current_word_width = 0

        spaces = 0
        current_line_width = 0

        line.each_char do |ch|
          if ch.whitespace?
            spaces += 1
          else
            current_word << ch
            current_word_width += UnicodeCharWidth.width(ch)
          end

          if spaces > 0
            if current_line_width + current_word_width + spaces > width
              row += 1
              lines << ([] of Char)
              lines[row].concat(current_word)
              lines[row].concat(Array.new(spaces, ' '))
              current_line_width = current_word_width + spaces
            else
              lines[row].concat(current_word)
              lines[row].concat(Array.new(spaces, ' '))
              current_line_width += current_word_width + spaces
            end

            spaces = 0
            current_word.clear
            current_word_width = 0
          else
            # Handle edge case with double-width runes at the end of the line.
            if current_word.size > 0
              last_char_width = UnicodeCharWidth.width(current_word.last)
              if current_word_width + last_char_width > width
                if lines[row].size > 0
                  row += 1
                  lines << ([] of Char)
                  current_line_width = 0
                end
                lines[row].concat(current_word)
                current_line_width = current_word_width
                current_word.clear
                current_word_width = 0
              end
            end
          end
        end

        if current_line_width + current_word_width + spaces >= width
          lines << ([] of Char)
          lines[row + 1].concat(current_word)
          spaces += 1
          lines[row + 1].concat(Array.new(spaces, ' '))
        else
          lines[row].concat(current_word)
          spaces += 1
          lines[row].concat(Array.new(spaces, ' '))
        end

        lines.map(&.join)
      end

      def scroll_to_cursor
        # Basic scrolling logic
        if @cursor_line < @viewport.y_offset
          @viewport.y_offset = @cursor_line
        elsif @cursor_line >= @viewport.y_offset + @viewport.height
          @viewport.y_offset = @cursor_line - @viewport.height + 1
        end
      end

      def view : View
        # Force an update if value changed externally?
        # Usually update_viewport happens in update loop, but for simple tests:
        update_viewport if @viewport.content.empty? && !@value.empty?

        inner_view = @viewport.view
        if @id.empty?
          inner_view
        else
          View.new(content: Zone.mark(@id, inner_view.content))
        end
      end

      private def split_lines(s : String) : Array(String)
        # Crystal's split behavior differs from Go's regarding trailing newlines
        s.split('\n')
      end

      private def display_width(str : String) : Int32
        UnicodeCharWidth.width(str)
      end

      private def column_for_display(line : String, target_width : Int32) : Int32
        return 0 if target_width <= 0
        width = 0
        line.each_char_with_index do |ch, idx|
          width += UnicodeCharWidth.width(ch)
          return idx + 1 if width >= target_width
        end
        line.size
      end

      private def visible_prefix_width : Int32
        prefix = ""
        prefix = sprintf("%3d ", @cursor_line + 1) if @show_line_numbers
        prefix += @prompt
        Lipgloss::Text.width(prefix)
      end

      def value=(text : String)
        new_val = if @char_limit > 0 && text.size > @char_limit
                    text[0...@char_limit]
                  else
                    text
                  end
        @value = new_val
        lines = split_lines(@value)
        if lines.empty?
          @cursor_line = 0
          @cursor_col = 0
        else
          @cursor_line = lines.size - 1
          @cursor_col = lines.last.size
        end
        @preferred_x = display_width(lines.last? || "")
        @last_move_vertical = false
        update_viewport
        scroll_to_cursor
      end
    end
  end
end
