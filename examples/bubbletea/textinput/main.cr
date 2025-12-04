require "../../../src/term2"

include Term2::Prelude

class TextInputExampleModel
  include Term2::Model

  getter text_input : TC::TextInput
  getter err : Exception?

  def initialize
    ti = TC::TextInput.new
    ti.placeholder = "Pikachu"
    ti.focus
    ti.char_limit = 156
    ti.width = 20

    @text_input = ti
    @err = nil
  end

  def init : Term2::Cmd
    @text_input.cursor.blink_cmd
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.type
      when Term2::KeyType::Enter, Term2::KeyType::CtrlC, Term2::KeyType::Esc
        return {self, Term2::Cmds.quit}
      end
    end

    @text_input, cmd = @text_input.update(msg)
    {self, cmd}
  end

  def view : String
    "What’s your favorite Pokémon?\n\n#{@text_input.view}\n\n(esc to quit)\n"
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(TextInputExampleModel.new)
end
