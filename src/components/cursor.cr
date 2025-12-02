require "../term2"

module Term2
  module Components
    class Cursor
      include Model

      enum Mode
        Blink
        Static
        Hide
      end

      property blink_speed : Time::Span = 530.milliseconds
      property style : Style = Style.new.reverse(true) # Default to reverse video
      property text_style : Style = Style.new
      property char : String = " "
      property? focus : Bool = false
      property? blink : Bool = true # Current visibility state (true = visible)
      property mode : Mode = Mode::Blink

      # Internal for blink management
      @blink_tag : Int32 = 0

      def initialize
      end

      class BlinkMsg < Message
        getter tag : Int32

        def initialize(@tag : Int32)
        end
      end

      def update(msg : Msg) : {Cursor, Cmd}
        case msg
        when BlinkMsg
          if @mode == Mode::Blink && @focus && msg.tag == @blink_tag
            @blink = !@blink
            return {self, blink_cmd}
          end
        end
        {self, Cmds.none}
      end

      def blink_cmd : Cmd
        tag = @blink_tag
        Cmds.tick(@blink_speed) do
          BlinkMsg.new(tag)
        end
      end

      # Start blinking/focus
      def focus_cmd : Cmd
        @focus = true
        @blink = true
        @blink_tag += 1
        if @mode == Mode::Blink
          blink_cmd
        else
          Cmds.none
        end
      end

      # Stop blinking/blur
      def blur
        @focus = false
        @blink = true
        @blink_tag += 1 # Invalidate pending blink messages
      end

      def char=(char : String)
        @char = char
      end

      def mode=(mode : Mode)
        @mode = mode
        @blink = true
        if @focus && @mode == Mode::Blink
          # Restart blinking?
          @blink_tag += 1
        end
      end

      def view : String
        if @mode == Mode::Hide || !@focus || (@mode == Mode::Blink && !@blink)
          # Render text normally
          @text_style.render(@char)
        else
          # Render cursor block
          @style.render(@char)
        end
      end
    end
  end
end
