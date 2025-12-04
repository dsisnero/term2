require "../../../src/term2"
require "log"

include Term2::Prelude

Log.setup_from_env

DEBOUNCE_DURATION = 1.second

class ExitMsg < Term2::Message
  getter tag : Int32
  def initialize(@tag : Int32); end
end

class DebounceModel
  include Term2::Model

  getter tag : Int32 = 0

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      @tag += 1
      current = @tag
      cmd = Term2::Cmds.tick(DEBOUNCE_DURATION) { ExitMsg.new(current) }
      {self, cmd}
    when ExitMsg
      if msg.tag == @tag
        {self, Term2::Cmds.quit}
      else
        {self, nil}
      end
    else
      {self, nil}
    end
  end

  def view : String
    "Key presses: #{@tag}\nTo exit press any key, then wait for one second without pressing anything."
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(DebounceModel.new)
end
