# Text Input Component Example
#
# This example demonstrates the TextInput component.
# Type text and see it displayed with a blinking cursor.
#
# Run with: crystal run examples/input.cr
require "../src/term2"
include Term2::Prelude

# Define styles
TITLE_STYLE = Lipgloss::Style.new
  .bold(true)
  .foreground(Lipgloss::Color::CYAN)

LABEL_STYLE = Lipgloss::Style.new.bold(true)
VALUE_STYLE = Lipgloss::Style.new.foreground(Lipgloss::Color::BRIGHT_BLACK) # gray
KEY_STYLE   = Lipgloss::Style.new.foreground(Lipgloss::Color::CYAN)

class InputModel
  include Term2::Model
  property input : TC::TextInput

  def initialize
    @input = TC::TextInput.new
    @input.placeholder = "Type something..."
    @input.char_limit = 20
    @input.focus
  end

  def init : Term2::Cmd
    @input.focus
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.string
      when "ctrl+c"
        {self, Term2::Cmds.quit}
      when "enter"
        # Submit
        {self, Term2::Cmds.none}
      else
        new_input, cmd = @input.update(msg)
        @input = new_input
        {self, cmd}
      end
    else
      {self, Term2::Cmds.none}
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
