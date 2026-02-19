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

  def view : Term2::View
    @executed.set(true)
    Term2.new_view("success\n")
  end
end

describe "BubbleTea parity: Wait/Kill basics" do
  it "waits for program completion" do
    io = IO::Memory.new
    model = TeaWaitKillModel.new
    options = Term2::ProgramOptions.new(Term2::WithoutSignalHandler.new)
    program = Term2::Program(TeaWaitKillModel).new(model, input: IO::Memory.new, output: io, options: options)
    spawn { program.stop }
    program.wait
  end

  it "kill triggers wait error" do
    io = IO::Memory.new
    model = TeaWaitKillModel.new
    options = Term2::ProgramOptions.new(Term2::WithoutSignalHandler.new)
    program = Term2::Program(TeaWaitKillModel).new(model, input: IO::Memory.new, output: io, options: options)
    begin
      program.kill
    rescue Term2::ProgramKilled
    end
    expect_raises(Term2::ProgramKilled) do
      program.wait
    end
  end
end
