require "../term2"
require "./viewport"
require "./cursor"
require "./key"
require "uniwidth"
require "./memoization"
require "./rune_util"
require "easyclip"
require "cellwrap"

module Term2
  module Components
    class TextArea
      include Model

      MAX_LINES = 10000

      struct KeyMap
        getter character_backward : Key::Binding
        getter character_forward : Key::Binding
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
        getter page_up : Key::Binding
        getter page_down : Key::Binding
        getter paste : Key::Binding
        getter word_backward : Key::Binding
        getter word_forward : Key::Binding
        getter input_begin : Key::Binding
        getter input_end : Key::Binding
        getter uppercase_word_forward : Key::Binding
        getter lowercase_word_forward : Key::Binding
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
          @page_up = Key::Binding.new(["pgup"], "pgup", "page up")
          @page_down = Key::Binding.new(["pgdown"], "pgdown", "page down")
          @paste = Key::Binding.new(["ctrl+v"], "ctrl+v", "paste")
          @input_begin = Key::Binding.new(["alt+<", "ctrl+home"], "alt+<", "input begin")
          @input_end = Key::Binding.new(["alt+>", "ctrl+end"], "alt+>", "input end")
          @capitalize_word_forward = Key::Binding.new(["alt+c"], "alt+c", "capitalize word forward")
          @lowercase_word_forward = Key::Binding.new(["alt+l"], "alt+l", "lowercase word forward")
          @uppercase_word_forward = Key::Binding.new(["alt+u"], "alt+u", "uppercase word forward")
          @transpose_character_backward = Key::Binding.new(["ctrl+t"], "ctrl+t", "transpose character backward")
        end
      end

      private struct Line
        include Memoization::Hashable
        getter runes : Array(Char)
        getter width : Int32

        def initialize(@runes : Array(Char), @width : Int32)
        end

        def hash_value : String
          Digest::SHA256.hexdigest("#{runes.join}:#{width}")
        end

        def ==(other)
          other.is_a?(Line) && other.runes == @runes && other.width == @width
        end
      end

      def self.default_key_map : KeyMap
        KeyMap.new
      end

      # Cursor shape enum matching Go's tea.CursorShape
      enum CursorShape
        Block
        Underline
        Bar
      end

      # CursorStyle is the style for real and virtual cursors.
      struct CursorStyle
        property color : Lipgloss::Color? = nil
        property shape : CursorShape = CursorShape::Block
        property? blink : Bool = false
        property blink_speed : Time::Span = 500.milliseconds

        def initialize(@color = nil, @shape = CursorShape::Block, @blink = false, @blink_speed = 500.milliseconds)
        end
      end

      # StyleState that will be applied to the text area.
      # StyleState can be applied to focused and unfocused states to change the styles
      # depending on the focus state.
      struct StyleState
        property base : Lipgloss::Style
        property text : Lipgloss::Style
        property line_number : Lipgloss::Style
        property cursor_line_number : Lipgloss::Style
        property cursor_line : Lipgloss::Style
        property end_of_buffer : Lipgloss::Style
        property placeholder : Lipgloss::Style
        property prompt : Lipgloss::Style

        def initialize(
          @base = Lipgloss::Style.new,
          @text = Lipgloss::Style.new,
          @line_number = Lipgloss::Style.new,
          @cursor_line_number = Lipgloss::Style.new,
          @cursor_line = Lipgloss::Style.new,
          @end_of_buffer = Lipgloss::Style.new,
          @placeholder = Lipgloss::Style.new,
          @prompt = Lipgloss::Style.new,
        )
        end

        def computed_cursor_line : Lipgloss::Style
          @cursor_line.inherit(@base).inline(true)
        end

        def computed_cursor_line_number : Lipgloss::Style
          @cursor_line_number.inherit(@cursor_line).inherit(@base).inline(true)
        end

        def computed_end_of_buffer : Lipgloss::Style
          @end_of_buffer.inherit(@base).inline(true)
        end

        def computed_line_number : Lipgloss::Style
          @line_number.inherit(@base).inline(true)
        end

        def computed_placeholder : Lipgloss::Style
          @placeholder.inherit(@base).inline(true)
        end

        def computed_prompt : Lipgloss::Style
          @prompt.inherit(@base).inline(true)
        end

        def computed_text : Lipgloss::Style
          @text.inherit(@base).inline(true)
        end
      end

      # Styles are the styles for the textarea, separated into focused and blurred
      # states. The appropriate styles will be chosen based on the focus state of
      # the textarea.
      struct Styles
        property focused : StyleState
        property blurred : StyleState
        property cursor : CursorStyle

        def initialize(
          @focused = StyleState.new,
          @blurred = StyleState.new,
          @cursor = CursorStyle.new,
        )
        end
      end

      # Properties matching Go implementation
      property id : String = ""
      property? focus : Bool = false

      def focus=(value : Bool)
        @focus = value
        if @focus
          @cursor.focus
        else
          @cursor.blur
        end
      end

      private def active_style : StyleState
        focused? ? @styles.focused : @styles.blurred
      end

      private def update_cursor_style
        cursor_style = @styles.cursor
        @cursor.blink_speed = cursor_style.blink_speed
        # Set blink mode
        @cursor.mode = cursor_style.blink? ? Cursor::Mode::Blink : Cursor::Mode::Static
        # Map shape to Lipgloss::Style
        case cursor_style.shape
        when CursorShape::Block
          @cursor.style = Lipgloss::Style.new.reverse(true)
        when CursorShape::Underline
          @cursor.style = Lipgloss::Style.new.underline(true)
        when CursorShape::Bar
          # Bar cursor: vertical line at position, we'll use reverse for now
          @cursor.style = Lipgloss::Style.new.reverse(true)
        end
        # Apply color if set
        if color = cursor_style.color
          @cursor.style = @cursor.style.foreground(color)
          @cursor.text_style = Lipgloss::Style.new.foreground(color)
        else
          @cursor.text_style = Lipgloss::Style.new
        end
      end

      # SetStyles updates styling for the textarea.
      property styles : Styles = Styles.new

      def styles=(s : Styles)
        @styles = s
        update_cursor_style
      end

      # DefaultStyles returns the default styles for focused and blurred states.
      def self.default_styles(dark : Bool = false) : Styles
        # Simplified version - TODO: implement proper light/dark styles
        Styles.new
      end

      # DefaultLightStyles returns the default styles for a light background.
      def self.default_light_styles : Styles
        default_styles(false)
      end

      # DefaultDarkStyles returns the default styles for a dark background.
      def self.default_dark_styles : Styles
        default_styles(true)
      end

      def value : String
        @value.map(&.join).join("\n")
      end

      # Word returns the word at the cursor position.
      # A word is delimited by spaces or line-breaks.
      def word : String
        return "" if @cursor_line < 0 || @cursor_line >= @value.size

        line = @value[@cursor_line]
        col = @cursor_col - 1
        return "" if col < 0
        return "" if col >= line.size

        return "" if line[col].whitespace?

        start = col
        while start > 0 && !line[start - 1].whitespace?
          start -= 1
        end

        finish = col
        while finish < line.size && !line[finish].whitespace?
          finish += 1
        end

        line[start...finish].join
      end

      property cursor_line : Int32 = 0
      property cursor_col : Int32 = 0

      def value=(text : String)
        if @char_limit > 0 && text.size > @char_limit
          text = text[0...@char_limit]
        end
        @value = string_to_lines(text)
        if @value.empty?
          @cursor_line = 0
          @cursor_col = 0
        else
          @cursor_line = @value.size - 1
          @cursor_col = @value.last.size
        end
        @preferred_x = display_width(@value.last?.try(&.join) || "")
        @last_move_vertical = false
        update_viewport
        scroll_to_cursor
      end

      property? show_line_numbers : Bool = true
      getter prompt : String = "┃ "
      property placeholder : String = ""

      # End-of-buffer marker, rendered on otherwise blank lines.
      # Allows ANSI styling like the Go textarea's `Lipgloss::Style.EndOfBuffer`.
      property end_of_buffer_char : String = " "

      property char_limit : Int32 = 0
      getter max_height : Int32 = 99

      def max_height=(value : Int32)
        @max_height = value
        update_cache_capacity
      end

      property max_width : Int32 = 500

      property viewport : Viewport
      property cursor : Cursor
      property key_map : KeyMap
      property cache : Memoization::MemoCache(Line, Array(Array(Char))) = Memoization::MemoCache(Line, Array(Array(Char))).new(MAX_LINES)

      private def update_cache_capacity
        if @max_height > 0 && @max_height != @cache.capacity
          @cache = Memoization::MemoCache(Line, Array(Array(Char))).new(@max_height)
        end
      end

      # Styles following Go v2-exp API

      # Internal state
      @value : Array(Array(Char)) = [[] of Char]
      @width : Int32 = 40
      @height : Int32 = 6
      @preferred_x : Int32 = 0
      @last_char_offset : Int32 = 0
      @last_move_vertical : Bool = false
      @prompt_width : Int32 = 0

      def initialize(@id : String = "")
        @viewport = Viewport.new(40, 6)
        @cursor = Cursor.new
        @cursor.mode = Cursor::Mode::Blink
        @key_map = TextArea.default_key_map
        @prompt_width = Lipgloss::Text.width(@prompt)
        update_cursor_style
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
      record LineInfo,
        width : Int32,
        char_width : Int32,
        height : Int32,
        start_column : Int32,
        column_offset : Int32,
        row_offset : Int32,
        char_offset : Int32

      # Alias for Go-style setters
      # ameba:disable Naming/AccessorMethodName
      def set_width(w : Int32)
        @prompt_width = Lipgloss::Text.width(@prompt)

        reserved_outer = active_style.base.get_horizontal_frame_size
        reserved_inner = @prompt_width

        if @show_line_numbers
          reserved_inner += num_digits(@max_height) + 2
        end

        min_width = reserved_inner + reserved_outer + 1
        input_width = [w, min_width].max

        if @max_width > 0
          input_width = [input_width, @max_width].min
        end

        @viewport.width = input_width - reserved_outer
        @width = input_width - reserved_outer - reserved_inner
      end

      # ameba:disable Naming/AccessorMethodName
      def set_height(h : Int32)
        self.height = h
      end

      def focus : Cmd
        @focus = true
        @cursor.focus
      end

      def blur
        @focus = false
        @cursor.blur
      end

      def blink : Cmd
        @cursor.blink_cmd
      end

      def focused?
        @focus
      end

      def prompt=(value : String)
        @prompt = value
        @prompt_width = Lipgloss::Text.width(@prompt)
      end

      # Update logic
      def update(msg : Msg) : {TextArea, Cmd}
        new_cursor, cmd = @cursor.update(msg)
        @cursor = new_cursor

        case msg
        when UV::Key
          if focused?
            handle_key(msg)
            update_viewport
            scroll_to_cursor
          end
        end

        {self, cmd}
      end

      def handle_key(msg : UV::Key)
        lines = @value.map(&.join)

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
          set_cursor_line_relative(-1)
          @last_move_vertical = true
        when @key_map.line_next.matches?(msg)
          set_cursor_line_relative(1)
          @last_move_vertical = true
        when @key_map.character_backward.matches?(msg)
          if @cursor_col > 0
            @cursor_col -= 1
          elsif @cursor_line > 0
            @cursor_line -= 1
            @cursor_col = lines[@cursor_line].size
          end
          @last_char_offset = 0
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.character_forward.matches?(msg)
          if @cursor_col < lines[@cursor_line].size
            @cursor_col += 1
          elsif @cursor_line < lines.size - 1
            @cursor_line += 1
            @cursor_col = 0
          end
          @last_char_offset = 0
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.insert_newline.matches?(msg)
          insert_newline(lines)
          @last_char_offset = 0
          @preferred_x = 0
          @last_move_vertical = false
        when @key_map.delete_word_backward.matches?(msg)
          if @cursor_col <= 0
            delete_char(lines) # merges with previous line
          else
            delete_word_left(lines)
          end
          @last_char_offset = 0
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.delete_character_backward.matches?(msg)
          delete_char(lines)
          @last_char_offset = 0
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.delete_character_forward.matches?(msg)
          delete_character_forward(lines)
          @last_char_offset = 0
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.delete_after_cursor.matches?(msg)
          delete_after_cursor(lines)
          @last_char_offset = 0
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.delete_before_cursor.matches?(msg)
          delete_before_cursor(lines)
          @last_char_offset = 0
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.delete_word_forward.matches?(msg)
          delete_word_forward(lines)
          @last_char_offset = 0
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.line_start.matches?(msg)
          @cursor_col = 0
          @last_char_offset = 0
          @preferred_x = 0
          @last_move_vertical = false
        when @key_map.line_end.matches?(msg)
          @cursor_col = lines[@cursor_line].size
          @last_char_offset = 0
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.page_up.matches?(msg)
          page_up
          @last_move_vertical = true
        when @key_map.page_down.matches?(msg)
          page_down
          @last_move_vertical = true
        when @key_map.word_backward.matches?(msg)
          word_backward(lines)
          @last_char_offset = 0
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.word_forward.matches?(msg)
          word_forward(lines)
          @last_char_offset = 0
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.input_begin.matches?(msg)
          @cursor_line = 0
          @cursor_col = 0
          @last_char_offset = 0
          @preferred_x = 0
          @last_move_vertical = false
        when @key_map.input_end.matches?(msg)
          @cursor_line = lines.size - 1
          @cursor_col = lines.last.size
          @last_char_offset = 0
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.uppercase_word_forward.matches?(msg)
          uppercase_word_forward(lines)
          @last_char_offset = 0
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.lowercase_word_forward.matches?(msg)
          lowercase_word_forward(lines)
          @last_char_offset = 0
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.capitalize_word_forward.matches?(msg)
          capitalize_word_forward(lines)
          @last_char_offset = 0
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.transpose_character_backward.matches?(msg)
          transpose_character_backward(lines)
          @last_char_offset = 0
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        when @key_map.paste.matches?(msg)
          paste(lines)
          @last_char_offset = 0
          @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
          @last_move_vertical = false
        else
          # Check for regular typing
          if !msg.text.empty? && !UV.mod_contains?(msg.mod, UV::ModAlt) && !UV.mod_contains?(msg.mod, UV::ModCtrl)
            if @char_limit > 0 && value.size >= @char_limit
              return
            end
            insert_char(lines, msg.text)
            @last_char_offset = 0
            @last_move_vertical = false
          end
        end

        @value = lines.map(&.chars.to_a)
        @value = [[] of Char] if @value.empty?
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

      def delete_character_forward(lines : Array(String))
        line = lines[@cursor_line]
        if @cursor_col < line.size
          left = line[0...@cursor_col]
          right = line[@cursor_col + 1..-1]
          lines[@cursor_line] = left + right
        elsif @cursor_line < lines.size - 1
          # Merge with next line
          current = lines[@cursor_line]
          next_line = lines.delete_at(@cursor_line + 1)
          lines[@cursor_line] = current + next_line
        end
      end

      def delete_after_cursor(lines : Array(String))
        line = lines[@cursor_line]
        lines[@cursor_line] = line[0...@cursor_col]
      end

      def delete_before_cursor(lines : Array(String))
        line = lines[@cursor_line]
        lines[@cursor_line] = line[@cursor_col..-1]
        @cursor_col = 0
      end

      def delete_word_forward(lines : Array(String))
        line = lines[@cursor_line]
        chars = line.chars
        return if @cursor_col >= chars.size

        old_col = @cursor_col.clamp(0, chars.size)
        cursor = old_col

        while cursor < chars.size && chars[cursor].whitespace?
          cursor += 1
        end

        while cursor < chars.size
          if !chars[cursor].whitespace?
            cursor += 1
          else
            break
          end
        end

        end_col = cursor
        new_chars = [] of Char
        new_chars.concat(chars[0...old_col]) if old_col > 0
        new_chars.concat(chars[end_col..-1]) if end_col < chars.size
        lines[@cursor_line] = new_chars.join
      end

      def word_backward(lines : Array(String))
        line = lines[@cursor_line]
        chars = line.chars
        return if @cursor_col <= 0

        cursor = @cursor_col - 1
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
        @cursor_col = cursor
      end

      def word_forward(lines : Array(String))
        line = lines[@cursor_line]
        chars = line.chars
        return if @cursor_col >= chars.size

        cursor = @cursor_col
        while cursor < chars.size && chars[cursor].whitespace?
          cursor += 1
        end
        while cursor < chars.size
          if !chars[cursor].whitespace?
            cursor += 1
          else
            break
          end
        end
        @cursor_col = cursor
      end

      def uppercase_word_forward(lines : Array(String))
        line = lines[@cursor_line]
        chars = line.chars
        start = @cursor_col
        # find word start
        while start > 0 && !chars[start - 1].whitespace?
          start -= 1
        end
        # find word end
        finish = start
        while finish < chars.size && !chars[finish].whitespace?
          finish += 1
        end
        # uppercase
        (start...finish).each do |i|
          chars[i] = chars[i].upcase
        end
        lines[@cursor_line] = chars.join
        @cursor_col = finish
      end

      def lowercase_word_forward(lines : Array(String))
        line = lines[@cursor_line]
        chars = line.chars
        start = @cursor_col
        while start > 0 && !chars[start - 1].whitespace?
          start -= 1
        end
        finish = start
        while finish < chars.size && !chars[finish].whitespace?
          finish += 1
        end
        (start...finish).each do |i|
          chars[i] = chars[i].downcase
        end
        lines[@cursor_line] = chars.join
        @cursor_col = finish
      end

      def capitalize_word_forward(lines : Array(String))
        line = lines[@cursor_line]
        chars = line.chars
        start = @cursor_col
        while start > 0 && !chars[start - 1].whitespace?
          start -= 1
        end
        finish = start
        while finish < chars.size && !chars[finish].whitespace?
          finish += 1
        end
        if start < chars.size
          chars[start] = chars[start].upcase
          (start + 1...finish).each do |i|
            chars[i] = chars[i].downcase
          end
        end
        lines[@cursor_line] = chars.join
        @cursor_col = finish
      end

      def transpose_character_backward(lines : Array(String))
        line = lines[@cursor_line]
        chars = line.chars
        return if @cursor_col == 0 || @cursor_col >= chars.size
        # swap chars[@cursor_col - 1] and chars[@cursor_col]
        chars[@cursor_col - 1], chars[@cursor_col] = chars[@cursor_col], chars[@cursor_col - 1]
        lines[@cursor_line] = chars.join
        @cursor_col += 1
      end

      def paste(lines : Array(String))
        content = EasyClip.paste
        return if content.empty?
        # Enforce char limit if set
        if @char_limit > 0
          current_value = lines.join("\n")
          remaining = @char_limit - current_value.size
          return if remaining <= 0
          if content.size > remaining
            content = content[0...remaining]
          end
        end
        # Split by newline, preserving empty lines (split with limit -1)
        paste_lines = content.split('\n', -1)
        # If single line (no newline) or trailing newline results in empty last line, handle
        # For now, treat each line as separate insertion
        # Insert first line at cursor position
        first_line = paste_lines[0]
        insert_char(lines, first_line)
        # For remaining lines, insert as new lines
        paste_lines[1..-1].each do |line|
          # Move to next line (insert newline) and insert line
          insert_newline(lines)
          insert_char(lines, line)
        end
      rescue ex : EasyClip::PasteError
        Log.debug { "TextArea paste failed: #{ex.message}" }
      end

      def reset
        @value = [[] of Char]
        @cursor_line = 0
        @cursor_col = 0
        update_viewport
        scroll_to_cursor
      end

      def insert_string(str : String)
        lines = @value.map(&.join)
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
        @value = lines.map(&.chars.to_a)
        @value = [[] of Char] if @value.empty?
        @cursor_col = left.size + str.size
        @preferred_x = display_width(lines[@cursor_line][0...@cursor_col])
        update_viewport
        scroll_to_cursor
      end

      def line_info : LineInfo
        lines = @value.map(&.join)
        lines = [""] if lines.empty?
        line = lines[@cursor_line]?
        line ||= ""

        # Available width for text (after prompt and line numbers)
        available = [@width, 1].max

        # Get wrapped segments for this line
        grid = memoized_wrap(line.chars.to_a, available)

        counter = 0
        grid.each_with_index do |wrapped_line, i|
          # Check if cursor is at the exact boundary between wrapped segments
          if counter + wrapped_line.size == @cursor_col && i + 1 < grid.size
            # Cursor at end of wrapped line, wrap to next line
            return LineInfo.new(
              width: wrapped_line.size,
              char_width: display_width(wrapped_line.join),
              height: grid.size,
              start_column: @cursor_col,
              column_offset: 0,
              row_offset: i + 1,
              char_offset: 0
            )
          end

          if counter + wrapped_line.size >= @cursor_col
            # Cursor is within this wrapped segment
            chars_before_cursor = @cursor_col - counter
            segment_before = wrapped_line[0...chars_before_cursor]
            return LineInfo.new(
              width: wrapped_line.size,
              char_width: display_width(wrapped_line.join),
              height: grid.size,
              start_column: counter,
              column_offset: chars_before_cursor,
              row_offset: i,
              char_offset: display_width(segment_before.join)
            )
          end

          counter += wrapped_line.size
        end

        # Cursor at end of last wrapped segment
        if grid.empty?
          LineInfo.new(width: 0, char_width: 0, height: 0, start_column: 0, column_offset: 0, row_offset: 0, char_offset: 0)
        else
          last_line = grid.last
          LineInfo.new(
            width: last_line.size,
            char_width: display_width(last_line.join),
            height: grid.size,
            start_column: counter,
            column_offset: last_line.size,
            row_offset: grid.size - 1,
            char_offset: display_width(last_line.join)
          )
        end
      end

      # Moves the cursor by the given number of lines. Negative values move the cursor up,
      # positive values move the cursor down.
      def set_cursor_line_relative(delta : Int32)
        if delta == 0
          return
        end

        li = line_info
        char_offset = Math.max(@last_char_offset, li.char_offset)
        @last_char_offset = char_offset

        # 2 columns to account for the trailing space wrapping.
        trailing_space = 2

        if delta > 0
          # Moving down.
          delta.times do
            if li.row_offset + 1 >= li.height && @cursor_line < @value.size - 1
              @cursor_line += 1
              @cursor_col = 0
            else
              # Move the cursor to the start of the next virtual line.
              line_size = @value[@cursor_line].size
              @cursor_col = Math.min(li.start_column + li.width + trailing_space, line_size - 1)
            end
            li = line_info
          end
        else
          # Moving up.
          (-delta).times do
            if li.row_offset <= 0 && @cursor_line > 0
              @cursor_line -= 1
              line_size = @value[@cursor_line].size
              @cursor_col = line_size
            else
              # Move the cursor to the end of the previous line.
              @cursor_col = Math.max(li.start_column - trailing_space, 0)
            end
            li = line_info
          end
        end

        nli = line_info
        @cursor_col = nli.start_column

        if nli.width <= 0
          scroll_to_cursor
          return
        end

        offset = 0
        while offset < char_offset
          if @cursor_line >= @value.size
            break
          end
          line = @value[@cursor_line]
          if @cursor_col >= line.size || offset >= nli.char_width - 1
            break
          end
          offset += display_width(line[@cursor_col].to_s)
          @cursor_col += 1
        end
        scroll_to_cursor
      end

      private def cursor_line_number : Int32
        # Sum wrapped lines for rows before current row
        lines = @value.map(&.join)
        lines = [""] if lines.empty?

        total = 0
        available = [@width, 1].max

        # For rows before current cursor line
        @cursor_line.times do |i|
          line = lines[i]
          wrapped = memoized_wrap(line.chars.to_a, available)
          total += wrapped.size
        end

        # Add row offset within current line
        info = line_info
        total + info.row_offset
      end

      private def page_up
        cursor_line = cursor_line_number
        # If not on first visible line, snap to it
        offset = @viewport.y_offset - cursor_line
        if offset < 0
          # Move cursor up by offset lines (negative offset means cursor is below)
          set_cursor_line_relative(offset)
          return
        end

        # Already on first visible line, move up by a full page (height display lines)
        set_cursor_line_relative(-@height)
      end

      private def page_down
        cursor_line = cursor_line_number
        # If not on last visible line, snap to it
        offset = cursor_line - @viewport.y_offset
        if offset < @height - 1
          # Move cursor down to last visible line
          delta = @height - 1 - offset
          set_cursor_line_relative(delta)
          return
        end

        # Already on last visible line, move down by a full page
        set_cursor_line_relative(@height)
      end

      def update_viewport
        lines = @value.map(&.join)
        lines = [""] if lines.empty?

        rendered_lines = [] of String

        lines.each_with_index do |line, i|
          wrapped = memoized_wrap(line.chars.to_a, @width).map(&.join)

          wrapped.each_with_index do |wrapped_line, wl_idx|
            prompt = prompt_view(rendered_lines.size)
            line_number = ""
            if @show_line_numbers
              number = wl_idx == 0 ? i + 1 : 0
              line_number = line_number_view(number, i == @cursor_line)
            end

            padding = @width - Lipgloss::Text.width(wrapped_line)
            padding = 0 if padding < 0

            rendered = prompt + line_number + wrapped_line + (" " * padding)
            rendered_lines << rendered
          end
        end

        # Add End of Buffer markers for empty space
        visible_lines = rendered_lines.size
        if visible_lines < @height
          (visible_lines...@height).each do
            prompt = prompt_view(rendered_lines.size)
            rendered_lines << prompt + @end_of_buffer_char
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

      private def wrap_runes(runes : Array(Char), width : Int32) : Array(Array(Char))
        wrap_line(runes.join, width).map(&.chars.to_a)
      end

      private def memoized_wrap(runes : Array(Char), width : Int32) : Array(Array(Char))
        line = Line.new(runes, width)
        cached, hit = @cache.get(line)
        if hit
          return cached.not_nil!
        end
        wrapped = wrap_runes(runes, width)
        @cache.set(line, wrapped)
        wrapped
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
        if @value.all?(&.empty?) && !@placeholder.empty?
          @viewport.content = placeholder_lines.join("\n")
        else
          update_viewport
        end

        content = active_style.base.render(@viewport.view.content)
        View.new(content: content)
      end

      private def string_to_lines(s : String) : Array(Array(Char))
        lines = s.split('\n')
        lines = [""] if lines.empty?
        lines.map(&.chars.to_a)
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
        line_number_width = @show_line_numbers ? num_digits(@max_height) + 2 : 0
        line_number_width + @prompt_width
      end

      private def num_digits(value : Int32) : Int32
        v = value.abs
        return 1 if v == 0
        v.to_s.size
      end

      private def prompt_view(display_line : Int32) : String
        prompt = @prompt
        width = Lipgloss::Text.width(prompt)
        if @prompt_width > width
          prompt = (" " * (@prompt_width - width)) + prompt
        end
        prompt
      end

      private def line_number_view(n : Int32, is_cursor_line : Bool) : String
        return "" unless @show_line_numbers

        str = n <= 0 ? " " : n.to_s
        digits = num_digits(@max_height)
        sprintf(" %*s ", digits, str)
      end

      private def placeholder_lines : Array(String)
        wrapped = Cellwrap.wrap(@placeholder, @width)
        plines = wrapped.strip.split("\n")

        rendered = [] of String
        @height.times do |i|
          prompt = prompt_view(i)
          line_number = ""

          if @show_line_numbers
            ln = 0
            if i == 0
              ln = 1
            end
            if plines.size > i
              line_number = line_number_view(ln, plines.size > i)
            end
          end

          if i == 0
            line_text = plines[0]? || ""
            gap = @width - Lipgloss::Text.width(line_text)
            gap = 0 if gap < 0
            rendered << prompt + line_number + line_text + (" " * gap)
          elsif plines.size > i
            line_text = plines[i]
            gap = @width - Lipgloss::Text.width(line_text)
            gap = 0 if gap < 0
            rendered << prompt + line_number + line_text + (" " * gap)
          else
            rendered << prompt + @end_of_buffer_char
          end
        end

        rendered
      end
    end
  end
end
