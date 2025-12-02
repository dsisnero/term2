require "../spec_helper"

class ScreenDummyModel
  include Term2::Model

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    {self, nil}
  end

  def view : String
    "success"
  end
end

describe "BubbleTea parity: screen commands" do
  it "renders clear screen" do
    io = IO::Memory.new
    program = Term2::Program(ScreenDummyModel).new(ScreenDummyModel.new, output: io)
    program.process_message(Term2::ClearScreenMsg.new)
    io.to_s.should contain("\e[2J")
  end

  it "enters/exits alt screen" do
    io = IO::Memory.new
    program = Term2::Program(ScreenDummyModel).new(ScreenDummyModel.new, output: io)
    program.process_message(Term2::EnterAltScreenMsg.new)
    program.process_message(Term2::ExitAltScreenMsg.new)
    io.to_s.should contain("\e[?1049h")
    io.to_s.should contain("\e[?1049l")
  end
end