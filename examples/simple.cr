# Simple counter application built with Term2.
#
# Run with: crystal run examples/simple.cr
require "../src/term2"
include Term2::Prelude

class CounterModel < Model
  getter count : Int32

  def initialize(@count : Int32 = 0)
  end

  def init : Cmd
    Cmd.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        {self, Term2.quit}
      when "+", "="
        {CounterModel.new(count + 1), Cmd.none}
      when "-", "_"
        {CounterModel.new(count - 1), Cmd.none}
      when "r"
        {CounterModel.new, Cmd.none}
      else
        {self, Cmd.none}
      end
    else
      {self, Cmd.none}
    end
  end

  def view : String
    # Note: Framework handles cursor hide/show and screen clearing.
    # View just returns content to display.
    String.build do |str|
      str << "\n"
      str << "Counter: ".bold << count.to_s.cyan << "\n"
      str << "\n"
      str << "Commands: ".bold.yellow << "\n"
      str << "  " << "+/=".cyan << ": Increment\n"
      str << "  " << "-/_".cyan << ": Decrement\n"
      str << "  " << "r".cyan << ": Reset\n"
      str << "  " << "q".cyan << " or " << "Ctrl+C".cyan << ": Quit\n"
      str << "\n"
    end
  end
end

Term2.run(CounterModel.new)
