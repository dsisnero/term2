require "../term2"
require "./cursor"
require "./key"

module Term2
  module Components
    class TextInput < Model
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

      # Styling
      property prompt_style : Style = Style.new
      property text_style : Style = Style.new
      property placeholder_style : Style = Style.new(faint: true)

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

      def initialize
        @cursor = Cursor.new
        @key_map = KeyMap.new
      end

      def focus : Cmd
        @cursor.focus_cmd
      end

      def blur
        @cursor.blur
      end

      def focused?
        @cursor.focus?
      end

      def update(msg : Message) : {TextInput, Cmd}
        # Handle cursor blink
        new_cursor, cmd = @cursor.update(msg)
        @cursor = new_cursor

        case msg
        when KeyMsg
          if focused?
            handle_key(msg)
          end
        end

        {self, cmd}
      end

      def handle_key(msg : KeyMsg)
        if handle_navigation_key(msg)
          return
        elsif handle_deletion_key(msg)
          return
        else
          handle_insertion_key(msg)
        end
      end

      private def handle_navigation_key(msg : KeyMsg) : Bool
        case
        when @key_map.character_forward.matches?(msg)
          move_cursor(1)
          true
        when @key_map.character_backward.matches?(msg)
          move_cursor(-1)
          true
        when @key_map.line_start.matches?(msg)
          cursor_start
          true
        when @key_map.line_end.matches?(msg)
          cursor_end
          true
        else
          false
        end
      end

      private def handle_deletion_key(msg : KeyMsg) : Bool
        case
        when @key_map.delete_character_backward.matches?(msg)
          delete_before_cursor
          true
        when @key_map.delete_character_forward.matches?(msg)
          delete_after_cursor
          true
        when @key_map.delete_before_cursor.matches?(msg)
          delete_line_before_cursor
          true
        when @key_map.delete_after_cursor.matches?(msg)
          delete_line_after_cursor
          true
        else
          false
        end
      end

      private def handle_insertion_key(msg : KeyMsg)
        if msg.key.type == KeyType::Runes && !msg.key.alt?
          insert_string(msg.key.to_s)
        elsif msg.key.type == KeyType::Space && !msg.key.alt?
          insert_string(" ")
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
        @value = left + s + right
        @cursor_pos += s.size
      end

      def delete_before_cursor
        return if @cursor_pos == 0

        left = @value[0...(@cursor_pos - 1)]
        right = @value[@cursor_pos..-1]
        @value = left + right
        @cursor_pos -= 1
      end

      def delete_after_cursor
        return if @cursor_pos >= @value.size

        left = @value[0...@cursor_pos]
        right = @value[(@cursor_pos + 1)..-1]
        @value = left + right
      end

      def delete_line_before_cursor
        @value = @value[@cursor_pos..-1]
        @cursor_pos = 0
      end

      def delete_line_after_cursor
        @value = @value[0...@cursor_pos]
      end

      def view : String
        # Construct the view
        # Prompt + Value (with cursor)

        val = @value
        if @echo_mode == EchoMode::Password
          val = "*" * @value.size
        elsif @echo_mode == EchoMode::None
          val = ""
        end

        if !focused? && val.empty? && !@placeholder.empty?
          return "#{@prompt_style.apply(@prompt)}#{@placeholder_style.apply(@placeholder)}"
        end

        # Cursor handling
        # We need to split val at cursor_pos

        cursor_char = " "
        if @cursor_pos < val.size
          cursor_char = val[@cursor_pos].to_s
        end

        # Update cursor component char
        @cursor.char = cursor_char

        left = val[0...@cursor_pos]
        right = ""
        if @cursor_pos < val.size
          right = val[(@cursor_pos + 1)..-1]
        end

        # Render
        String.build do |str|
          str << @prompt_style.apply(@prompt)
          str << @text_style.apply(left)
          str << @cursor.view
          str << @text_style.apply(right)
        end
      end
    end
  end
end
