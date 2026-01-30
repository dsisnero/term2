require "../term2"

module Term2
  module Components
    class Progress
      include Term2::Model

      # Configuration options
      alias Option = Proc(Progress, Nil)

      # --- Properties ---
      property width : Int32
      property full_char : Char
      property empty_char : Char
      property? show_percentage : Bool
      property percent_format : String

      # Styles
      property full_color : String
      property empty_color : String
      property percentage_style : Style

      # Animation state
      # `percent` is the target percent (Go: targetPercent).
      property percent : Float64
      property target_percent : Float64
      property velocity : Float64

      # Percent currently being rendered (Go: percentShown).
      property percent_shown : Float64

      # Gradient settings
      property? use_ramp : Bool
      property ramp_color_a : Color
      property ramp_color_b : Color
      property? scale_ramp : Bool

      # Compatibility alias used by some example ports.
      def use_gradient? : Bool
        use_ramp?
      end

      def use_gradient=(v : Bool) : Bool
        self.use_ramp = v
        v
      end

      # Animation constants
      FPS = 60.0

      # Internal ID to manage animation frames
      @id : Int32 = rand(10000)
      @tag : Int32 = 0

      def initialize(opts : Array(Option) = [] of Option, width : Int32 = 30, show_percentage : Bool = true)
        @width = width
        @full_char = '█'
        @empty_char = '░'
        @show_percentage = show_percentage
        @percent_format = "%3.0f%%"
        @full_color = "#7571F9"
        @empty_color = "#606060"
        @percentage_style = Style.new
        @percent = 0.0
        @percent_shown = 0.0
        @target_percent = 0.0
        @velocity = 0.0
        @use_ramp = false
        @ramp_color_a = Color.from_hex("#5A56E0")
        @ramp_color_b = Color.from_hex("#EE6FF8")
        @scale_ramp = false

        opts.each(&.call(self))
      end

      # --- Options ---

      def self.with_default_gradient : Option
        with_gradient("#5A56E0", "#EE6FF8")
      end

      def self.with_gradient(color_a : String, color_b : String) : Option
        ->(p : Progress) {
          p.use_ramp = true
          p.scale_ramp = false
          p.ramp_color_a = Color.from_hex(color_a)
          p.ramp_color_b = Color.from_hex(color_b)
          nil
        }
      end

      def self.with_scaled_gradient(color_a : String, color_b : String) : Option
        ->(p : Progress) {
          p.use_ramp = true
          p.scale_ramp = true
          p.ramp_color_a = Color.from_hex(color_a)
          p.ramp_color_b = Color.from_hex(color_b)
          nil
        }
      end

      def self.with_solid_fill(color : String) : Option
        ->(p : Progress) {
          p.full_color = color
          p.use_ramp = false
          nil
        }
      end

      def self.with_width(w : Int32) : Option
        ->(p : Progress) { p.width = w; nil }
      end

      def self.without_percentage : Option
        ->(p : Progress) { p.show_percentage = false; nil }
      end

      # --- Messages ---

      class FrameMsg < Message
        getter id : Int32
        getter tag : Int32

        def initialize(@id : Int32, @tag : Int32); end
      end

      class SetPercentMsg < Message
        getter value : Float64

        def initialize(@value : Float64); end
      end

      class IncrementMsg < Message
        getter delta : Float64

        def initialize(@delta : Float64); end
      end

      # --- Commands (Go-style convenience) ---

      def percent_cmd(value : Float64) : Cmd
        Term2::Cmds.message(SetPercentMsg.new(value))
      end

      def increment_cmd(delta : Float64) : Cmd
        Term2::Cmds.message(IncrementMsg.new(delta))
      end

      # --- Update ---

      def init : Cmd
        nil
      end

      def update(msg : Msg) : {Progress, Cmd}
        case msg
        when FrameMsg
          if msg.id == @id && msg.tag == @tag
            if is_animating?
              update_animation
              return {self, next_frame}
            end
          end
        when SetPercentMsg
          return {self, set_percent(msg.value)}
        when IncrementMsg
          return {self, incr_percent(msg.delta)}
        end
        {self, nil}
      end

      def set_percent(p : Float64) : Cmd
        @target_percent = p.clamp(0.0, 1.0)
        @percent = @target_percent
        @tag += 1
        next_frame
      end

      def percent=(value : Float64)
        v = value.clamp(0.0, 1.0)
        @percent = v
        @target_percent = v
        @percent_shown = v
        @velocity = 0.0
      end

      def incr_percent(v : Float64) : Cmd
        set_percent(@percent + v)
      end

      def decr_percent(v : Float64) : Cmd
        set_percent(@percent - v)
      end

      # --- View ---

      def view : View
        View.new(content: view_as(@percent_shown))
      end

      def view_as(percent : Float64) : String
        pct_str = percentage_view(percent)
        text_width = Text.width(pct_str)

        # Crystal doesn't have Math.max, use tuple max or clamp
        bar_width = {0, @width - text_width}.max

        filled_width = (bar_width * percent).round.to_i.clamp(0, bar_width)
        empty_width = bar_width - filled_width

        String.build do |str|
          # Filled section
          if @use_ramp
            filled_width.times do |i|
              p = if filled_width == 1
                    0.5
                  elsif @scale_ramp
                    i.to_f / (filled_width - 1)
                  else
                    i.to_f / (bar_width - 1)
                  end

              color = blend_colors(@ramp_color_a, @ramp_color_b, p)
              str << Style.new.foreground(color).render(@full_char.to_s)
            end
          else
            fill_style = Style.new.foreground(Color.from_hex(@full_color))
            str << fill_style.render(@full_char.to_s * filled_width)
          end

          # Empty section
          empty_style = Style.new.foreground(Color.from_hex(@empty_color))
          str << empty_style.render(@empty_char.to_s * empty_width)

          # Percentage
          str << pct_str
        end
      end

      private def percentage_view(percent : Float64) : String
        return "" unless @show_percentage
        val = percent.clamp(0.0, 1.0) * 100
        formatted = sprintf(@percent_format, val)
        @percentage_style.render(formatted)
      end

      private def next_frame : Cmd
        Term2::Cmds.tick((1000 / FPS).milliseconds) { FrameMsg.new(@id, @tag) }
      end

      private def is_animating? : Bool
        dist = (@percent_shown - @target_percent).abs
        !(dist < 0.001 && @velocity.abs < 0.01)
      end

      private def update_animation
        # Simple critically-damped-ish spring.
        delta = (@target_percent - @percent_shown)
        @velocity = (@velocity + delta * 0.12) * 0.85
        @percent_shown = (@percent_shown + @velocity).clamp(0.0, 1.0)
      end

      # Public command to schedule the next animation frame (Go: nextFrame()).
      def frame : Cmd
        next_frame
      end

      private def blend_colors(c1 : Color, c2 : Color, t : Float64) : Color
        if c1.type == Color::Type::RGB && c2.type == Color::Type::RGB
          # Access value from the color struct
          v1 = c1.value
          v2 = c2.value

          if v1.is_a?(Tuple(Int32, Int32, Int32)) && v2.is_a?(Tuple(Int32, Int32, Int32))
            r1, g1, b1 = v1
            r2, g2, b2 = v2

            r = (r1 + (r2 - r1) * t).to_i
            g = (g1 + (g2 - g1) * t).to_i
            b = (b1 + (b2 - b1) * t).to_i

            return Color.rgb(r, g, b)
          end
        end
        # Fallback
        t > 0.5 ? c2 : c1
      end
    end
  end
end
