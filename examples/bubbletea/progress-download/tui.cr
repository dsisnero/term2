require "../../../src/term2"

include Term2::Prelude

class ProgressMsg < Term2::Message
  getter ratio : Float64

  def initialize(@ratio : Float64); end
end

class ProgressErrMsg < Term2::Message
  getter error : Exception

  def initialize(@error : Exception); end
end

class ProgressDownloadModel
  include Term2::Model

  HELP_STYLE = Lipgloss::Style.new.fg_hex("#626262")
  PADDING    =  2
  MAX_WIDTH  = 80

  getter progress : TC::Progress
  getter err : Exception?

  @pw : Nil

  def initialize
    @pw = nil
    @progress = TC::Progress.new
    @progress.use_gradient = true
    @err = nil
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      return {self, Term2::Cmds.quit}
    when Term2::WindowSizeMsg
      @progress.width = msg.width - PADDING * 2 - 4
      @progress.width = MAX_WIDTH if @progress.width > MAX_WIDTH
      return {self, nil}
    when ProgressErrMsg
      @err = msg.error
      return {self, Term2::Cmds.quit}
    when ProgressMsg
      cmds = [] of Term2::Cmd

      if msg.ratio >= 1.0
        cmds << Term2::Cmds.sequence(final_pause, Term2::Cmds.quit)
      end

      cmds << @progress.set_percent(msg.ratio)

      return {self, Term2::Cmds.batch(cmds)} unless cmds.empty?
      return {self, nil}
    when TC::Progress::FrameMsg
      @progress, cmd = @progress.update(msg)
      return {self, cmd}
    else
      return {self, nil}
    end
  end

  def view : String
    if err = @err
      return "Error downloading: #{err.message}\n"
    end

    pad = " " * PADDING
    "\n#{pad}#{@progress.view}\n\n#{pad}#{HELP_STYLE.render("Press any key to quit")}"
  end

  private def final_pause : Term2::Cmd
    Term2::Cmds.tick(750.milliseconds) { Term2::PrintMsg.new("") }
  end
end
