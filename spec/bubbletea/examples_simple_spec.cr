require "../spec_helper"

describe "BubbleTea parity: examples/simple" do
  it "renders output without error" do
    io = IO::Memory.new
    input = IO::Memory.new("q")
    program = Term2::Program(SimpleExampleModel).new(SimpleExampleModel.new, input: input, output: io)
    program.run
    io.to_s.should contain("hi")
  end
end

class SimpleExampleModel
  include Term2::Model

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg then {self, Term2::Cmds.quit}
    else                    {self, nil}
    end
  end

  def view : String
    "hi"
  end
end