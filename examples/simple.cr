require "../src/term2"

# Simple counter application built with Term2.
class CounterApp < Term2::Application
  class CounterModel < Term2::Model
    getter count : Int32

    def initialize(@count : Int32 = 0)
    end
  end

  def init
    {CounterModel.new, Term2::Cmd.none}
  end

  def update(msg : Term2::Message, model : Term2::Model)
    counter = model.as(CounterModel)

    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        {counter, Term2::Cmd.quit}
      when "+", "="
        {CounterModel.new(counter.count + 1), Term2::Cmd.none}
      when "-", "_"
        {CounterModel.new(counter.count - 1), Term2::Cmd.none}
      when "r"
        {CounterModel.new, Term2::Cmd.none}
      else
        {model, Term2::Cmd.none}
      end
    else
      {model, Term2::Cmd.none}
    end
  end

  def view(model : Term2::Model) : String
    counter = model.as(CounterModel)
    <<-TERMINAL
    \033[?25l\033[2J\033[H
    Counter: #{counter.count}

    Commands:
      +/=: Increment
      -/_: Decrement
      r: Reset
      q or Ctrl+C: Quit
    \033[?25h
    TERMINAL
  end
end

CounterApp.new.run
