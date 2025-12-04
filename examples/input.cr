# Text Input Component Example
#
# This example demonstrates the TextInput component.
# Type text and see it displayed with a blinking cursor.
#
# Run with: crystal run examples/input.cr
require "../src/term2"
include Term2::Prelude

# Define styles
TITLE_STYLE = Term2::Style.new
  .bold(true)
  .cyan

LABEL_STYLE = Term2::Style.new.bold(true)
VALUE_STYLE = Term2::Style.new.dark_gray # gray
KEY_STYLE   = Term2::Style.new.cyan

class InputModel
  include Model
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
        {self, Cmds.none}
      else
        new_input, cmd = @input.update(msg)
        @input = new_input
        {self, cmd}
      end
    else
      {self, Cmds.none}
    end
  end

  def view : String
    String.build do |str|
      str << "\n"
      str << TITLE_STYLE.render("╔════════════════════════════════════════╗") << "\n"
      str << TITLE_STYLE.render("║          Text Input Demo               ║") << "\n"
      str << TITLE_STYLE.render("╚════════════════════════════════════════╝") << "\n"
      str << "\n"
      str << "  " << LABEL_STYLE.render("Input:") << " " << @input.view << "\n"
      str << "\n"
      str << "  " << LABEL_STYLE.render("Value:") << " " << VALUE_STYLE.render(@input.value.inspect) << "\n"
      str << "\n"
      str << "─" * 44 << "\n"
      str << "Type to enter text, " << KEY_STYLE.render("Ctrl+C") << " to quit\n"
    end
  end
end

Term2.run(InputModel.new)
