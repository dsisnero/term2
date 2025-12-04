require "../../../src/term2"
require "log"

include Term2::Prelude

Log.setup_from_env

class FocusBlurModel
  include Term2::Model

  getter? focused : Bool
  getter? reporting : Bool

  def initialize(@focused = true, @reporting = true)
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::FocusMsg
      @focused = true
    when Term2::BlurMsg
      @focused = false
    when Term2::KeyMsg
      case msg.key.to_s
      when "t"
        @reporting = !@reporting
      when "ctrl+c", "q"
        return {self, Term2::Cmds.quit}
      end
    end
    {self, nil}
  end

  def view : String
    s = "Hi. Focus report is currently "
    s += @reporting ? "enabled" : "disabled"
    s += ".\n\n"

    if @reporting
      if @focused
        s += "This program is currently focused!"
      else
        s += "This program is currently blurred!"
      end
    end
    s + "\n\nTo quit sooner press ctrl-c, or t to toggle focus reporting...\n"
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  opts = Term2::ProgramOptions.new(Term2::WithReportFocus.new)
  Term2.run(FocusBlurModel.new, options: opts)
end
