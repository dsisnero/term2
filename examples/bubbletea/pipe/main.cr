require "../../../src/term2"

include Term2::Prelude

def read_stdin_content : String
  content = String.build do |io|
    while char = STDIN.read_char
      io << char
    end
  end
  content = content.rstrip

  if content.empty? && STDIN.tty?
    puts "Try piping in some text."
    exit 1
  end

  content
end

class PipeModel
  include Term2::Model

  getter user_input : TC::TextInput

  def initialize(initial_value : String)
    ti = TC::TextInput.new
    ti.prompt = ""
    ti.cursor.style = Term2::Style.new.fg_indexed(63)
    ti.width = 48
    ti.value = initial_value
    ti.cursor_end
    ti.focus
    @user_input = ti
  end

  def init : Term2::Cmd
    @user_input.cursor.blink_cmd
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    if msg.is_a?(Term2::KeyMsg)
      case msg.key.to_s
      when "ctrl+c", "esc", "enter"
        return {self, Term2::Cmds.quit}
      end
    end
    @user_input, cmd = @user_input.update(msg)
    {self, cmd}
  end

  def view : String
    "\nYou piped in: #{@user_input.view}\n\nPress ^C to exit"
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  initial = read_stdin_content
  Term2.run(PipeModel.new(initial))
end
