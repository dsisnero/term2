require "../../../src/term2"

include Term2::Prelude

class WindowSizeModel
  include Term2::Model

  property width : Int32
  property height : Int32

  def initialize
    @width = 0
    @height = 0
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
      else
        # In non-TTY tests, reuse the last known size instead of querying the terminal.
        if @width > 0 && @height > 0
          return {self, Term2::Cmds.message(Term2::WindowSizeMsg.new(@width, @height))}
        else
          return {self, Term2::Cmds.window_size}
        end
      end
    when Term2::WindowSizeMsg
      @width = msg.width
      @height = msg.height
      return {self, Term2::Cmds.printf("%dx%d", @width, @height)}
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
