require "../src/term2"

# A simple counter application
class CounterApp < Term2::Application
  class Model < Term2::Model
    getter count : Int32

    def initialize(@count : Int32 = 0)
    end
  end

  class Increment < Term2::Message
  end

  class Decrement < Term2::Message
  end

  class Reset < Term2::Message
  end

  def init
    {Model.new, Term2::Cmd.none}
  end

  def update(msg : Term2::Message, model : Term2::Model)
    m = model.as(Model)
    case msg
    when Increment
      {Model.new(m.count + 1), Term2::Cmd.none}
    when Decrement
      {Model.new(m.count - 1), Term2::Cmd.none}
    when Reset
      {Model.new, Term2::Cmd.none}
    when Term2::KeyMsg
      handle_key(msg.key, m)
    else
      {model, Term2::Cmd.none}
    end
  end

  def view(model : Term2::Model) : String
    m = model.as(Model)
    String.build do |str|
      str << "\n"
      str << "Counter: #{m.count}\n"
      str << "\n"
      str << "Controls:\n"
      str << "  + / up: Increment\n"
      str << "  - / down: Decrement\n"
      str << "  0: Reset\n"
      str << "  q / ctrl+c: Quit\n"
      str << "\n"
    end
  end

  private def handle_key(key : Term2::Key, model : Model) : {Model, Term2::Cmd}
    case key.to_s
    when "+", "up"
      {Model.new(model.count + 1), Term2::Cmd.none}
    when "-", "down"
      {Model.new(model.count - 1), Term2::Cmd.none}
    when "0"
      {Model.new, Term2::Cmd.none}
    when "q", "ctrl+c"
      {model, Term2::Cmd.quit}
    else
      {model, Term2::Cmd.none}
    end
  end
end

# Run the application
app = CounterApp.new
app.run
