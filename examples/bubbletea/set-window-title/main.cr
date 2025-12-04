require "../../../src/term2"

include Term2::Prelude

class WindowTitleModel
  include Term2::Model

  def init : Term2::Cmd
    Term2::Cmds.window_title=("Bubble Tea Example")
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      return {self, Term2::Cmds.quit}
    end
    {self, nil}
  end

  def view : String
    "\nPress any key to quit."
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(WindowTitleModel.new)
end
