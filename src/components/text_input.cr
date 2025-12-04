require "../term2"
require "./cursor"
require "./key"

module Term2
  module Components
    class TextInput
      include Model

      enum EchoMode
        Normal
        Password
        None
      end

      property value : String = ""
      property placeholder : String = ""
      property cursor_pos : Int32 = 0
      property width : Int32 = 40
      property prompt : String = "> "
      property echo_mode : EchoMode = EchoMode::Normal
      property char_limit : Int32 = 0 # 0 means no limit
      property id : String = ""       # Zone ID for focus management

      # Suggestions
      property? show_suggestions : Bool = false
      property suggestions : Array(String) = [] of String
      @matched_suggestions : Array(String) = [] of String
      @suggestion_index : Int32 = -1

      # Optional validator; returns true if valid, false otherwise.
      property validate : Proc(String, Bool)? = nil

      # Styling
      property prompt_style : Style = Style.new
      property text_style : Style = Style.new
      property placeholder_style : Style = Style.new.faint(true)
      property completion_style : Style = Style.new.faint(true)

      # Components
      property cursor : Cursor

      # Key bindings
      property key_map : KeyMap

      struct KeyMap
        getter character_forward : Key::Binding
        getter character_backward : Key::Binding
        getter word_forward : Key::Binding
        getter word_backward : Key::Binding
        getter delete_after_cursor : Key::Binding
        getter delete_before_cursor : Key::Binding
        getter delete_character_backward : Key::Binding
        getter delete_character_forward : Key::Binding
        getter line_start : Key::Binding
        getter line_end : Key::Binding
        getter paste : Key::Binding

        def initialize
          @character_forward = Key::Binding.new(["right", "ctrl+f"], "right", "character forward")
          @character_backward = Key::Binding.new(["left", "ctrl+b"], "left", "character backward")
          @word_forward = Key::Binding.new(["alt+right", "alt+f"], "alt+right", "word forward")
          @word_backward = Key::Binding.new(["alt+left", "alt+b"], "alt+left", "word backward")
          @delete_after_cursor = Key::Binding.new(["ctrl+k"], "ctrl+k", "delete after cursor")
          @delete_before_cursor = Key::Binding.new(["ctrl+u"], "ctrl+u", "delete before cursor")
          @delete_character_backward = Key::Binding.new(["backspace", "ctrl+h"], "backspace", "delete character backward")
          @delete_character_forward = Key::Binding.new(["delete", "ctrl+d"], "delete", "delete character forward")
          @line_start = Key::Binding.new(["home", "ctrl+a"], "home", "line start")
          @line_end = Key::Binding.new(["end", "ctrl+e"], "end", "line end")
          @paste = Key::Binding.new(["ctrl+v"], "paste", "paste")
        end
      end

      def initialize(@id : String = "")
        @cursor = Cursor.new
        @key_map = KeyMap.new
      end

      # Zone ID for focus management
      def zone_id : String?
        @id.empty? ? nil : @id
      end

      def focus : Cmd
        Zone.focus(@id) unless @id.empty?
        @cursor.focus_cmd
      end

      # Start cursor blinking (parity helper)
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

      def update(msg : Msg) : {TextInput, Cmd}
        # Handle cursor blink
        new_cursor, cmd = @cursor.update(msg)
        @cursor = new_cursor

        case msg
        when ZoneClickMsg
          # Focus this input when clicked
          if msg.id == @id
            return {self, focus}
          end
        when ZoneFocusMsg
          # Focus this input when tab-focused
          if msg.zone_id == @id
            return {self, focus}
          end
        when KeyMsg
          if focused?
            handle_key(msg)
          else
            handle_suggestion_keys(msg)
          end
        end

        {self, cmd}
      end

      def handle_key(msg : KeyMsg)
        case
        when @key_map.character_forward.matches?(msg)
          move_cursor(1)
        when @key_map.character_backward.matches?(msg)
          move_cursor(-1)
        when @key_map.line_start.matches?(msg)
          cursor_start
        when @key_map.line_end.matches?(msg)
          cursor_end
        when @key_map.delete_character_backward.matches?(msg)
          delete_before_cursor
        when @key_map.delete_character_forward.matches?(msg)
          delete_after_cursor
        when @key_map.delete_before_cursor.matches?(msg)
          delete_line_before_cursor
        when @key_map.delete_after_cursor.matches?(msg)
          delete_line_after_cursor
        when msg.key.to_s == "tab" && @show_suggestions
          accept_current_suggestion
        when msg.key.to_s == "ctrl+n" && @show_suggestions
          next_suggestion
        when msg.key.to_s == "ctrl+p" && @show_suggestions
          prev_suggestion
        else
          # Insert character - handle both Runes and Space
          if msg.key.type == KeyType::Runes && !msg.key.alt?
            insert_string(msg.key.to_s)
          elsif msg.key.type == KeyType::Space
            insert_string(" ")
          end
        end
      end

      private def handle_suggestion_keys(msg : KeyMsg)
        return unless @show_suggestions
        case msg.key.to_s
        when "tab"    then accept_current_suggestion
        when "ctrl+n" then next_suggestion
        when "ctrl+p" then prev_suggestion
        end
      end

      def move_cursor(delta : Int32)
        @cursor_pos = (@cursor_pos + delta).clamp(0, @value.size)
      end

      def cursor_start
        @cursor_pos = 0
      end

      def cursor_end
        @cursor_pos = @value.size
      end

      def insert_string(s : String)
        return if @char_limit > 0 && @value.size + s.size > @char_limit

        left = @value[0...@cursor_pos]
        right = @value[@cursor_pos..-1]
        candidate = left + s + right
        return unless valid_input?(candidate)

        @value = candidate
        @cursor_pos += s.size
        update_suggestions
      end

      def value=(val : String)
        if @char_limit > 0 && val.size > @char_limit
          @value = val[0, @char_limit]
        else
          @value = valid_input?(val) ? val : @value
        end
        @cursor_pos = @value.size
        update_suggestions
      end

      def delete_before_cursor
        return if @cursor_pos == 0

        left = @value[0...(@cursor_pos - 1)]
        right = @value[@cursor_pos..-1]
        @value = left + right
        @cursor_pos -= 1
        update_suggestions
      end

      def delete_after_cursor
        return if @cursor_pos >= @value.size

        left = @value[0...@cursor_pos]
        right = @value[(@cursor_pos + 1)..-1]
        @value = left + right
        update_suggestions
      end

      def delete_line_before_cursor
        @value = @value[@cursor_pos..-1]
        @cursor_pos = 0
        update_suggestions
      end

      def delete_line_after_cursor
        @value = @value[0...@cursor_pos]
        update_suggestions
      end

      def view : String
        val = rendered_value

        content = if !focused? && val.empty? && !@placeholder.empty?
                    available = available_width
                    placeholder = truncate_with_ellipsis(@placeholder, available)
                    @prompt_style.render(@prompt) + @placeholder_style.render(placeholder)
                  else
                    render_value(val)
                  end

        content = pad_to_width(content)
        @id.empty? ? content : Zone.mark(@id, content)
      end

      # Suggestions API (parity with Bubbles tests)
      def set_suggestions(list : Array(String))
        @suggestions = list
        update_suggestions
      end

      def update_suggestions
        return reset_suggestions unless @show_suggestions
        return reset_suggestions if @value.empty? || @suggestions.empty?

        prefix = @value.downcase
        @matched_suggestions = @suggestions.select(&.downcase.starts_with?(prefix))
        @suggestion_index = @matched_suggestions.empty? ? -1 : 0
      end

      private def reset_suggestions
        @matched_suggestions = [] of String
        @suggestion_index = -1
      end

      private def valid_input?(val : String) : Bool
        return true unless validator = @validate
        !!validator.call(val)
      end

      def next_suggestion
        return if @matched_suggestions.empty?
        @suggestion_index = (@suggestion_index + 1) % @matched_suggestions.size
      end

      def prev_suggestion
        return if @matched_suggestions.empty?
        size = @matched_suggestions.size
        @suggestion_index = (@suggestion_index - 1 + size) % size
      end

      def accept_current_suggestion
        suggestion = current_suggestion
        return if suggestion.empty?
        self.value = suggestion
        update_suggestions
        cursor_end
      end

      def current_suggestion : String
        return "" if @matched_suggestions.empty? || @suggestion_index < 0
        @matched_suggestions[@suggestion_index]
      end

      private def render_value(val : String) : String
        display = val
        if @echo_mode == EchoMode::Password
          display = "*" * @value.size
        elsif @echo_mode == EchoMode::None
          display = ""
        end

        cursor_char = " "
        if @cursor_pos < display.size
          cursor_char = display[@cursor_pos].to_s
        end

        suggestion_tail = ""
        if focused? && @show_suggestions
          if suggestion = current_suggestion.presence
            if suggestion.size > @value.size
              suggestion_tail = suggestion[@value.size..-1]
              cursor_char = suggestion[@value.size, 1] if @cursor_pos == display.size
            end
          end
        end

        @cursor.char = cursor_char

        left = display[0...@cursor_pos]
        right = ""
        if @cursor_pos < display.size
          right = display[(@cursor_pos + 1)..-1]
        end

        String.build do |str|
          str << @prompt_style.render(@prompt)
          str << @text_style.render(left)
          str << @cursor.view
          str << @text_style.render(right)
          unless suggestion_tail.empty?
            str << @completion_style.render(suggestion_tail)
          end
        end
      end

      private def rendered_value : String
        @value
      end

      private def available_width : Int32
        [@width - Term2::Text.width(@prompt), 0].max
      end

      private def truncate_with_ellipsis(text : String, width : Int32) : String
        return "" if width <= 0
        return text if Term2::Text.width(text) <= width
        truncated = Term2::Text.truncate(text, width - 1)
        truncated + "…"
      end

      private def pad_to_width(str : String) : String
        return str if @width <= 0
        w = Term2::Text.width(str)
        if w < @width
          str + (" " * (@width - w))
        else
          Term2::Text.truncate(str, @width)
        end
      end
    end
  end
end
