# Simple Term2 v2 example with a View-based render.
#
# Run with: crystal run examples/v2/simple.cr
require "../../src/term2"
include Term2::Prelude

HEADER_STYLE = Lipgloss::Style.new.bold(true).foreground(Lipgloss::Color::YELLOW)
HELP_STYLE   = Lipgloss::Style.new.foreground(Lipgloss::Color::CYAN)

class SimpleModel
  include Model

  def init : Cmd
    Cmds.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        {self, Term2.quit}
      else
        {self, Cmds.none}
      end
    else
      {self, Cmds.none}
    end
  end

  def view : Term2::View
    content = String.build do |str|
      str << "\n"
      str << HEADER_STYLE.render("Term2 v2 Simple") << "\n\n"
      str << "This example returns a View struct." << "\n\n"
      str << HELP_STYLE.render("Press q to quit.") << "\n"
    end

    Term2::View.new(content: content, window_title: "Term2 v2 Simple")
  end
end

Term2.run(SimpleModel.new)
