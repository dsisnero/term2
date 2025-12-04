require "../spec_helper"

class ScreenOutputModel
  include Term2::Model

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    {self, nil}
  end

  def view : String
    "success"
  end
end

describe "BubbleTea parity: screen output sequences" do
  it "prints clear screen sequence" do
    io = IO::Memory.new
    program = Term2::Program(ScreenOutputModel).new(ScreenOutputModel.new, output: io)
    program.process_message(Term2::ClearScreenMsg.new)
    io.to_s.should contain("\e[2J")
  end

  it "prints alt screen sequences on enter/exit" do
    io = IO::Memory.new
    program = Term2::Program(ScreenOutputModel).new(ScreenOutputModel.new, output: io)
    program.process_message(Term2::EnterAltScreenMsg.new)
    program.process_message(Term2::ExitAltScreenMsg.new)
    text = io.to_s
    text.should contain("\e[?1049h")
    text.should contain("\e[?1049l")
  end
end
