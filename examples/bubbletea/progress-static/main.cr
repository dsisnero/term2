require "../../../src/term2"

include Term2::Prelude

class ProgressTick < Term2::Message
end

class ProgressStaticModel
  include Term2::Model

  PADDING    =  2
  MAX_WIDTH  = 80
  HELP_STYLE = Term2::Style.new.foreground(Term2::Color.from_hex("#626262"))

  getter percent : Float64
  getter progress : TC::Progress

  def initialize
    @percent = 0.0
    @progress = TC::Progress.with_scaled_gradient("#FF7CCB", "#FDFF8C")
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
    when ProgressTick
      @percent += 0.25
      if @percent > 1.0
        @percent = 1.0
        return {self, Term2::Cmds.quit}
      end
      return {self, tick_cmd}
    end
    {self, nil}
  end

  def view : String
    pad = " " * PADDING
    "\n#{pad}#{@progress.view_as(@percent)}\n\n#{pad}#{HELP_STYLE.render("Press any key to quit")}"
  end

  private def tick_cmd : Term2::Cmd
    Term2::Cmds.tick(1.second) { ProgressTick.new }
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(ProgressStaticModel.new)
end
