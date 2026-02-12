require "../../../src/term2"

module CursorStyleExample
  include Term2::Prelude

  class Model
    include Term2::Model

    @shape : Term2::CursorShape = Term2::CursorShape::Block
    @blink : Bool = true

    def init : Term2::Cmd
      Term2::Cmds.none
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::KeyMsg
        case msg.string
        when "ctrl+c", "q"
          return {self, Term2.quit}
        when "h", "left"
          @shape = prev_shape(@shape)
        when "l", "right"
          @shape = next_shape(@shape)
        end
      end

      @blink = !@blink
      {self, Term2::Cmds.none}
    end

    def view : Term2::View
      content = "Press left/right to change the cursor style, q or ctrl+c to quit." +
                "\n\n" +
                "  <- This is the cursor (a #{describe_cursor})"

      cursor = Term2::Cursor.new(0, 2)
      cursor.shape = @shape
      cursor.blink = @blink
      Term2::View.new(content: content, cursor: cursor)
    end

    private def describe_cursor : String
      adj = @blink ? "blinking" : "steady"
      noun = case @shape
             when Term2::CursorShape::Block
               "block"
             when Term2::CursorShape::Underline
               "underline"
             when Term2::CursorShape::Bar
               "bar"
             else
               "block"
             end
      "#{adj} #{noun}"
    end

    private def prev_shape(shape : Term2::CursorShape) : Term2::CursorShape
      case shape
      when Term2::CursorShape::Block
        Term2::CursorShape::Bar
      when Term2::CursorShape::Underline
        Term2::CursorShape::Block
      when Term2::CursorShape::Bar
        Term2::CursorShape::Underline
      else
        Term2::CursorShape::Block
      end
    end

    private def next_shape(shape : Term2::CursorShape) : Term2::CursorShape
      case shape
      when Term2::CursorShape::Block
        Term2::CursorShape::Underline
      when Term2::CursorShape::Underline
        Term2::CursorShape::Bar
      when Term2::CursorShape::Bar
        Term2::CursorShape::Block
      else
        Term2::CursorShape::Block
      end
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(CursorStyleExample::Model.new)
end
