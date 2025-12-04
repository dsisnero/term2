require "../../../src/term2"
require "log"

include Term2::Prelude

Log.setup_from_env

class FullscreenTickMsg < Term2::Message
  getter time : Time

  def initialize(@time : Time); end
end

def tick_cmd : Term2::Cmd
  Term2::Cmds.tick(1.second) { |t| FullscreenTickMsg.new(t) }
end

class FullscreenModel
  include Term2::Model
  getter countdown : Int32

  def initialize(@countdown : Int32 = 5)
  end

  def init : Term2::Cmd
    tick_cmd
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "q", "esc", "ctrl+c"
        return {self, Term2::Cmds.quit}
      end
    when FullscreenTickMsg
      @countdown -= 1
      if @countdown <= 0
        return {self, Term2::Cmds.quit}
      end
      return {self, tick_cmd}
    end
    {self, nil}
  end

  def view : String
    "\n\n     Hi. This program will exit in #{@countdown} seconds..."
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  opts = Term2::ProgramOptions.new(Term2::WithAltScreen.new)
  Term2.run(FullscreenModel.new, options: opts)
end
