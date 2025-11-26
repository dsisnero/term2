# Basic counter application with message types
#
# This example demonstrates:
# - Custom message types for actions
# - Key handling
# - Styled output using the DSL
#
# Run with: crystal run examples/basic_example.cr
require "../src/term2"
include Term2::Prelude

class CounterModel < Model
  getter count : Int32

  def initialize(@count : Int32 = 0)
  end
end

# Custom messages for explicit actions
class Increment < Message
end

class Decrement < Message
end

class Reset < Message
end

class CounterApp < Application(CounterModel)
  def init
    CounterModel.new
  end

  def update(msg : Message, model : CounterModel)
    m = model
    case msg
    when Increment
      {CounterModel.new(m.count + 1), Cmd.none}
    when Decrement
      {CounterModel.new(m.count - 1), Cmd.none}
    when Reset
      {CounterModel.new, Cmd.none}
    when KeyPress
      handle_key(msg.key, m)
    else
      {model, Cmd.none}
    end
  end

  def view(model : CounterModel) : String
    m = model.as(CounterModel)
    String.build do |str|
      str << "\n"
      str << (S.bold.cyan | "╔════════════════════════════════╗") << "\n"
      str << (S.bold.cyan | "║        Counter Example         ║") << "\n"
      str << (S.bold.cyan | "╚════════════════════════════════╝") << "\n"
      str << "\n"
      str << "  Count: ".bold << m.count.to_s.bright_cyan << "\n"
      str << "\n"
      str << "  Controls: ".bold.yellow << "\n"
      str << "    " << "+".cyan << "/" << "up".cyan << ": Increment\n"
      str << "    " << "-".cyan << "/" << "down".cyan << ": Decrement\n"
      str << "    " << "0".cyan << ": Reset\n"
      str << "    " << "q".cyan << "/" << "ctrl+c".cyan << ": Quit\n"
      str << "\n"
    end
  end

  private def handle_key(key : String, model : CounterModel) : {CounterModel, Cmd}
    case key
    when "+", "up"
      {CounterModel.new(model.count + 1), Cmd.none}
    when "-", "down"
      {CounterModel.new(model.count - 1), Cmd.none}
    when "0"
      {CounterModel.new, Cmd.none}
    when "q", "\u0003" # q or Ctrl+C
      {model, Cmd.quit}
    else
      {model, Cmd.none}
    end
  end
end

CounterApp.new.run
