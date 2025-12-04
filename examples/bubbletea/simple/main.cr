require "../../../src/term2"

include Term2::Prelude

class SimpleTickMsg < Term2::Message
end

def tick : Term2::Cmd
  -> {
    sleep 1.second
    SimpleTickMsg.new.as(Term2::Message)
  }
end

class SimpleModel
  include Term2::Model

  getter remaining : Int32

  def initialize(@remaining : Int32 = 5)
  end

  def init : Term2::Cmd
    tick
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "ctrl+c", "q"
        return {self, Term2::Cmds.quit}
      when "ctrl+z"
        return {self, Term2::Cmds.suspend}
      end
    when SimpleTickMsg
      @remaining -= 1
      if @remaining <= 0
        return {self, Term2::Cmds.quit}
      else
        return {self, tick}
      end
    end
    {self, nil}
  end

  def view : String
    "Hi. This program will exit in #{@remaining} seconds.\n\nTo quit sooner press ctrl-c, or press ctrl-z to suspend...\n"
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(SimpleModel.new)
end
