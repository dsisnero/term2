require "../spec_helper"

class ScreenTestModel
  include Term2::Model

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      {self, Term2::Cmds.quit}
    else
      {self, nil}
    end
  end

  def view : String
    "success"
  end
end

describe "BubbleTea parity: screen command sequences (basic)" do
  it "emits escape sequences for clear and mouse toggles" do
    io = IO::Memory.new
    program = Term2::Program(ScreenTestModel).new(ScreenTestModel.new, input: IO::Memory.new, output: io)

    program.process_message(Term2::ClearScreenMsg.new)
    io.to_s.should contain("\e[2J")
    io.clear

    program.process_message(Term2::EnableMouseCellMotionMsg.new)
    io.to_s.should contain("\e[?1002h")
    io.to_s.should contain("\e[?1006h")
    io.clear

    program.process_message(Term2::EnableMouseAllMotionMsg.new)
    io.to_s.should contain("\e[?1003h")
    io.to_s.should contain("\e[?1006h")
    io.clear

    program.process_message(Term2::DisableMouseTrackingMsg.new)
    io.to_s.should contain("\e[?1002l")
    io.to_s.should contain("\e[?1003l")
    io.to_s.should contain("\e[?1006l")
  end
end