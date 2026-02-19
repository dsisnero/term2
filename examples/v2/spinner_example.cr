# Spinner example using the View API.
#
# Run with: crystal run examples/v2/spinner_example.cr
require "../../src/term2"
require "../../src/components/spinner"
include Term2::Prelude

class SpinnerModel
  include Model

  property spinner : Term2::Components::Spinner

  def initialize
    @spinner = Term2::Components::Spinner.new(Term2::Components::Spinner::LINE)
    @spinner.style = Lipgloss::Style.new.foreground(Lipgloss::Color::MAGENTA)
  end

  def init : Cmd
    @spinner.tick
  end

  def update(msg : Term2::Msg) : {Model, Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        return {self, Term2.quit}
      end
    end

    new_spinner, cmd = @spinner.update(msg)
    @spinner = new_spinner

    {self, cmd}
  end

  def view : Term2::View
    content = "#{@spinner.view.content} Loading... (press q to quit)"
    Term2::View.new(content: content, window_title: "Term2 v2 Spinner")
  end
end

Term2.run(SpinnerModel.new)
