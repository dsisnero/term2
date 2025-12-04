require "../spec_helper"

class SimpleExampleModel
  include Term2::Model

  def initialize(@count : Int32 = 10)
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      {self, Term2::Cmds.quit}
    else
      {self, nil}
    end
  end

  def view : String
    "Counter: #{@count}"
  end
end

describe "Bubbletea parity: examples/simple main_test.go" do
  it "simple example outputs content and quits" do
    io = IO::Memory.new
    input = IO::Memory.new("q")
    program = Term2::Program(SimpleExampleModel).new(SimpleExampleModel.new(10), input: input, output: io)
    program.run
    io.to_s.should contain("Counter")
  end
end
