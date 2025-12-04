require "../../../src/term2"

include Term2::Prelude

class WindowSizeModel
  include Term2::Model

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "ctrl+c", "q", "esc"
        return {self, Term2::Cmds.quit}
      else
        return {self, Term2::Cmds.window_size}
      end
    when Term2::WindowSizeMsg
      return {self, Term2::Cmds.printf("%dx%d", msg.width, msg.height)}
    end
    {self, nil}
  end

  def view : String
    "When you're done press q to quit. Press any other key to query the window-size.\n"
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(WindowSizeModel.new)
end
