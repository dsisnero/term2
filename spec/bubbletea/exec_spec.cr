require "../spec_helper"

class ExecTestModel
  include Term2::Model

  getter err : Exception?

  def initialize(@cmd : String, @err : Exception? = nil)
  end

  def init : Term2::Cmd
    Term2::Cmds.exec_process(@cmd) { |err| ExecFinishedMsg.new(err) }
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when ExecFinishedMsg
      @err = msg.err
      {self, Term2::Cmds.quit}
    else
      {self, nil}
    end
  end

  def view : String
    "\n"
  end
end

class ExecFinishedMsg < Term2::Message
  getter err : Exception?

  def initialize(@err : Exception?); end
end

describe "BubbleTea parity: Exec" do
  it "captures errors for invalid command" do
    model = ExecTestModel.new("invalid_command_zzz")
    program = Term2::Program(ExecTestModel).new(model, input: IO::Memory.new, output: IO::Memory.new)
    program.run
    model.err.should_not be_nil
  end
end