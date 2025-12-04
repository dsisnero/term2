require "../../../src/term2"
require "log"
require "math"
require "random"

include Term2::Prelude

Log.setup_from_env

EYE_WIDTH     = 15
EYE_HEIGHT    = 12
EYE_SPACING   = 40
BLINK_FRAMES  = 20
OPEN_TIME_MIN = 1.seconds
OPEN_TIME_MAX = 4.seconds
EYE_CHAR      = "●"
BG_CHAR       = " "

class EyesTickMsg < Term2::Message
  getter time : Time

  def initialize(@time : Time); end
end

class EyesModel
  include Term2::Model

  getter width : Int32 = 80
  getter height : Int32 = 24
  getter eye_positions : Array(Int32) = [0, 0]
  getter eye_y : Int32 = 0
  getter? blinking : Bool = false
  getter blink_state : Int32 = 0
  getter last_blink : Time = Time.utc
  getter open_time : Time::Span = OPEN_TIME_MIN

  def initialize
    update_eye_positions
  end

  def init : Term2::Cmd
    Term2::Cmds.batch(tick_cmd, Term2::Cmds.enter_alt_screen)
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      if msg.key.type == Term2::KeyType::CtrlC || msg.key.type == Term2::KeyType::Esc
        return {self, Term2::Cmds.quit}
      end
    when Term2::WindowSizeMsg
      @width = msg.width
      @height = msg.height
      update_eye_positions
    when EyesTickMsg
      current_time = Time.utc
      if !@blinking && current_time - @last_blink >= @open_time
        @blinking = true
        @blink_state = 0
      end

      if @blinking
        @blink_state += 1
        if @blink_state >= BLINK_FRAMES
          @blinking = false
          @last_blink = current_time
          diff_ns = (OPEN_TIME_MAX - OPEN_TIME_MIN).nanoseconds
          diff_ns = 1_i64 if diff_ns <= 0
          span_ns = OPEN_TIME_MIN.nanoseconds + Random.rand(diff_ns)
          @open_time = Time::Span.new(nanoseconds: span_ns)
          if Random.rand(10) == 0
            @open_time = 300.milliseconds
          end
        end
      end
    end

    {self, tick_cmd}
  end

  def view : String
    canvas = Array.new(@height) { Array.new(@width, BG_CHAR) }

    current_height = EYE_HEIGHT
    if @blinking
      blink_progress = if @blink_state < BLINK_FRAMES // 2
                         progress = @blink_state.to_f / (BLINK_FRAMES.to_f / 2)
                         1.0 - (progress * progress)
                       else
                         progress = (@blink_state - BLINK_FRAMES // 2).to_f / (BLINK_FRAMES.to_f / 2)
                         progress * (2.0 - progress)
                       end
      current_height = {(EYE_HEIGHT * blink_progress).to_i, 1}.max
    end

    2.times do |i|
      draw_ellipse(canvas, @eye_positions[i], @eye_y, EYE_WIDTH, current_height)
    end

    String.build do |str|
      canvas.each do |row|
        row.each { |cell| str << cell }
        str << '\n'
      end
    end
  end

  private def update_eye_positions
    start_x = (@width - EYE_SPACING) // 2
    @eye_y = @height // 2
    @eye_positions[0] = start_x
    @eye_positions[1] = start_x + EYE_SPACING
  end

  private def tick_cmd : Term2::Cmd
    Term2::Cmds.tick(50.milliseconds) { |t| EyesTickMsg.new(t) }
  end
end

def draw_ellipse(canvas : Array(Array(String)), x0 : Int32, y0 : Int32, rx : Int32, ry : Int32)
  (-ry..ry).each do |y|
    width = (rx.to_f * Math.sqrt(1.0 - (y.to_f / ry.to_f) ** 2)).to_i
    (-width..width).each do |x|
      canvas_x = x0 + x
      canvas_y = y0 + y
      next unless canvas_x >= 0 && canvas_x < canvas[0].size && canvas_y >= 0 && canvas_y < canvas.size
      canvas[canvas_y][canvas_x] = EYE_CHAR
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  opts = Term2::ProgramOptions.new(Term2::WithAltScreen.new)
  Term2.run(EyesModel.new, options: opts)
end
