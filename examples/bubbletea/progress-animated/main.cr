require "../../../src/term2"

include Term2::Prelude

class ProgressAnimatedTick < Term2::Message
end

class ProgressAnimatedModel
  include Term2::Model

  PADDING    =  2
  MAX_WIDTH  = 80
HELP_STYLE = Term2::Style.new.fg_hex("#626262")

  getter progress : TC::Progress

  def initialize
    @progress = TC::Progress.new
    @progress.use_gradient = true
  end

  def init : Term2::Cmd
    tick_cmd
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      return {self, Term2::Cmds.quit}
    when Term2::WindowSizeMsg
      @progress.width = msg.width - PADDING * 2 - 4
      @progress.width = MAX_WIDTH if @progress.width > MAX_WIDTH
      return {self, nil}
    when ProgressAnimatedTick
      if @progress.percent >= 1.0
        return {self, Term2::Cmds.quit}
      end
      cmd = @progress.incr_percent(0.25)
      return {self, Term2::Cmds.batch(tick_cmd, cmd)}
    when TC::Progress::FrameMsg
      @progress, cmd = @progress.update(msg)
      return {self, cmd}
    end
    {self, nil}
  end

  def view : String
    pad = " " * PADDING
    "\n#{pad}#{@progress.view}\n\n#{pad}#{HELP_STYLE.render("Press any key to quit")}"
  end

  private def tick_cmd : Term2::Cmd
    Term2::Cmds.tick(1.second) { ProgressAnimatedTick.new }
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(ProgressAnimatedModel.new)
end
