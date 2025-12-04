require "../src/term2"
require "../src/components/spinner"

class SpinnerModel
  include Term2::Model
  property spinner : Term2::Components::Spinner

  def initialize
    @spinner = Term2::Components::Spinner.new(Term2::Components::Spinner::DOT)
    @spinner.style = Term2::Style.new.magenta
  end

  def init : Term2::Cmd
    @spinner.tick
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      if msg.key.to_s == "q" || msg.key.to_s == "ctrl+c"
        return {self, Term2.quit}
      end
    end

    new_spinner, cmd = @spinner.update(msg)
    @spinner = new_spinner

    {self, cmd}
  end

  def view : String
    "#{@spinner.view} Loading... (press q to quit)"
  end
end

Term2.run(SpinnerModel.new)
