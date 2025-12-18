require "../term2"
require "./cursor"
require "./key"

module Term2
  module Components
    class TextInput
      include Term2::Model

      # EchoMode sets the input behavior of the text input field.
      enum EchoMode
        Normal   # Displays text as is
        Password # Displays EchoCharacter mask
        None     # Displays nothing
      end

      # KeyMap is the key bindings for different actions within the textinput.
      class KeyMap
        property character_forward : Key::Binding
        property character_backward : Key::Binding
        property word_forward : Key::Binding
        property word_backward : Key::Binding
        property delete_word_backward : Key::Binding
        property delete_word_forward : Key::Binding
        property delete_after_cursor : Key::Binding
        property delete_before_cursor : Key::Binding
        property delete_character_backward : Key::Binding
        property delete_character_forward : Key::Binding
        property line_start : Key::Binding
        property line_end : Key::Binding
        property paste : Key::Binding
        property accept_suggestion : Key::Binding
        property next_suggestion : Key::Binding
        property prev_suggestion : Key::Binding

        def initialize
          @character_forward = Key::Binding.new(["right", "ctrl+f"], "", "")
          @character_backward = Key::Binding.new(["left", "ctrl+b"], "", "")
          @word_forward = Key::Binding.new(["alt+right", "ctrl+right", "alt+f"], "", "")
          @word_backward = Key::Binding.new(["alt+left", "ctrl+left", "alt+b"], "", "")
          @delete_word_backward = Key::Binding.new(["alt+backspace", "ctrl+w"], "", "")
          @delete_word_forward = Key::Binding.new(["alt+delete", "alt+d"], "", "")
          @delete_after_cursor = Key::Binding.new(["ctrl+k"], "", "")
          @delete_before_cursor = Key::Binding.new(["ctrl+u"], "", "")
          @delete_character_backward = Key::Binding.new(["backspace", "ctrl+h"], "", "")
          @delete_character_forward = Key::Binding.new(["delete", "ctrl+d"], "", "")
          @line_start = Key::Binding.new(["home", "ctrl+a"], "", "")
          @line_end = Key::Binding.new(["end", "ctrl+e"], "", "")
          @paste = Key::Binding.new(["ctrl+v"], "", "")
          @accept_suggestion = Key::Binding.new(["tab"], "", "")
          @next_suggestion = Key::Binding.new(["down", "ctrl+n"], "", "")
          @prev_suggestion = Key::Binding.new(["up", "ctrl+p"], "", "")
        end
      end

      # General settings
      property prompt : String = "> "
      property placeholder : String = ""
      property echo_mode : EchoMode = EchoMode::Normal
      property echo_character : Char = '*'
      property cursor : Cursor = Cursor.new

      # Styles
      property prompt_style : Style = Style.new
      property text_style : Style = Style.new
      property placeholder_style : Style = Style.new.foreground(Term2::Color.indexed(240))
      property completion_style : Style = Style.new.foreground(Term2::Color.indexed(240))
      property cursor_style : Style = Style.new

      # Limits
      property char_limit : Int32 = 0
      property width : Int32 = 0

      # State
      property key_map : KeyMap = KeyMap.new
      getter value : String = ""
      getter pos : Int32 = 0

      property show_suggestions : Bool = false

      # Internal state
      @focus : Bool = false
      @offset : Int32 = 0
      @offset_right : Int32 = 0
      @err : Exception? = nil
      @suggestions : Array(String) = [] of String
      @matched_suggestions : Array(String) = [] of String
      @current_suggestion_index : Int32 = 0

      # Validate function
      property validate : (String -> Exception?)? = nil
      getter err : Exception? = nil

      # [NEW] Blink command factory
      # Use this to start the cursor blinking.
      def self.blink : Cmd
        Cursor.blink
      end

      def blink : Cmd
        @cursor.blink_cmd
      end

      def initialize
      end

      # Compatibility constructor: TextInput IDs are handled by Zone in some ports.
      def self.new(id : String)
        new
      end

      def init : Cmd
        nil
      end

      # SetValue sets the value of the text input.
      def set_value(s : String)
        runes = sanitize(s)
        if @char_limit > 0 && runes.size > @char_limit
          runes = runes[0, @char_limit]
        end
        @value = runes
        if (@pos == 0 && @value.empty?) || @pos > @value.size
          set_cursor(@value.size)
        end
        handle_overflow
        run_validate
      end

      # Helper for property setter syntax
      def value=(s : String)
        set_value(s)
      end

      def position
        @pos
      end

      def cursor_pos : Int32
        @pos
      end

      def cursor_pos=(pos : Int32)
        set_cursor(pos)
      end

      def set_cursor(pos : Int32)
        @pos = pos.clamp(0, @value.size)
        handle_overflow
      end

      def cursor_start
        set_cursor(0)
      end

      def cursor_end
        set_cursor(@value.size)
      end

      def focused? : Bool
        @focus
      end

      def focus : Cmd
        @focus = true
        @cursor.focus
      end

      def blur
        @focus = false
        @cursor.blur
      end

      def reset
        @value = ""
        set_cursor(0)
      end

      def set_suggestions(suggestions : Array(String))
        @suggestions = suggestions
        update_suggestions
      end

      def suggestions=(s : Array(String))
        set_suggestions(s)
      end

      def available_suggestions : Array(String)
        @suggestions
      end

      def matched_suggestions : Array(String)
        @matched_suggestions
      end

      def current_suggestion : String
        return "" if @matched_suggestions.empty?
        return "" if @current_suggestion_index >= @matched_suggestions.size
        @matched_suggestions[@current_suggestion_index]
      end

      def update(msg : Msg) : {self, Cmd}
        return {self, nil} unless @focus

        # Check for suggestion acceptance first (tab)
        if msg.is_a?(KeyMsg) && @key_map.accept_suggestion.matches?(msg)
          if can_accept_suggestion?
            suggestion = @matched_suggestions[@current_suggestion_index]
            # Append the rest of the suggestion
            if suggestion.size > @value.size
              suffix = suggestion[@value.size..-1]
              set_value(@value + suffix)
              cursor_end
            end
            return {self, nil}
          end
        end

        old_pos = @pos
        cmd : Cmd = nil

        case msg
        when KeyMsg
          # Match key bindings
          if @key_map.character_forward.matches?(msg)
            set_cursor(@pos + 1) if @pos < @value.size
          elsif @key_map.character_backward.matches?(msg)
            set_cursor(@pos - 1) if @pos > 0
          elsif @key_map.line_start.matches?(msg)
            cursor_start
          elsif @key_map.line_end.matches?(msg)
            cursor_end
          elsif @key_map.delete_character_backward.matches?(msg)
            if @value.size > 0 && @pos > 0
              # Remove char before cursor
              head = @value[0...@pos - 1]
              tail = @value[@pos..-1]
              @value = head + tail
              set_cursor(@pos - 1)
            end
          elsif @key_map.delete_character_forward.matches?(msg)
            if @value.size > 0 && @pos < @value.size
              head = @value[0...@pos]
              tail = @value[@pos + 1..-1]
              @value = head + tail
            end
          elsif @key_map.next_suggestion.matches?(msg)
            next_suggestion
          elsif @key_map.prev_suggestion.matches?(msg)
            prev_suggestion
            # Explicitly check for Runes type to insert text
          elsif msg.key.type == Term2::KeyType::Runes && msg.key.runes.any?
            insert_runes(msg.key.runes)
          end

          update_suggestions
        end

        new_cursor, cursor_cmd = @cursor.update(msg)
        @cursor = new_cursor.as(Cursor) # Cast because cursor update returns model

        # Reset blink if cursor moved
        if old_pos != @pos && @cursor.mode == Cursor::Mode::Blink
          @cursor.blink = false
        end

        handle_overflow
        run_validate

        {self, cursor_cmd}
      end

      private def run_validate : Nil
        if validator = @validate
          @err = validator.call(@value)
        else
          @err = nil
        end
      end

      def view : String
        # Placeholder
        if @value.empty? && !@placeholder.empty?
          return placeholder_view
        end

        # Current viewable window
        visible_value = @value[@offset...@offset_right]
        cursor_pos = (@pos - @offset).clamp(0, visible_value.size)

        pre_cursor = visible_value[0...cursor_pos]

        # Determine char under cursor
        char_under = if cursor_pos < visible_value.size
                       visible_value[cursor_pos]
                     else
                       ' '
                     end

        post_cursor = if cursor_pos + 1 < visible_value.size
                        visible_value[cursor_pos + 1..-1]
                      else
                        ""
                      end

        # Apply Echo transformation
        pre_cursor = echo_transform(pre_cursor)
        char_under_str = echo_transform(char_under.to_s)
        post_cursor = echo_transform(post_cursor)

        # Style text
        v = @text_style.render(pre_cursor)

        # Render Cursor
        @cursor.char = char_under_str
        # Check suggestions overlay
        if @focus && can_accept_suggestion? && cursor_pos >= visible_value.size
          suggestion = @matched_suggestions[@current_suggestion_index]
          if suggestion.size > @value.size
            # Show ghost text
            completion_char = suggestion[@value.size]
            @cursor.text_style = @completion_style
            @cursor.char = completion_char.to_s

            rest_completion = suggestion[@value.size + 1..-1]
            cursor_view = @cursor.view
            return @prompt_style.render(@prompt) + v + cursor_view + @completion_style.render(rest_completion)
          end
        end

        v += @cursor.view
        v += @text_style.render(post_cursor)

        visible_width = Term2::Text.width(echo_transform(visible_value))
        if @width > 0 && visible_width <= @width
          padding = (@width - visible_width).clamp(0, Int32::MAX)
          if visible_width + padding <= @width && cursor_pos < visible_value.size
            padding += 1
          end
          v += @text_style.render(" " * padding)
        end

        @prompt_style.render(@prompt) + v
      end

      private def placeholder_view : String
        p = @prompt_style.render(@prompt)

        first = ""
        rest = String.build do |io|
          i = 0
          @placeholder.each_grapheme do |g|
            if i == 0
              first = g.to_s
            else
              io << g
            end
            i += 1
          end
        end

        v = ""
        @cursor.text_style = @placeholder_style
        @cursor.char = first
        v += @cursor.view

        if @width > 0
          available = @width - Term2::Text.width(p) - Term2::Text.width(v)
          available = [available, 0].max
          placeholder_rest = Term2::StyleTable.truncate(rest, available, "…")
          pad = [available - Term2::Text.width(placeholder_rest), 0].max
          v += @placeholder_style.render(placeholder_rest) + (" " * pad)
        else
          v += @placeholder_style.render(rest)
        end

        p + v
      end

      private def sanitize(s : String) : String
        # Replace newlines and tabs with spaces for single-line input
        s.gsub("\n", " ").gsub("\t", " ")
      end

      private def insert_runes(runes : Array(Char))
        to_insert = runes.join

        # Handle char limit
        if @char_limit > 0
          avail = @char_limit - @value.size
          return if avail <= 0
          if avail < to_insert.size
            to_insert = to_insert[0, avail]
          end
        end

        head = @value[0...@pos]
        tail = @value[@pos..-1]

        @value = head + to_insert + tail
        @pos += to_insert.size
      end

      private def handle_overflow
        if @width <= 0
          @offset = 0
          @offset_right = @value.size
          return
        end

        # Simple viewport logic (simplified from Go for now)
        # Ensure cursor is visible
        if @pos < @offset
          @offset = @pos
        end

        # If cursor is past the right edge
        if @pos >= @offset + @width
          @offset = @pos - @width + 1
        end

        @offset_right = Math.min(@offset + @width, @value.size)

        # If we have space on the right, pull offset back
        if @offset_right == @value.size && @value.size - @offset < @width
          @offset = Math.max(0, @value.size - @width)
        end

        @offset_right = Math.min(@offset + @width, @value.size)
        # Ensure we show at least the cursor position if at end
        if @pos == @value.size
          # Allow offset_right to go one past for cursor rendering
          @offset_right = @pos
        end
      end

      private def echo_transform(s : String) : String
        case @echo_mode
        when EchoMode::Password
          @echo_character.to_s * s.size
        when EchoMode::None
          ""
        else
          s
        end
      end

      def update_suggestions
        return unless @show_suggestions
        if @value.empty? || @suggestions.empty?
          @matched_suggestions = [] of String
          @current_suggestion_index = 0
          return
        end

        val_lower = @value.downcase
        @matched_suggestions = @suggestions.select do |s|
          s.downcase.starts_with?(val_lower)
        end
        @current_suggestion_index = 0
      end

      private def can_accept_suggestion? : Bool
        !@matched_suggestions.empty?
      end

      # Accepts the current suggestion, appending the rest of the suggestion text
      # to the current value.
      def accept_current_suggestion
        return unless can_accept_suggestion?
        suggestion = @matched_suggestions[@current_suggestion_index]
        # Append the rest of the suggestion
        if suggestion.size > @value.size
          suffix = suggestion[@value.size..-1]
          @value += suffix
          set_cursor(@value.size)
        end
      end

      # Moves to the next suggestion in the list
      def next_suggestion
        return unless can_accept_suggestion?
        @current_suggestion_index += 1
        if @current_suggestion_index >= @matched_suggestions.size
          @current_suggestion_index = 0
        end
      end

      # Moves to the previous suggestion in the list
      def prev_suggestion
        return unless can_accept_suggestion?
        @current_suggestion_index -= 1
        if @current_suggestion_index < 0
          @current_suggestion_index = @matched_suggestions.size - 1
        end
      end
    end
  end
end
