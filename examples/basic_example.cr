# Basic counter application with message types
#
# This example demonstrates:
# - Custom message types for actions
# - Key handling
# - Styled output using Lipgloss::Style
#
# Run with: crystal run examples/basic_example.cr
require "../src/term2"
include Term2::Prelude

# Define styles
TITLE_STYLE = Lipgloss::Style.new
  .bold(true)
  .foreground(Lipgloss::Color::CYAN)

COUNT_STYLE = Lipgloss::Style.new
  .bold(true)
  .foreground(Lipgloss::Color::BRIGHT_CYAN)

LABEL_STYLE = Lipgloss::Style.new
  .bold(true)

CONTROLS_STYLE = Lipgloss::Style.new
  .bold(true)
  .foreground(Lipgloss::Color::YELLOW)

KEY_STYLE = Lipgloss::Style.new
  .foreground(Lipgloss::Color::CYAN)

# Custom messages for explicit actions
class Increment < Term2::Message
end

class Decrement < Term2::Message
end

class Reset < Term2::Message
end

class CounterModel
  include Term2::Model

  getter count : Int32

  def initialize(@count : Int32 = 0)
  end

  def init : Term2::Cmd
    Term2::Cmds.none
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Increment
      {CounterModel.new(count + 1), Term2::Cmds.none}
    when Decrement
      {CounterModel.new(count - 1), Term2::Cmds.none}
    when Reset
      {CounterModel.new, Term2::Cmds.none}
    when Term2::KeyMsg
      handle_key(msg.string)
    else
      {self, Term2::Cmds.none}
    end
  end

  def view : String
    String.build do |str|
      str << "\n"
      str << TITLE_STYLE.render("╔════════════════════════════════╗") << "\n"
      str << TITLE_STYLE.render("║        Counter Example         ║") << "\n"
      str << TITLE_STYLE.render("╚════════════════════════════════╝") << "\n"
      str << "\n"
      str << LABEL_STYLE.render("  Count: ") << COUNT_STYLE.render(count.to_s) << "\n"
      str << "\n"
      str << CONTROLS_STYLE.render("  Controls:") << "\n"
      str << "    " << KEY_STYLE.render("+") << "/" << KEY_STYLE.render("up") << ": Increment\n"
      str << "    " << KEY_STYLE.render("-") << "/" << KEY_STYLE.render("down") << ": Decrement\n"
      str << "    " << KEY_STYLE.render("0") << ": Reset\n"
      str << "    " << KEY_STYLE.render("q") << "/" << KEY_STYLE.render("ctrl+c") << ": Quit\n"
      str << "\n"
    end
  end

  private def handle_key(key : String) : {Term2::Model, Term2::Cmd}
    case key
    when "+", "up"
      {CounterModel.new(count + 1), Term2::Cmds.none}
    when "-", "down"
      {CounterModel.new(count - 1), Term2::Cmds.none}
    when "0"
      {CounterModel.new, Term2::Cmds.none}
    when "q", "ctrl+c"
      {self, Term2::Cmds.quit}
    else
      {self, Term2::Cmds.none}
    end
  end
end

Term2.run(CounterModel.new)
