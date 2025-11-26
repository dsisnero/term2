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

# Custom messages for explicit actions
class Increment < Message
end

class Decrement < Message
end

class Reset < Message
end

class CounterModel < Model
  getter count : Int32

  def initialize(@count : Int32 = 0)
  end

  def init : Cmd
    Cmd.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when Increment
      {CounterModel.new(count + 1), Cmd.none}
    when Decrement
      {CounterModel.new(count - 1), Cmd.none}
    when Reset
      {CounterModel.new, Cmd.none}
    when Term2::KeyMsg
      handle_key(msg.key)
    else
      {self, Cmd.none}
    end
  end

  def view : String
    String.build do |str|
      str << "\n"
      str << "╔════════════════════════════════╗".bold.cyan << "\n"
      str << "║        Counter Example         ║".bold.cyan << "\n"
      str << "╚════════════════════════════════╝".bold.cyan << "\n"
      str << "\n"
      str << "  Count: ".bold << count.to_s.bright_cyan << "\n"
      str << "\n"
      str << "  Controls: ".bold.yellow << "\n"
      str << "    " << "+".cyan << "/" << "up".cyan << ": Increment\n"
      str << "    " << "-".cyan << "/" << "down".cyan << ": Decrement\n"
      str << "    " << "0".cyan << ": Reset\n"
      str << "    " << "q".cyan << "/" << "ctrl+c".cyan << ": Quit\n"
      str << "\n"
    end
  end

  private def handle_key(key : Term2::Key) : {Model, Cmd}
    case key.to_s
    when "+", "up"
      {CounterModel.new(count + 1), Cmd.none}
    when "-", "down"
      {CounterModel.new(count - 1), Cmd.none}
    when "0"
      {CounterModel.new, Cmd.none}
    when "q", "ctrl+c"
      {self, Term2.quit}
    else
      {self, Cmd.none}
    end
  end
end

Term2.run(CounterModel.new)
