require "../term2"

module Term2
  module Components
    class Progress
      include Model

      property percent : Float64 = 0.0
      property width : Int32 = 40
      property full_char : Char = '█'
      property empty_char : Char = '░'
      property? show_percentage : Bool = true
      property percent_format : String = " %.0f%%"
      property animation : Animation?

      struct Animation
        getter target : Float64
        getter start : Float64
        getter duration : Time::Span
        getter start_time : Time

        def initialize(@start : Float64, @target : Float64, @duration : Time::Span, @start_time : Time)
        end
      end

      # Styles
      property full_style : Style = Style.new.foreground(Color::GREEN)
      property empty_style : Style = Style.new.foreground(Color::BLACK)
      property? use_gradient : Bool = false
      property? scale_gradient : Bool = false
      property gradient_color_a : String = "#5A56E0"
      property gradient_color_b : String = "#EE6FF8"
      @id : Int32

      def initialize(@width : Int32 = 30)
        @id = Random.rand(Int32)
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

      class FrameMsg < Message
        getter id : Int32
        getter percent : Float64

        def initialize(@id : Int32, @percent : Float64)
        end
      end

      def update(msg : Msg) : {Progress, Cmd}
        case msg
        when SetPercentMsg
          @percent = msg.value.clamp(0.0, 1.0)
        when IncrementMsg
          @percent = (@percent + msg.delta).clamp(0.0, 1.0)
        when FrameMsg
          if msg.id == @id
            @percent = msg.percent
            # If we're animating and hit target, clear animation
            if anim = @animation
              @animation = nil if anim.target == @percent
            end
            return {self, tick_frame}
          end
        end
        {self, Cmds.none}
      end

      def view : String
        pct_str = ""
        if @show_percentage
          pct_str = sprintf(@percent_format, @percent * 100)
        end

        bar_width = @width - pct_str.size
        return "" if bar_width < 0

        filled_width = (@percent * bar_width).round.to_i
        empty_width = bar_width - filled_width

        full_segment = if @use_gradient
                         gradient_fill(filled_width, bar_width)
                       else
                         @full_style.render(@full_char.to_s * filled_width)
                       end

        empty_segment = @empty_style.render(@empty_char.to_s * empty_width)

        String.build do |str|
          str << full_segment
          str << empty_segment
          str << pct_str if @show_percentage
        end
      end

      def view_as(percent : Float64) : String
        prev = @percent
        @percent = percent
        v = view
        @percent = prev
        v
      end

      # Helper to set percent directly
      def percent_cmd(p : Float64) : Cmd
        Cmds.message(SetPercentMsg.new(p))
      end

      def incr_percent(delta : Float64) : Cmd
        target = (@percent + delta).clamp(0.0, 1.0)
        animate_to(target)
      end

      def animate_to(target : Float64, duration : Time::Span = 300.milliseconds) : Cmd
        @animation = Animation.new(@percent, target, duration, Time.local)
        tick_frame
      end

      def self.with_gradient(color_a : String, color_b : String) : Progress
        p = Progress.new
        p.use_gradient = true
        p.gradient_color_a = color_a
        p.gradient_color_b = color_b
        p
      end

      def self.with_scaled_gradient(color_a : String, color_b : String) : Progress
        p = with_gradient(color_a, color_b)
        p.scale_gradient = true
        p
      end

      private def tick_frame : Cmd
        return Cmds.none unless anim = @animation
        start = anim.start_time
        duration = anim.duration
        start_value = anim.start
        target_value = anim.target

        Cmds.tick(16.milliseconds) do |_time|
          elapsed = Time.local - start
          t = (elapsed / duration).to_f
          t = t.clamp(0.0, 1.0)
          current = start_value + (target_value - start_value) * t
          FrameMsg.new(@id, current.clamp(0.0, 1.0))
        end
      end

      private def gradient_fill(fill_width : Int32, total_width : Int32) : String
        return "" if fill_width <= 0
        span = @scale_gradient ? fill_width : total_width
        span = 1 if span <= 0
        String.build do |io|
          fill_width.times do |i|
            t = if span == 1
                  0.5
                else
                  i.to_f / (span - 1)
                end
            color = blend_hex(@gradient_color_a, @gradient_color_b, t)
            io << ansi_foreground(color) << @full_char << "\e[0m"
          end
        end
      end

      private def blend_hex(a_hex : String, b_hex : String, t : Float64) : Array(Int32)
        ar, ag, ab = hex_to_rgb(a_hex)
        br, bg, bb = hex_to_rgb(b_hex)
        [
          (ar + (br - ar) * t).round,
          (ag + (bg - ag) * t).round,
          (ab + (bb - ab) * t).round,
        ].map(&.clamp(0, 255)).map(&.to_i)
      end

      private def hex_to_rgb(hex : String) : {Float64, Float64, Float64}
        h = hex.gsub("#", "")
        return {0.0, 0.0, 0.0} unless h.size == 6
        r = h[0..1].to_i(16).to_f
        g = h[2..3].to_i(16).to_f
        b = h[4..5].to_i(16).to_f
        {r, g, b}
      end

      private def ansi_foreground(rgb : Array(Int32)) : String
        "\e[38;2;#{rgb[0]},#{rgb[1]},#{rgb[2]}m"
      end
    end
  end
end
