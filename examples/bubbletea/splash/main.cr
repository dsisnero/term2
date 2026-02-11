require "../../../src/term2"

module SplashExample
  include Term2::Prelude

  COLORS = [
    {0x88, 0x11, 0x77},
    {0xAA, 0x33, 0x55},
    {0xCC, 0x66, 0x66},
    {0xEE, 0x99, 0x44},
    {0xEE, 0xDD, 0x00},
    {0x99, 0xDD, 0x55},
    {0x44, 0xDD, 0x88},
    {0x22, 0xCC, 0xBB},
    {0x00, 0xBB, 0xCC},
    {0x00, 0x99, 0xCC},
    {0x33, 0x66, 0xBB},
    {0x66, 0x33, 0x99},
  ]

  class TickMsg < Term2::Message; end

  class Model
    include Term2::Model

    property width : Int32 = 0
    property height : Int32 = 0
    property rate : Int64 = 90_i64

    def init : Term2::Cmd
      tick
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::KeyMsg
        return {self, Term2.quit}
      when Term2::WindowSizeMsg
        @width = msg.width
        @height = msg.height
      when TickMsg
        return {self, tick}
      end
      {self, nil}
    end

    def view : Term2::View
      if @width == 0
        return Term2::View.new(content: "Initializing...", alt_screen: true)
      end

      Term2::View.new(content: gradient, alt_screen: true)
    end

    private def tick : Term2::Cmd
      Term2::Cmds.tick(16.milliseconds) { TickMsg.new }
    end

    private def gradient : String
      t = Time.utc.to_unix_ms.to_f64 * @rate / 1000.0
      angle_radians = -t * Math::PI / 180.0
      sin_angle = Math.sin(angle_radians)
      cos_angle = Math.cos(angle_radians)

      center_x = @width.to_f64 / 2.0
      center_y = @height.to_f64

      String.build do |io|
        @height.times do |line_y|
          point_y = line_y.to_f64 * 2.0 - center_y
          point_x = -center_x

          x1 = (center_x + (point_x * cos_angle - point_y * sin_angle)) / @width.to_f64
          x2 = (center_x + (point_x * cos_angle - (point_y + 1.0) * sin_angle)) / @width.to_f64
          point_x = @width.to_f64 - center_x
          end_x1 = (center_x + (point_x * cos_angle - point_y * sin_angle)) / @width.to_f64
          delta_x = (end_x1 - x1) / @width.to_f64

          if delta_x.abs < 0.0001
            c1 = gradient_color(x1)
            c2 = gradient_color(x2)
            io << Lipgloss::Style.new.foreground(c1).background(c2).render("▀" * @width)
          else
            @width.times do |x|
              pos1 = x1 + x.to_f64 * delta_x
              pos2 = x2 + x.to_f64 * delta_x
              c1 = gradient_color(pos1)
              c2 = gradient_color(pos2)
              io << Lipgloss::Style.new.foreground(c1).background(c2).render("▀")
            end
          end

          io << '\n' if line_y < @height - 1
        end
      end
    end

    private def gradient_color(position : Float64) : Lipgloss::Color
      p = position.clamp(0.0, 1.0)
      idx = p * (COLORS.size - 1)
      i1 = idx.floor.to_i
      i2 = idx.ceil.to_i
      t = idx - i1

      r = lerp(COLORS[i1][0], COLORS[i2][0], t)
      g = lerp(COLORS[i1][1], COLORS[i2][1], t)
      b = lerp(COLORS[i1][2], COLORS[i2][2], t)
      Lipgloss::Color.rgb(r, g, b)
    end

    private def lerp(a : Int32, b : Int32, t : Float64) : Int32
      (a.to_f64 * (1.0 - t) + b.to_f64 * t).round.to_i
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(SplashExample::Model.new)
end
