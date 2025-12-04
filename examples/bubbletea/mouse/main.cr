require "../../../src/term2"

include Term2::Prelude

class MouseModel
  include Term2::Model

  getter mouse_event : Term2::MouseEvent?

  def initialize
    @mouse_event = nil
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "ctrl+c", "q", "esc"
        return {self, Term2::Cmds.quit}
      end
    when Term2::MouseEvent
      @mouse_event = msg
      return {self, Term2::Cmds.printf("(X: %d, Y: %d) %s", msg.x, msg.y, msg.to_s)}
    end
    {self, nil}
  end

  def view : String
    "Do mouse stuff. When you're done press q to quit.\n"
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(MouseModel.new, options: Term2::ProgramOptions.new(Term2::WithMouseAllMotion.new))
end
