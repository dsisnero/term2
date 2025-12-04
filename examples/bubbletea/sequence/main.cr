require "../../../src/term2"
require "log"

include Term2::Prelude

Log.setup_from_env

def sleep_println(str : String, milliseconds : Int32) : Term2::Cmd
  -> : Term2::Message? {
    sleep milliseconds.milliseconds
    SequenceModel::LogMsg.new(str)
  }
end

class SequenceModel
  include Term2::Model

  class LogMsg < Term2::Message
    getter text : String

    def initialize(@text : String); end
  end

  getter logs : Array(String)

  def initialize
    @logs = [] of String
  end

  def init : Term2::Cmd
    Term2::Cmds.sequence(
      Term2::Cmds.batch(
        Term2::Cmds.sequence(
          sleep_println("1-1-1", 100),
          sleep_println("1-1-2", 100),
        ),
        Term2::Cmds.batch(
          sleep_println("1-2-1", 150),
          sleep_println("1-2-2", 125),
        ),
      ),
      -> : Term2::Message? { LogMsg.new("2") },
      Term2::Cmds.sequence(
        Term2::Cmds.batch(
          sleep_println("3-1-1", 50),
          sleep_println("3-1-2", 100),
        ),
        Term2::Cmds.sequence(
          sleep_println("3-2-1", 75),
          sleep_println("3-2-2", 50),
        ),
      ),
    )
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when LogMsg
      @logs << msg.text
      if @logs.size >= 9
        return {self, Term2::Cmds.quit}
      end
    when Term2::KeyMsg
      return {self, Term2::Cmds.quit}
    end
    {self, nil}
  end

  def view : String
    lines = @logs.empty? ? ["Running sequence..."] : @logs
    lines.join("\n") + "\n"
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(SequenceModel.new)
end
