require "../../../src/term2"

include Term2::Prelude

class SuspendModel
  include Term2::Model

  getter? quitting : Bool
  getter? suspending : Bool

  def initialize
    @quitting = false
    @suspending = false
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::ResumeMsg
      @suspending = false
      return {self, nil}
    when Term2::KeyMsg
      case msg.key.to_s
      when "q", "esc"
        @quitting = true
        return {self, Term2::Cmds.quit}
      when "ctrl+c"
        @quitting = true
        return {self, Term2::Cmds.interrupt}
      when "ctrl+z"
        @suspending = true
        return {self, Term2::Cmds.suspend}
      end
    end
    {self, nil}
  end

  def view : String
    if @suspending || @quitting
      ""
    else
      "\nPress ctrl-z to suspend, ctrl+c to interrupt, q, or esc to exit\n"
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(SuspendModel.new)
end
