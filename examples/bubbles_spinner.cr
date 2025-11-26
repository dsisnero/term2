require "../src/term2"
require "../src/bubbles/spinner"

class SpinnerModel < Term2::Model
  property spinner : Term2::Bubbles::Spinner

  def initialize
    @spinner = Term2::Bubbles::Spinner.new(Term2::Bubbles::Spinner::DOT)
    @spinner.style = Term2::Style.new(foreground: Term2::Color::MAGENTA)
  end
end

class SpinnerDemo < Term2::Application(SpinnerModel)
  def init : {SpinnerModel, Term2::Cmd}
    model = SpinnerModel.new
    {model, model.spinner.tick}
  end

  def update(msg : Term2::Message, model : SpinnerModel) : {SpinnerModel, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      if msg.key.to_s == "q" || msg.key.to_s == "ctrl+c"
        return {model, Term2::Cmd.quit}
      end
    end

    new_spinner, cmd = model.spinner.update(msg)
    model.spinner = new_spinner

    {model, cmd}
  end

  def view(model : SpinnerModel) : String
    "#{model.spinner.view} Loading... (press q to quit)"
  end
end

SpinnerDemo.new.run
