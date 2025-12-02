require "../src/term2"

class TestModel
  include Term2::Model

  def init : Term2::Cmd
    Term2::Cmds.none
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::WindowSizeMsg
      puts "Window size: #{msg.width}x#{msg.height}"
    end
    {self, Term2::Cmds.none}
  end

  def view : String
    "Hello from Term2!\n"
  end
end

if PROGRAM_NAME.includes?(__FILE__)
  model = TestModel.new
  Term2.run(model)
end
