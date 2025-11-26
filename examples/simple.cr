# Simple counter application built with Term2.
#
# Run with: crystal run examples/simple.cr
require "../src/term2"
include Term2::Prelude

class CounterModel < Model
  getter count : Int32

  def initialize(@count : Int32 = 0)
  end
end

class CounterApp < Application(CounterModel)
  def init : CounterModel
    CounterModel.new
  end

  def update(msg : Message, model : CounterModel)
    case msg
    when KeyPress
      case msg.key
      when "q", "\u0003" # q or Ctrl+C
        {model, Cmd.quit}
      when "+", "="
        {CounterModel.new(model.count + 1), Cmd.none}
      when "-", "_"
        {CounterModel.new(model.count - 1), Cmd.none}
      when "r"
        {CounterModel.new, Cmd.none}
      else
        {model, Cmd.none}
      end
    else
      {model, Cmd.none}
    end
  end

  def view(model : CounterModel) : String
    # Note: Framework handles cursor hide/show and screen clearing.
    # View just returns content to display.
    String.build do |s|
      s << "\n"
      s << "Counter: ".bold << model.count.to_s.cyan << "\n"
      s << "\n"
      s << "Commands:".bold.yellow << "\n"
      s << "  +/=".cyan << ": Increment\n"
      s << "  -/_".cyan << ": Decrement\n"
      s << "  r".cyan << ": Reset\n"
      s << "  q".cyan << " or " << "Ctrl+C".cyan << ": Quit\n"
      s << "\n"
    end
  end
end

CounterApp.new.run
