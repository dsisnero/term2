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
      property height : Int32 = 6
      property? show_line_numbers : Bool = true
      property prompt : String = "> "
      property placeholder : String = "Hello, World!"
      property end_of_buffer_char : Char = ' '
      property char_limit : Int32 = 0
      property max_width : Int32 = 500
      property max_height : Int32 = 99
      property? show_line_numbers_placeholder : Bool = true
      property? word_wrap : Bool = true
      @last_vertical_column : Int32? = nil

      # Key bindings (parity with Bubbles)
      property key_map : KeyMap

      property viewport : Viewport
      property cursor : Cursor
      getter line_info_cache : LineInfo = LineInfo.new(0, 0, 0, 0, 0, 0, 0)

      struct LineInfo
        getter width : Int32
        getter char_width : Int32
        getter height : Int32
        getter start_column : Int32
        getter column_offset : Int32
        getter row_offset : Int32
        getter char_offset : Int32

        def initialize(@width, @char_width, @height, @start_column, @column_offset, @row_offset, @char_offset)
        end
      end

      struct KeyMap
        getter character_backward : Key::Binding
        getter character_forward : Key::Binding
        getter word_backward : Key::Binding
        getter word_forward : Key::Binding
        getter delete_after_cursor : Key::Binding
        getter delete_before_cursor : Key::Binding
        getter delete_character_backward : Key::Binding
        getter delete_character_forward : Key::Binding
        getter delete_word_backward : Key::Binding
        getter delete_word_forward : Key::Binding
        getter insert_newline : Key::Binding
        getter line_end : Key::Binding
        getter line_next : Key::Binding
        getter line_previous : Key::Binding
        getter line_start : Key::Binding
        getter paste : Key::Binding
        getter input_begin : Key::Binding
        getter input_end : Key::Binding
        getter lowercase_word_forward : Key::Binding
        getter uppercase_word_forward : Key::Binding
        getter capitalize_word_forward : Key::Binding
        getter transpose_character_backward : Key::Binding

        def initialize
          @character_forward = Key::Binding.new(["right", "ctrl+f"], "right", "character forward")
          @character_backward = Key::Binding.new(["left", "ctrl+b"], "left", "character backward")
          @word_forward = Key::Binding.new(["alt+right", "alt+f"], "alt+right", "word forward")
          @word_backward = Key::Binding.new(["alt+left", "alt+b"], "alt+left", "word backward")
          @line_next = Key::Binding.new(["down", "ctrl+n"], "down", "next line")
          @line_previous = Key::Binding.new(["up", "ctrl+p"], "up", "previous line")
          @delete_word_backward = Key::Binding.new(["alt+backspace", "ctrl+w"], "alt+backspace", "delete word backward")
          @delete_word_forward = Key::Binding.new(["alt+delete", "alt+d"], "alt+delete", "delete word forward")
          @delete_after_cursor = Key::Binding.new(["ctrl+k"], "ctrl+k", "delete after cursor")
          @delete_before_cursor = Key::Binding.new(["ctrl+u"], "ctrl+u", "delete before cursor")
          @insert_newline = Key::Binding.new(["enter", "ctrl+m"], "enter", "insert newline")
          @delete_character_backward = Key::Binding.new(["backspace", "ctrl+h"], "backspace", "delete character backward")
          @delete_character_forward = Key::Binding.new(["delete", "ctrl+d"], "delete", "delete character forward")
          @line_start = Key::Binding.new(["home", "ctrl+a"], "home", "line start")
          @line_end = Key::Binding.new(["end", "ctrl+e"], "end", "line end")
          @paste = Key::Binding.new(["ctrl+v"], "ctrl+v", "paste")
          @input_begin = Key::Binding.new(["alt+<", "ctrl+home"], "start", "input begin")
          @input_end = Key::Binding.new(["alt+>", "ctrl+end"], "end", "input end")
          @lowercase_word_forward = Key::Binding.new(["alt+l"], "alt+l", "lowercase word forward")
          @uppercase_word_forward = Key::Binding.new(["alt+u"], "alt+u", "uppercase word forward")
          @capitalize_word_forward = Key::Binding.new(["alt+c"], "alt+c", "capitalize word forward")
          @transpose_character_backward = Key::Binding.new(["ctrl+t"], "ctrl+t", "transpose character backward")
        end
      end

      def initialize(@id : String = "")
        @viewport = Viewport.new(@width, @height)
        @cursor = Cursor.new
        @cursor.mode = Cursor::Mode::Static
        @cursor.style = Style.new
        @cursor.text_style = Style.new
        @cursor.focus = true
        @key_map = KeyMap.new
        update_viewport
      end

      def focus : Cmd
        Zone.focus(@id) unless @id.empty?
        @cursor.focus_cmd
      end

      # Start cursor blinking (parity with Bubbles' textarea.Blink command)
      def blink : Cmd
        @cursor.mode = Cursor::Mode::Blink
        @cursor.blink_cmd
      end

      def blur
        Zone.blur(@id) unless @id.empty?
        @cursor.blur
      end

      def focused?
        return @cursor.focus? if @id.empty?
        Zone.focused?(@id) || @cursor.focus?
      end

      def value=(val : String)
        if @char_limit > 0 && val.size > @char_limit
          val = val[0, @char_limit]
        end
        @value = val
        update_viewport
        recalc_cursor_from_value(clamp_only: false)
      end

      def set_value(val : String)
        self.value = val
      end

      def reset
        @value = ""
        @cursor_line = 0
        @cursor_col = 0
        reset_vertical_memory
        @viewport.goto_top
        recalc_line_info
      end

      def set_width(w : Int32)
        target = w
        if @max_width > 0 && target > @max_width
          target = @max_width
        end
        @width = target
        @viewport.width = w
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

        if @key_map.line_previous.matches?(msg)
          move_vertically(lines, -1)
        elsif @key_map.line_next.matches?(msg)
          move_vertically(lines, 1)
        elsif @key_map.character_backward.matches?(msg)
          move_left(lines, false)
        elsif @key_map.character_forward.matches?(msg)
          move_right(lines, false)
        elsif @key_map.word_backward.matches?(msg)
          word_left(lines)
        elsif @key_map.word_forward.matches?(msg)
          word_right(lines)
        elsif @key_map.line_start.matches?(msg)
          @cursor_col = 0
          reset_vertical_memory
        elsif @key_map.line_end.matches?(msg)
          @cursor_col = lines[@cursor_line].size
          reset_vertical_memory
        elsif @key_map.input_begin.matches?(msg)
          @cursor_line = 0
          @cursor_col = 0
          reset_vertical_memory
        elsif @key_map.input_end.matches?(msg)
          @cursor_line = lines.size - 1
          @cursor_col = lines[@cursor_line].size
          reset_vertical_memory
        elsif @key_map.delete_character_backward.matches?(msg)
          delete_char(lines)
        elsif @key_map.delete_character_forward.matches?(msg)
          delete_forward(lines)
        elsif @key_map.delete_word_backward.matches?(msg)
          delete_word_backward(lines)
        elsif @key_map.delete_word_forward.matches?(msg)
          delete_word_forward(lines)
        elsif @key_map.delete_before_cursor.matches?(msg)
          delete_before_cursor(lines)
        elsif @key_map.delete_after_cursor.matches?(msg)
          delete_after_cursor(lines)
        elsif @key_map.transpose_character_backward.matches?(msg)
          transpose_left(lines)
        elsif @key_map.insert_newline.matches?(msg)
          insert_newline(lines)
        elsif @key_map.lowercase_word_forward.matches?(msg)
          lowercase_word_forward(lines)
        elsif @key_map.uppercase_word_forward.matches?(msg)
          uppercase_word_forward(lines)
        elsif @key_map.capitalize_word_forward.matches?(msg)
          capitalize_word_forward(lines)
        else
          if msg.key.type == KeyType::Space
            insert_char(lines, " ")
          elsif msg.key.type == KeyType::Runes && !msg.key.alt?
            msg.key.to_s.each_char do |ch|
              if ch == '\n'
                insert_newline(lines)
              else
                insert_char(lines, ch.to_s)
              end
            end
          end
        end

        @value = lines.join("\n")
        recalc_cursor_from_value
      end

      private def move_vertically(lines : Array(String), delta : Int32)
        current_line = lines[@cursor_line]? || ""
        target_visual = @last_vertical_column || visual_offset_for_line(current_line, @cursor_col)

        @cursor_line = (@cursor_line + delta).clamp(0, lines.size - 1)
        new_line = lines[@cursor_line]? || ""
        @cursor_col = col_for_visual_offset(new_line, target_visual)

        @last_vertical_column = target_visual
      end

      private def reset_vertical_memory
        @last_vertical_column = nil
      end

      def insert_newline(lines : Array(String))
        return if @char_limit > 0 && (@value.size + 1) > @char_limit
        current_line = lines[@cursor_line]
        left = current_line[0...@cursor_col]
        right = current_line[@cursor_col..-1]

        lines[@cursor_line] = left
        lines.insert(@cursor_line + 1, right)

        @cursor_line += 1
        @cursor_col = 0
        reset_vertical_memory
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
        @last_vertical_column = nil
      end

      private def delete_forward(lines : Array(String))
        line = lines[@cursor_line]
        if @cursor_col < line.size
          lines[@cursor_line] = line[0...@cursor_col] + line[(@cursor_col + 1)..-1]
        elsif @cursor_line < lines.size - 1
          # merge with next line
          lines[@cursor_line] = line + lines.delete_at(@cursor_line + 1)
        end
        reset_vertical_memory
      end

      private def delete_before_cursor(lines : Array(String))
        line = lines[@cursor_line]
        lines[@cursor_line] = line[@cursor_col..-1] || ""
        @cursor_col = 0
        reset_vertical_memory
      end

      private def delete_after_cursor(lines : Array(String))
        line = lines[@cursor_line]
        lines[@cursor_line] = line[0...@cursor_col] || ""
        reset_vertical_memory
      end

      private def move_left(lines : Array(String), inside_line : Bool)
        if @cursor_col == 0 && @cursor_line > 0
          @cursor_line -= 1
          @cursor_col = lines[@cursor_line].size
          return unless inside_line
        end
        if @cursor_col > 0
          @cursor_col -= 1
        end
        reset_vertical_memory
      end

      private def move_right(lines : Array(String), inside_line : Bool)
        line = lines[@cursor_line]
        if @cursor_col < line.size
          @cursor_col += 1
        elsif @cursor_line < lines.size - 1
          @cursor_line += 1
          @cursor_col = 0
        end
        reset_vertical_memory unless inside_line
      end

      private def word_left(lines : Array(String))
        return if @cursor_col == 0 && @cursor_line == 0

        move_left(lines, true)
        line = lines[@cursor_line]
        while @cursor_col > 0 && line[@cursor_col]?.try &.whitespace?
          move_left(lines, true)
          line = lines[@cursor_line]
        end
        while @cursor_col > 0 && !line[@cursor_col - 1].whitespace?
          move_left(lines, true)
          line = lines[@cursor_line]
        end
        reset_vertical_memory
      end

      private def word_right(lines : Array(String))
        line = lines[@cursor_line]
        while @cursor_col < line.size && !line[@cursor_col].whitespace?
          move_right(lines, true)
          line = lines[@cursor_line]
        end
        while @cursor_col < line.size && line[@cursor_col].whitespace?
          move_right(lines, true)
          line = lines[@cursor_line]
        end
        reset_vertical_memory
      end

      private def delete_word_backward(lines : Array(String))
        line = lines[@cursor_line]
        return if line.empty? && @cursor_line == 0

        start = @cursor_col
        while start > 0 && line[start - 1].whitespace?
          start -= 1
        end
        while start > 0 && !line[start - 1].whitespace?
          start -= 1
        end
        if start == @cursor_col && @cursor_line > 0
          prev = lines[@cursor_line - 1]
          @cursor_col = prev.size
          lines[@cursor_line - 1] = prev + line
          lines.delete_at(@cursor_line)
          @cursor_line -= 1
        else
          lines[@cursor_line] = line[0...start] + line[@cursor_col..-1]
          @cursor_col = start
        end
        reset_vertical_memory
      end

      private def delete_word_forward(lines : Array(String))
        line = lines[@cursor_line]
        start = @cursor_col
        finish = start
        while finish < line.size && line[finish].whitespace?
          finish += 1
        end
        while finish < line.size && !line[finish].whitespace?
          finish += 1
        end
        if finish == start && @cursor_line < lines.size - 1
          # merge with next line
          lines[@cursor_line] = line + lines.delete_at(@cursor_line + 1)
        else
          lines[@cursor_line] = line[0...start] + line[finish..-1]
        end
        reset_vertical_memory
      end

      private def transpose_left(lines : Array(String))
        line = lines[@cursor_line]
        return if @cursor_col == 0 || line.size < 2
        col = @cursor_col
        col = line.size - 1 if col >= line.size
        chars = line.chars
        chars[col - 1], chars[col] = chars[col], chars[col - 1]
        lines[@cursor_line] = chars.join
        @cursor_col = (col + 1).clamp(0, lines[@cursor_line].size)
        reset_vertical_memory
      end

      private def lowercase_word_forward(lines : Array(String))
        mutate_word_forward(lines) { |c| c.downcase }
      end

      private def uppercase_word_forward(lines : Array(String))
        mutate_word_forward(lines) { |c| c.upcase }
      end

      private def capitalize_word_forward(lines : Array(String))
        first = true
        mutate_word_forward(lines) do |c|
          if first
            first = false
            c.titlecase
          else
            c.downcase
          end
        end
      end

      private def mutate_word_forward(lines : Array(String))
        line = lines[@cursor_line]
        return if @cursor_col >= line.size
        chars = line.chars
        idx = @cursor_col
        while idx < chars.size && chars[idx].whitespace?
          idx += 1
        end
        while idx < chars.size && !chars[idx].whitespace?
          chars[idx] = yield chars[idx]
          idx += 1
        end
        lines[@cursor_line] = chars.join
        reset_vertical_memory
      end

      def insert_char(lines : Array(String), char : String)
        return if @cursor_line >= lines.size
        line = lines[@cursor_line]
        col = @cursor_col.clamp(0, line.size)
        left = line[0...col]
        right = line[col..-1]
        if @char_limit > 0 && (@value.size + char.size) > @char_limit
          return
        end
        lines[@cursor_line] = left + char + right
        @cursor_col = col + char.size
        recalc_line_info
        @last_vertical_column = visual_offset_for_line(lines[@cursor_line], @cursor_col)
      end

      def value
        @value
      end

      def insert_string(str : String)
        lines = @value.split("\n", remove_empty: false)
        lines << "" if lines.empty?
        return if @cursor_line >= lines.size
        line = lines[@cursor_line]
        col = @cursor_col.clamp(0, line.size)
        left = line[0...col]
        right = line[col..-1]
        if @char_limit > 0 && (@value.size + str.size) > @char_limit
          allowed = @char_limit - @value.size
          return if allowed <= 0
          str = str[0, allowed]
        end
        lines[@cursor_line] = left + str + right
        @cursor_col = col + str.size
        @value = lines.join("\n")
        recalc_cursor_from_value
        @last_vertical_column = visual_offset_for_line(lines[@cursor_line], @cursor_col)
      end

      def update_viewport
        @viewport.height = effective_height

        if @value.empty?
          use_numbers = @show_line_numbers_placeholder && @show_line_numbers
          width = @width - @prompt.size
          width -= line_number_width if use_numbers
          width = @max_width if @max_width > 0 && width > @max_width
          width = 1 if width < 1
          prefix = prefix_width(use_numbers)
          @viewport.width = {prefix + width, 1}.max
          content = build_placeholder_view(width, use_numbers)
          @viewport.content = content
          return
        end

        prefix = prefix_width
        avail = available_width
        @viewport.width = {prefix + avail, 1}.max
        content = build_value_view
        @viewport.content = content
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

      private def recalc_cursor_from_value(*, clamp_only : Bool = true)
        lines = @value.split("\n", remove_empty: false)
        lines << "" if lines.empty?

        if clamp_only
          @cursor_line = @cursor_line.clamp(0, lines.size - 1)
          @cursor_col = @cursor_col.clamp(0, lines[@cursor_line].size)
        else
          @cursor_line = lines.size - 1
          @cursor_col = lines[@cursor_line].size
        end

        recalc_line_info
      end

      def line_info : LineInfo
        recalc_line_info
        @line_info_cache
      end

      private def recalc_line_info
        raw_lines = @value.split("\n", remove_empty: false)
        raw_lines << "" if raw_lines.empty?
        current_line = raw_lines[@cursor_line]? || ""
        wrapped = wrap_line(current_line)
        counter = 0

        wrapped.each_with_index do |seg, idx|
          seg_len = seg.chars.size
          next_segment = wrapped[idx + 1]?

          if counter + seg_len == @cursor_col && next_segment
            width = Term2::Text.width(next_segment)
            @line_info_cache = LineInfo.new(width, width, wrapped.size, counter + seg_len, 0, idx + 1, 0)
            return
          end

          if counter + seg_len >= @cursor_col
            col_offset = @cursor_col - counter
            char_off = visual_offset_for_line(seg, col_offset)
            width = Term2::Text.width(seg)
            @line_info_cache = LineInfo.new(width, width, wrapped.size, counter, col_offset, idx, char_off)
            return
          end

          counter += seg_len
        end

        @line_info_cache = LineInfo.new(0, 0, wrapped.size, counter, 0, wrapped.size - 1, 0)
      end

      private def available_width(*, use_line_numbers : Bool = @show_line_numbers) : Int32
        width = @width - prefix_width(use_line_numbers)
        if @max_width > 0 && width > @max_width
          width = @max_width
        end
        width = 1 if width < 1
        width
      end

      private def line_number_width : Int32
        digits = @max_height.to_s.size
        # format is " %*d "
        digits + 2
      end

      private def prefix_width(use_line_numbers : Bool = @show_line_numbers) : Int32
        prefix = @prompt.size
        prefix += line_number_width if use_line_numbers
        prefix
      end

      private def format_line_number(num) : String
        sprintf(" %#{@max_height.to_s.size}s ", num)
      end

      private def wrap_line(line : String, width_override : Int32? = nil) : Array(String)
        width = width_override || available_width
        width = 1 if width < 1
        return line.chars.map(&.to_s) if width <= 1

        lines = [""]
        word = ""
        row = 0
        spaces = 0

        line.each_char do |ch|
          if ch.whitespace?
            spaces += 1
          else
            word += ch
          end

          if spaces > 0
            current_width = Term2::Text.width(lines[row]) + Term2::Text.width(word)
            spaces_to_add = spaces
            carry_spaces = false
            if current_width + spaces > width && current_width <= width
              lines[row] += word
              row += 1
              lines << ""
              word = ""
              spaces = 0
              next
            end

            if current_width + spaces > width
              row += 1
              lines << ""
              lines[row] += word
              lines[row] += " " * spaces_to_add
            else
              lines[row] += word
              lines[row] += " " * spaces_to_add
            end
            word = ""
            spaces = carry_spaces ? spaces : 0
          else
            unless word.empty?
              last_char_len = Term2::Text.char_width(word.chars.last)
              if Term2::Text.width(word) + last_char_len > width
                if !lines[row].empty?
                  row += 1
                  lines << ""
                end
                lines[row] += word
                word = ""
              end
            end
          end
        end

        if !word.empty? || spaces > 0
          if Term2::Text.width(lines[row]) + Term2::Text.width(word) + spaces > width
            row += 1
            lines << ""
          end
          lines[row] += word
          lines[row] += " " * spaces
        end

        lines = [""] if lines.empty?
        lines
      end

      def view : String
        update_viewport
        content = @viewport.view
        return content if @id.empty?
        Zone.mark(@id, content)
      end

      private def build_placeholder_view(width : Int32, use_line_numbers : Bool) : String
        placeholder_lines = [] of String
        @placeholder.split("\n").each do |pl|
          placeholder_lines.concat(wrap_line(pl, width))
        end

        height = effective_height
        rendered = [] of String

        height.times do |idx|
          rendered << String.build do |s|
            s << @prompt
            if use_line_numbers
              if idx == 0
                s << format_line_number(idx + 1)
              elsif idx < placeholder_lines.size
                s << format_line_number(" ")
              end
            end

            if idx < placeholder_lines.size
              line = placeholder_lines[idx]
              chars = line.chars
              if idx == 0 && !chars.empty?
                @cursor.char = chars.first.to_s
                s << @cursor.view
                s << chars[1..-1].join
              else
                s << line
              end
            else
              s << @end_of_buffer_char
            end
          end
        end

        rendered.join("\n")
      end

      private def build_value_view : String
        raw_lines = @value.split("\n", remove_empty: false)
        raw_lines << "" if raw_lines.empty?
        info = line_info
        rendered = [] of String

        raw_lines.each_with_index do |line, idx|
          wrap_line(line).each_with_index do |seg, seg_idx|
            rendered << render_segment(seg, idx, seg_idx, info)
          end
        end

        while rendered.size < effective_height
          rendered << "#{@prompt}#{@end_of_buffer_char}"
        end

        rendered.join("\n")
      end

      private def render_segment(seg : String, raw_idx : Int32, seg_idx : Int32, info : LineInfo) : String
        String.build do |s|
          s << @prompt
          if @show_line_numbers
            ln = seg_idx == 0 ? format_line_number(raw_idx + 1) : format_line_number(" ")
            s << ln
          end

          if raw_idx == @cursor_line && seg_idx == info.row_offset && focused?
            chars = seg.chars
            col = info.column_offset
            col = chars.size if col > chars.size

            cursor_char = col < chars.size ? chars[col].to_s : " "
            @cursor.char = cursor_char

            left = chars[0, col].join
            right = col < chars.size ? chars[(col + 1)..-1].join : ""
            s << left
            s << @cursor.view
            s << right
          else
            s << seg
          end
        end
      end

      private def effective_height : Int32
        h = @height
        h = 6 if h <= 0
        h
      end

      def cursor_line_number : Int32
        raw_lines = @value.split("\n", remove_empty: false)
        raw_lines << "" if raw_lines.empty?
        total = 0
        raw_lines.each_with_index do |line, idx|
          wrapped = wrap_line(line)
          if idx < @cursor_line
            total += wrapped.size
          elsif idx == @cursor_line
            total += line_info.row_offset
            break
          end
        end
        total
      end

      private def visual_offset_for_line(line : String, col : Int32) : Int32
        offset = 0
        line.chars.first(col).each do |ch|
          offset += Term2::Text.char_width(ch)
        end
        offset
      end

      private def col_for_visual_offset(line : String, target_visual : Int32) : Int32
        return 0 if target_visual <= 0

        chars = line.chars
        offset = 0
        idx = 0
        chars.each do |ch|
          offset += Term2::Text.char_width(ch)
          idx += 1
          break if offset >= target_visual
        end
        chars.size < idx ? chars.size : idx
      end
    end
  end
end
