require "../src/term2"
require "../src/components/text_input"

class TextInputModel < Term2::Model
  property text_input : Term2::Components::TextInput
  property entered_text : String = ""

  def initialize
    @text_input = Term2::Components::TextInput.new
    @text_input.placeholder = "Type something..."
    @text_input.focus
  end

  def init : Term2::Cmd
    @text_input.focus
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      if msg.key.to_s == "ctrl+c"
        return {self, Term2.quit}
      elsif msg.key.to_s == "enter"
        @entered_text = @text_input.value
        @text_input.value = ""
        @text_input.cursor_start
        return {self, Term2::Cmd.none}
      end
    end

    new_ti, cmd = @text_input.update(msg)
    @text_input = new_ti

    {self, cmd}
  end

  def view : String
    view_content = String.build do |str|
      str << "What is your favorite color?\n\n"
      str << @text_input.view
      str << "\n\n"
      unless @entered_text.empty?
        str << "You entered: #{@entered_text}\n"
      end
      str << "(ctrl+c to quit)"
    end
    view_content
  end
end

Term2.run(TextInputModel.new)
