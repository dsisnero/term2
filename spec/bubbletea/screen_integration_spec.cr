require "../spec_helper"

class OptionsDummy
  include Term2::Model

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    {self, nil}
  end

  def view : String
    "ok"
  end
end

describe "BubbleTea parity: screen command sequences" do
  it "emits expected sequences for mouse modes and alt screen" do
    io = IO::Memory.new
    program = Term2::Program(OptionsDummy).new(OptionsDummy.new, output: io)

    program.process_message(Term2::EnableMouseCellMotionMsg.new)
    io.to_s.should contain("\e[?1002h")
    io.to_s.should contain("\e[?1006h")
    io.clear

    program.process_message(Term2::EnableMouseAllMotionMsg.new)
    io.to_s.should contain("\e[?1003h")
    io.to_s.should contain("\e[?1006h")
    io.clear

    program.process_message(Term2::DisableMouseTrackingMsg.new)
    io.to_s.should contain("\e[?1003l")
    io.to_s.should contain("\e[?1002l")
    io.to_s.should contain("\e[?1006l")
    io.clear

    program.process_message(Term2::EnterAltScreenMsg.new)
    io.to_s.should contain("\e[?1049h")
    io.clear
    program.process_message(Term2::ExitAltScreenMsg.new)
    io.to_s.should contain("\e[?1049l")
  end
end