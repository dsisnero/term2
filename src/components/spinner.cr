require "../term2"

module Term2
  module Components
    class Spinner < Model
      struct Type
        getter frames : Array(String)
        getter fps : Time::Span

        def initialize(@frames, @fps)
        end
      end

      # Standard types
      LINE     = Type.new(["|", "/", "-", "\\"], 100.milliseconds)
      DOT      = Type.new(["⣾ ", "⣽ ", "⣻ ", "⢿ ", "⡿ ", "⣟ ", "⣯ ", "⣷ "], 100.milliseconds)
      MINI_DOT = Type.new(["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"], 80.milliseconds)
      JUMP     = Type.new(["⢄", "⢂", "⢁", "⡁", "⡈", "⡐", "⡠"], 100.milliseconds)
      PULSE    = Type.new(["█", "▓", "▒", "░"], 125.milliseconds)
      POINTS   = Type.new(["∙∙∙", "●∙∙", "∙●∙", "∙∙●"], 140.milliseconds)
      GLOBE    = Type.new(["🌍", "🌎", "🌏"], 250.milliseconds)
      MOON     = Type.new(["🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘"], 125.milliseconds)
      MONKEY   = Type.new(["🙈", "🙉", "🙊"], 333.milliseconds)
      METER    = Type.new([
        "▱▱▱",
        "▰▱▱",
        "▰▰▱",
        "▰▰▰",
        "▰▰▱",
        "▰▱▱",
        "▱▱▱",
      ], 140.milliseconds)
      HAMBURGER = Type.new(["☱", "☲", "☴", "☲"], 333.milliseconds)
      ELLIPSIS  = Type.new(["", ".", "..", "..."], 333.milliseconds)

      property type : Type
      property style : Style = Style.new
      property frame_index : Int32 = 0

      getter id : Int32
      @tag : Int32 = 0 # For tick validation

      def initialize(@type : Type = LINE)
        @id = Random.rand(Int32)
      end

      class TickMsg < Message
        getter id : Int32
        getter tag : Int32
        getter time : Time

        def initialize(@id, @tag, @time)
        end
      end

      def update(msg : Message) : {Spinner, Cmd}
        case msg
        when TickMsg
          if msg.id == @id && msg.tag == @tag
            @frame_index = (@frame_index + 1) % @type.frames.size
            return {self, tick}
          end
        end
        {self, Cmd.none}
      end

      def tick : Cmd
        id = @id
        tag = @tag
        Cmd.tick(@type.fps) do |time|
          TickMsg.new(id, tag, time)
        end
      end

      def view : String
        @style.apply(@type.frames[@frame_index])
      end
    end
  end
end
