require "../../../src/term2"
require "colorize"

include Term2::Prelude

PROGRESS_BAR_WIDTH = 71
PROGRESS_FULL_CHAR = "█"
PROGRESS_EMPTY_CHAR = "░"
DOT_CHAR = " • "

VIEWS_KEYWORD_STYLE = Style.new.foreground(Color.indexed(211))
SUBTLE_STYLE = Style.new.foreground(Color.indexed(241))
TICKS_STYLE = Style.new.foreground(Color.indexed(79))
CHECKBOX_STYLE = Style.new.foreground(Color.indexed(212))
PROGRESS_EMPTY = SUBTLE_STYLE.render(PROGRESS_EMPTY_CHAR)
VIEWS_DOT_STYLE = Style.new.foreground(Color.indexed(236)).render(DOT_CHAR)
VIEWS_MAIN_STYLE = Style.new.margin(0, 0, 0, 2)

# Simple gradient ramp for progress bar
def make_ramp_styles(a_hex : String, b_hex : String, width : Int32) : Array(Style)
  a = Color.from_hex(a_hex).to_rgb
  b = Color.from_hex(b_hex).to_rgb
  styles = Array(Style).new(width)
  width.times do |i|
    t = width == 1 ? 0.0 : i / (width - 1).to_f
    r = (a[0] + (b[0] - a[0]) * t).to_i
    g = (a[1] + (b[1] - a[1]) * t).to_i
    bl = (a[2] + (b[2] - a[2]) * t).to_i
    styles << Style.new.foreground(Color.rgb(r, g, bl))
  end
  styles
end

RAMP = make_ramp_styles("#B14FFF", "#00FFA3", PROGRESS_BAR_WIDTH)

class ViewsTickMsg < Message; end
class ViewsFrameMsg < Message; end

def tick_cmd : Cmd
  Cmds.tick(1.second) { ViewsTickMsg.new }
end

def frame_cmd : Cmd
  Cmds.tick(1.second / 60) { ViewsFrameMsg.new }
end

class ViewsModel
  include Model

  getter choice : Int32
  getter? chosen : Bool
  getter ticks : Int32
  getter frames : Int32
  getter progress : Float64
  getter? loaded : Bool
  getter? quitting : Bool

  def initialize
    @choice = 0
    @chosen = false
    @ticks = 10
    @frames = 0
    @progress = 0.0
    @loaded = false
    @quitting = false
  end

  def init : Cmd
    tick_cmd
  end

  def update(msg : Msg) : {Model, Cmd}
    if msg.is_a?(KeyMsg)
      k = msg.key.to_s
      if k == "q" || k == "esc" || k == "ctrl+c"
        @quitting = true
        return {self, Cmds.quit}
      end
    end

    if !@chosen
      return update_choices(msg)
    else
      return update_chosen(msg)
    end
  end

  def view : String
    return "\n  See you later!\n\n" if @quitting

    s = if !@chosen
          choices_view
        else
          chosen_view
        end
    VIEWS_MAIN_STYLE.render("\n" + s + "\n\n")
  end

  private def update_choices(msg : Msg) : {Model, Cmd}
    case msg
    when KeyMsg
      case msg.key.to_s
      when "j", "down"
        @choice += 1
        @choice = 3 if @choice > 3
      when "k", "up"
        @choice -= 1
        @choice = 0 if @choice < 0
      when "enter"
        @chosen = true
        return {self, frame_cmd}
      end
    when ViewsTickMsg
      if @ticks == 0
        @quitting = true
        return {self, Cmds.quit}
      end
      @ticks -= 1
      return {self, tick_cmd}
    end
    {self, nil}
  end

  private def update_chosen(msg : Msg) : {Model, Cmd}
    case msg
    when ViewsFrameMsg
      unless @loaded
        @frames += 1
        @progress = ease_out_bounce(@frames / 100.0)
        if @progress >= 1
          @progress = 1
          @loaded = true
          @ticks = 3
          return {self, tick_cmd}
        end
        return {self, frame_cmd}
      end
    when ViewsTickMsg
      if @loaded
        if @ticks == 0
          @quitting = true
          return {self, Cmds.quit}
        end
        @ticks -= 1
        return {self, tick_cmd}
      end
    end
    {self, nil}
  end

  # Simple ease out bounce approximation
  private def ease_out_bounce(t : Float64) : Float64
    n1 = 7.5625
    d1 = 2.75
    if t < 1 / d1
      n1 * t * t
    elsif t < 2 / d1
      t -= 1.5 / d1
      n1 * t * t + 0.75
    elsif t < 2.5 / d1
      t -= 2.25 / d1
      n1 * t * t + 0.9375
    else
      t -= 2.625 / d1
      n1 * t * t + 0.984375
    end
  end

  private def checkbox(title : String, checked : Bool) : String
    mark = checked ? CHECKBOX_STYLE.render("(•)") : "( )"
    "#{mark} #{title}"
  end

  private def progressbar(percent : Float64) : String
    pct = (percent * 100).to_i
    w = pct * PROGRESS_BAR_WIDTH // 100
    empty_w = PROGRESS_BAR_WIDTH - w
    full = (0...w).map { |i| RAMP[[i, RAMP.size - 1].min].render(PROGRESS_FULL_CHAR) }.join
    empty = PROGRESS_EMPTY_CHAR * empty_w
    full + empty
  end

  private def choices_view : String
    c = @choice
    tpl = "What to do today?\n\n"
    tpl += "%s\n\n"
    tpl += "Program quits in %s seconds\n\n"
    tpl += SUBTLE_STYLE.render("j/k, up/down: select") + VIEWS_DOT_STYLE +
      SUBTLE_STYLE.render("enter: choose") + VIEWS_DOT_STYLE +
      SUBTLE_STYLE.render("q, esc: quit")

    choices = [
      checkbox("Plant carrots", c == 0),
      checkbox("Go to the market", c == 1),
      checkbox("Read something", c == 2),
      checkbox("See friends", c == 3),
    ].join("\n")

    sprintf(tpl, choices, TICKS_STYLE.render(@ticks.to_s))
  end

  private def chosen_view : String
    header = VIEWS_KEYWORD_STYLE.render("Doing cool stuff with Bubble Tea") + "\n\n"
    notes = SUBTLE_STYLE.render("Hold on tight, we’re doing some work here…")
    prog = progressbar(@progress)
    header + prog + "\n\n" + notes
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(ViewsModel.new)
end
