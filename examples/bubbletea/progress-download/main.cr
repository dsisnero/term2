require "../../../src/term2"

include Term2::Prelude

class ProgressMsg < Term2::Message
  getter delta : Float64

  def initialize(@delta : Float64); end
end

class ProgressErrMsg < Term2::Message
  getter error : Exception

  def initialize(@error : Exception); end
end

class ProgressDownloadModel
  include Term2::Model

  PADDING    =  2
  MAX_WIDTH  = 80
  HELP_STYLE = Term2::Style.new.foreground(Term2::Color.from_hex("#626262"))

  getter progress : TC::Progress
  getter? quitting : Bool
  getter err : Exception?

  def initialize
    @progress = TC::Progress.new
    @progress.use_gradient = true
    @quitting = false
    @err = nil
  end

  def init : Term2::Cmd
    tick_download
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
      if @progress.percent >= 1.0
        return {self, Term2::Cmds.quit}
      end
      cmd = @progress.incr_percent(msg.delta)
      if @progress.percent + msg.delta >= 1.0
        finish_cmd = Term2::Cmds.sequence(final_pause, Term2::Cmds.quit)
        return {self, Term2::Cmds.batch(cmd, finish_cmd)}
      else
        return {self, Term2::Cmds.batch(cmd, tick_download)}
      end
    when TC::Progress::FrameMsg
      @progress, cmd = @progress.update(msg)
      return {self, cmd}
    end
    {self, nil}
  end

  def view : String
    if err = @err
      return "Error downloading: #{err.message}\n"
    end
    pad = " " * PADDING
    "\n#{pad}#{@progress.view}\n\n#{pad}#{HELP_STYLE.render("Press any key to quit")}"
  end

  private def tick_download : Term2::Cmd
    # Simulate download progress; send 25% increments every second.
    Term2::Cmds.tick(1.second) { ProgressMsg.new(0.25) }
  end

  private def final_pause : Term2::Cmd
    Term2::Cmds.tick(750.milliseconds) { Term2::PrintMsg.new("") }
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(ProgressDownloadModel.new)
end
