require "../../../src/term2"
require "log"

include Term2::Prelude

Log.setup_from_env

FPS       =   60
FREQUENCY =  7.5
DAMPING   = 0.15
ASTERISK  = "*"

class CellBuffer
  property cells : Array(String) = [] of String
  property stride : Int32 = 0

  def init(width : Int32, height : Int32)
    return if width == 0
    @stride = width
    @cells = Array(String).new(width * height, " ")
    wipe
  end

  def set(x : Int32, y : Int32)
    return if x < 0 || y < 0 || x >= width || y >= height
    idx = y * @stride + x
    return if idx >= @cells.size
    @cells[idx] = ASTERISK
  end

  def wipe
    @cells.fill(" ")
  end

  def width : Int32
    @stride
  end

  def height : Int32
    return 0 if @stride == 0
    h = @cells.size // @stride
    h += 1 if @cells.size % @stride != 0
    h
  end

  def ready? : Bool
    !@cells.empty?
  end

  def to_s : String
    return "" if @cells.empty?
    String.build do |str|
      @cells.each_with_index do |cell, idx|
        if idx > 0 && idx % @stride == 0 && idx < @cells.size - 1
          str << '\n'
        end
        str << cell
      end
    end
  end
end

def draw_ellipse(cb : CellBuffer, xc : Float64, yc : Float64, rx : Float64, ry : Float64)
  dx = 0_f64
  dy = 0_f64
  d1 = ry*ry - rx*rx*ry + 0.25*rx*rx
  x = 0_f64
  y = ry

  dx = 2 * ry * ry * x
  dy = 2 * rx * rx * y

  while dx < dy
    cb.set((x + xc).to_i, (y + yc).to_i)
    cb.set((-x + xc).to_i, (y + yc).to_i)
    cb.set((x + xc).to_i, (-y + yc).to_i)
    cb.set((-x + xc).to_i, (-y + yc).to_i)
    if d1 < 0
      x += 1
      dx = dx + (2 * ry * ry)
      d1 = d1 + dx + (ry * ry)
    else
      x += 1
      y -= 1
      dx = dx + (2 * ry * ry)
      dy = dy - (2 * rx * rx)
      d1 = d1 + dx - dy + (ry * ry)
    end
  end

  d2 = ((ry * ry) * ((x + 0.5) * (x + 0.5))) + ((rx * rx) * ((y - 1) * (y - 1))) - (rx * rx * ry * ry)

  while y >= 0
    cb.set((x + xc).to_i, (y + yc).to_i)
    cb.set((-x + xc).to_i, (y + yc).to_i)
    cb.set((x + xc).to_i, (-y + yc).to_i)
    cb.set((-x + xc).to_i, (-y + yc).to_i)
    if d2 > 0
      y -= 1
      dy = dy - (2 * rx * rx)
      d2 = d2 + (rx * rx) - dy
    else
      y -= 1
      x += 1
      dx = dx + (2 * ry * ry)
      dy = dy - (2 * rx * rx)
      d2 = d2 + dx - dy + (rx * rx)
    end
  end
end

class CellbufferFrameMsg < Term2::Message; end

def animate : Term2::Cmd
  Term2::Cmds.tick((1.0 / FPS).seconds) { CellbufferFrameMsg.new }
end

class CellBufferModel
  include Term2::Model

  getter cells : CellBuffer
  getter target_x : Float64
  getter target_y : Float64
  getter x : Float64
  getter y : Float64
  getter x_velocity : Float64
  getter y_velocity : Float64
  getter spring_fps : Float64
  getter spring_frequency : Float64
  getter spring_damping : Float64

  def initialize
    @cells = CellBuffer.new
    @target_x = 0.0
    @target_y = 0.0
    @x = 0.0
    @y = 0.0
    @x_velocity = 0.0
    @y_velocity = 0.0
    @spring_fps = FPS.to_f
    @spring_frequency = FREQUENCY.to_f
    @spring_damping = DAMPING.to_f
  end

  def init : Term2::Cmd
    Term2::Cmds.batch(Term2::Cmds.window_size, animate)
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      {self, Term2::Cmds.quit}
    when Term2::WindowSizeMsg
      if !@cells.ready?
        @target_x = msg.width / 2
        @target_y = msg.height / 2
      end
      @cells.init(msg.width, msg.height)
      {self, nil}
    when Term2::MouseEvent
      if !@cells.ready?
        {self, nil}
      else
        @target_x = msg.x.to_f
        @target_y = msg.y.to_f
        {self, nil}
      end
    when CellbufferFrameMsg
      if !@cells.ready?
        return {self, nil}
      end

      @cells.wipe
      @x, @x_velocity = update_spring(@x, @x_velocity, @target_x)
      @y, @y_velocity = update_spring(@y, @y_velocity, @target_y)
      draw_ellipse(@cells, @x, @y, 16, 8)
      {self, animate}
    else
      {self, nil}
    end
  end

  def view : String
    @cells.to_s
  end

  private def update_spring(position : Float64, velocity : Float64, target : Float64) : {Float64, Float64}
    # Simple critically damped spring integration mirroring harmonica behavior.
    dt = 1.0 / spring_fps
    omega = 2.0 * Math::PI * spring_frequency
    zeta = spring_damping
    f = 1.0 + 2.0 * dt * zeta * omega
    oo = omega * omega
    hoo = dt * oo
    hhoo = dt * hoo
    det_inv = 1.0 / (f + hhoo)
    det_x = f * position + dt * velocity + hhoo * target
    det_v = velocity + hoo * (target - position)
    new_pos = det_x * det_inv
    new_vel = det_v * det_inv
    {new_pos, new_vel}
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  opts = Term2::ProgramOptions.new(
    Term2::WithAltScreen.new,
    Term2::WithMouseCellMotion.new,
  )
  Term2.run(CellBufferModel.new, options: opts)
end
