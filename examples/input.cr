# Text Input Component Example
#
# This example demonstrates the TextInput component.
# Type text and see it displayed with a blinking cursor.
#
# Run with: crystal run examples/input.cr
require "../src/term2"
include Term2::Prelude

class InputModel < Model
  property input : TC::TextInput

  def initialize
    @input = TC::TextInput.new
    @input.placeholder = "Type something..."
    @input.char_limit = 20
    @input.focus
  end

  def init : Cmd
    @input.focus
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when KeyMsg
      case msg.key.to_s
      when "ctrl+c"
        {self, Term2.quit}
      when "enter"
        # Submit
        {self, Cmd.none}
      else
        new_input, cmd = @input.update(msg)
        @input = new_input
        {self, cmd}
      end
    else
      {self, Cmd.none}
    end
  end

  def view : String
    String.build do |str|
      str << "\n"
      str << "╔════════════════════════════════════════╗".bold.cyan << "\n"
      str << "║          Text Input Demo               ║".bold.cyan << "\n"
      str << "╚════════════════════════════════════════╝".bold.cyan << "\n"
      str << "\n"
      str << "  " << "Input:".bold << " " << @input.view << "\n"
      str << "\n"
      str << "  " << "Value:".bold << " " << @input.value.inspect.gray << "\n"
      str << "\n"
      str << "─" * 44 << "\n"
      str << "Type to enter text, " << "Ctrl+C".cyan << " to quit\n"
    end
  end
end

Term2.run(InputModel.new)
