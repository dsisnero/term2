# Basic counter application with message types
#
# This example demonstrates:
# - Custom message types for actions
# - Key handling
# - Styled output using Term2::Style
#
# Run with: crystal run examples/basic_example.cr
require "../src/term2"
include Term2::Prelude

# Define styles
TITLE_STYLE = Term2::Style.new
  .bold(true)
  .cyan

COUNT_STYLE = Term2::Style.new
  .bold(true)
  .bright_cyan

LABEL_STYLE = Term2::Style.new
  .bold(true)

CONTROLS_STYLE = Term2::Style.new
  .bold(true)
  .yellow

KEY_STYLE = Term2::Style.new
  .cyan

# Custom messages for explicit actions
class Increment < Message
end

class Decrement < Message
end

class Reset < Message
end

class CounterModel
  include Model

  getter count : Int32

  def initialize(@count : Int32 = 0)
  end

  def init : Cmd
    Cmds.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when Increment
      {CounterModel.new(count + 1), Cmds.none}
    when Decrement
      {CounterModel.new(count - 1), Cmds.none}
    when Reset
      {CounterModel.new, Cmds.none}
    when Term2::KeyMsg
      handle_key(msg.key)
    else
      {self, Cmds.none}
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

  private def handle_key(key : Term2::Key) : {Model, Cmd}
    case key.to_s
    when "+", "up"
      {CounterModel.new(count + 1), Cmds.none}
    when "-", "down"
      {CounterModel.new(count - 1), Cmds.none}
    when "0"
      {CounterModel.new, Cmds.none}
    when "q", "ctrl+c"
      {self, Term2.quit}
    else
      {self, Cmds.none}
    end
  end
end

Term2.run(CounterModel.new)
