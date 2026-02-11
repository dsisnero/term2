require "../../../src/term2"

module SpaceExample
  include Term2::Prelude

  class TickMsg < Term2::Message; end

  class Model
    include Term2::Model

    @colors : Array(Array(Lipgloss::Color)) = [] of Array(Lipgloss::Color)
    @last_width : Int32 = 0
    @last_height : Int32 = 0
    @frame_count : Int32 = 0
    @width : Int32 = 0
    @height : Int32 = 0

    def init : Term2::Cmd
      tick_cmd
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::KeyMsg
        case msg.string
        when "q", "ctrl+c"
          return {self, Term2.quit}
        end
      when Term2::WindowSizeMsg
        @width = msg.width
        @height = msg.height
        if @width != @last_width || @height != @last_height
          setup_colors
          @last_width = @width
          @last_height = @height
        end
      when TickMsg
        @frame_count += 1
        return {self, tick_cmd}
      end
      {self, nil}
    end

    def view : Term2::View
      title = Lipgloss::Style.new.bold(true).render("Space")
      body_height = {@height - 1, 0}.max

      body = String.build do |io|
        body_height.times do |y|
          @width.times do |x|
            next if @colors.empty?
            xi = (x + @frame_count) % @width
            fg = @colors[y * 2][xi]
            bg = @colors[y * 2 + 1][xi]
            io << Lipgloss::Style.new.foreground(fg).background(bg).render("▀")
          end
          io << '\n' if y < body_height - 1
        end
      end

      Term2::View.new(
        content: [title, body].join("\n"),
        alt_screen: true
      )
    end

    private def tick_cmd : Term2::Cmd
      Term2::Cmds.tick(16.milliseconds) { TickMsg.new }
    end

    private def setup_colors : Nil
      return if @width <= 0 || @height <= 0

      doubled_height = @height * 2
      @colors = Array.new(doubled_height) { Array.new(@width, Lipgloss::Color.rgb(0, 0, 0)) }

      doubled_height.times do |y|
        randomness_factor = (doubled_height - y).to_f64 / doubled_height.to_f64
        @width.times do |x|
          base_value = randomness_factor * ((doubled_height - y).to_f64 / doubled_height.to_f64)
          random_offset = deterministic_offset(x, y)
          value = (base_value + random_offset).clamp(0.0, 1.0)
          gray = (value * 255).round.to_i
          @colors[y][x] = Lipgloss::Color.rgb(gray, gray, gray)
        end
      end
    end

    # Stable pseudo-random offset in [-0.1, 0.1] for deterministic tests.
    private def deterministic_offset(x : Int32, y : Int32) : Float64
      n = (x.to_i64 * 374_761_393_i64 + y.to_i64 * 668_265_263_i64 + 0x9E37_79B9_i64) & 0x7FFF_FFFF_i64
      unit = (n % 2001) / 2000.0
      (unit - 0.5) * 0.2
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  options = Term2::ProgramOptions.new(Term2::WithFPS.new(120.0))
  Term2.run(SpaceExample::Model.new, options: options)
end
