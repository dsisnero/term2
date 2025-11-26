require "../src/term2"
require "../src/bubbles/text_input"

class TextInputModel < Term2::Model
  property text_input : Term2::Bubbles::TextInput
  property entered_text : String = ""

  def initialize
    @text_input = Term2::Bubbles::TextInput.new
    @text_input.placeholder = "Type something..."
    @text_input.focus
  end
end

class TextInputDemo < Term2::Application(TextInputModel)
  def init : {TextInputModel, Term2::Cmd}
    model = TextInputModel.new
    {model, model.text_input.focus}
  end

  def update(msg : Term2::Message, model : TextInputModel) : {TextInputModel, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      if msg.key.to_s == "ctrl+c"
        return {model, Term2::Cmd.quit}
      elsif msg.key.to_s == "enter"
        model.entered_text = model.text_input.value
        model.text_input.value = ""
        model.text_input.cursor_start
        return {model, Term2::Cmd.none}
      end
    end

    new_ti, cmd = model.text_input.update(msg)
    model.text_input = new_ti

    {model, cmd}
  end

  def view(model : TextInputModel) : String
    view_content = String.build do |str|
      str << "What is your favorite color?\n\n"
      str << model.text_input.view
      str << "\n\n"
      unless model.entered_text.empty?
        str << "You entered: #{model.entered_text}\n"
      end
      str << "(ctrl+c to quit)"
    end
    view_content
  end
end

TextInputDemo.new.run
