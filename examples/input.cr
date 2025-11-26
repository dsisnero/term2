# Text Input Component Example
#
# This example demonstrates the TextInput component.
# Type text and see it displayed with a blinking cursor.
#
# Run with: crystal run examples/input.cr
require "../src/term2"
include Term2::Prelude

class InputModel < Model
  getter text_input : Components::TextInput::Model

  def initialize(@text_input : Components::TextInput::Model)
  end
end

class InputDemo < Application
  @input : Components::TextInput

  def initialize
    @input = Components::TextInput.new(
      placeholder: "Type something...",
      max_length: 50
    )
  end

  def init
    input_model, cmd = @input.init(focused: true)
    {InputModel.new(input_model), cmd}
  end

  def update(msg : Message, model : Model)
    app = model.as(InputModel)

    case msg
    when KeyPress
      case msg.key
      when "\u0003"  # Ctrl+C
        {app, Cmd.quit}
      when "enter"
        # Could submit the text here
        {app, Cmd.none}
      else
        new_input, cmd = @input.update(msg, app.text_input)
        {InputModel.new(new_input), cmd}
      end
    else
      {model, Cmd.none}
    end
  end

  def view(model : Model) : String
    app = model.as(InputModel)
    String.build do |s|
      s << "\n"
      s << (S.bold.cyan | "╔════════════════════════════════════════╗") << "\n"
      s << (S.bold.cyan | "║          Text Input Demo               ║") << "\n"
      s << (S.bold.cyan | "╚════════════════════════════════════════╝") << "\n"
      s << "\n"
      s << "  " << "Input:".bold << " " << @input.view(app.text_input) << "\n"
      s << "\n"
      s << "  " << "Value:".bold << " " << app.text_input.value.inspect.gray << "\n"
      s << "\n"
      s << "─" * 44 << "\n"
      s << "Type to enter text, " << "Ctrl+C".cyan << " to quit\n"
    end
  end
end

InputDemo.new.run
