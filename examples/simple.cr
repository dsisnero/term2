# Simple counter application built with Term2.
#
# Run with: crystal run examples/simple.cr
require "../src/term2"
include Term2::Prelude

# Define styles
LABEL_STYLE  = Term2::Style.new.bold(true)
VALUE_STYLE  = Term2::Style.new.cyan
HEADER_STYLE = Term2::Style.new.bold(true).yellow
KEY_STYLE    = Term2::Style.new.cyan

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
    when Term2::KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        {self, Term2.quit}
      when "+", "="
        {CounterModel.new(count + 1), Cmds.none}
      when "-", "_"
        {CounterModel.new(count - 1), Cmds.none}
      when "r"
        {CounterModel.new, Cmds.none}
      else
        {self, Cmds.none}
      end
    else
      {self, Cmds.none}
    end
  end

  def view : String
    # Note: Framework handles cursor hide/show and screen clearing.
    # View just returns content to display.
    String.build do |str|
      str << "\n"
      str << LABEL_STYLE.render("Counter: ") << VALUE_STYLE.render(count.to_s) << "\n"
      str << "\n"
      str << HEADER_STYLE.render("Commands: ") << "\n"
      str << "  " << KEY_STYLE.render("+/=") << ": Increment\n"
      str << "  " << KEY_STYLE.render("-/_") << ": Decrement\n"
      str << "  " << KEY_STYLE.render("r") << ": Reset\n"
      str << "  " << KEY_STYLE.render("q") << " or " << KEY_STYLE.render("Ctrl+C") << ": Quit\n"
      str << "\n"
    end
  end
end

Term2.run(CounterModel.new)
