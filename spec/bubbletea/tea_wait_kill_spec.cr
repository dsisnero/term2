require "../spec_helper"

class TeaWaitKillModel
  include Term2::Model
  getter executed = Atomic(Bool).new(false)

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
    @executed.set(true)
    "success\n"
  end
end

describe "BubbleTea parity: Wait/Kill basics" do
  it "waits for program completion" do
    io = IO::Memory.new
    input = IO::Memory.new("q")
    model = TeaWaitKillModel.new
    program = Term2::Program(TeaWaitKillModel).new(model, input: input, output: io)
    spawn { program.run }
    program.wait
  end

  it "kill triggers wait error" do
    io = IO::Memory.new
    model = TeaWaitKillModel.new
    program = Term2::Program(TeaWaitKillModel).new(model, input: IO::Memory.new, output: io)
    spawn { program.kill }
    expect_raises(Term2::ProgramKilled) do
      program.wait
    end
  end
end