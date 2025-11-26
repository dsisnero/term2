require "../term2"

module Term2
  module Components
    class Progress < Model
      property percent : Float64 = 0.0
      property width : Int32 = 40
      property full_char : Char = '█'
      property empty_char : Char = '░'
      property? show_percentage : Bool = true

      # Styles
      property full_style : Style = Style.new(foreground: Color::GREEN)
      property empty_style : Style = Style.new(foreground: Color::BLACK)

      def initialize(@width : Int32 = 30)
      end

      class SetPercentMsg < Message
        getter value : Float64

        def initialize(@value : Float64)
        end
      end

      class IncrementMsg < Message
        getter delta : Float64

        def initialize(@delta : Float64)
        end
      end

      def update(msg : Message) : {Progress, Cmd}
        case msg
        when SetPercentMsg
          @percent = msg.value.clamp(0.0, 1.0)
        when IncrementMsg
          @percent = (@percent + msg.delta).clamp(0.0, 1.0)
        end
        {self, Cmd.none}
      end

      def view : String
        pct_str = ""
        if @show_percentage
          pct_str = sprintf(" %.0f%%", @percent * 100)
        end

        bar_width = @width - pct_str.size
        return "" if bar_width < 0

        filled_width = (@percent * bar_width).round.to_i
        empty_width = bar_width - filled_width

        String.build do |str|
          str << @full_style.apply(@full_char.to_s * filled_width)
          str << @empty_style.apply(@empty_char.to_s * empty_width)
          str << pct_str if @show_percentage
        end
      end

      # Helper to set percent directly
      def percent_cmd(p : Float64) : Cmd
        Cmd.message(SetPercentMsg.new(p))
      end

      def incr_percent(delta : Float64) : Cmd
        Cmd.message(IncrementMsg.new(delta))
      end
    end
  end
end
