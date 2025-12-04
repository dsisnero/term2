require "../spec_helper"

class ExecFinishedMsg < Term2::Message
  getter err : Exception?

  def initialize(@err : Exception?)
  end
end

class TestExecModel
  include Term2::Model
  getter cmd : String
  getter err : Exception?

  def initialize(@cmd : String, @err : Exception? = nil)
  end

  def init : Term2::Cmd
    Term2::Cmds.exec_process(@cmd) { |err| ExecFinishedMsg.new(err) }
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd?}
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

class ExecErrorMsg < Term2::Message
  getter err : Exception?
  def initialize(@err : Exception?)
  end
end

class TestExecErrorModel
  include Term2::Model
  getter cmd : String
  getter err : Exception?

  def initialize(@cmd : String, @err : Exception? = nil)
  end

  def init : Term2::Cmd
    Term2::Cmds.exec_process(@cmd) { |err| ExecErrorMsg.new(err) }
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd?}
    case msg
    when ExecErrorMsg
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

describe "Bubbletea parity: exec_test.go" do
  # Mirrors exec_test.go: ensure exec runs commands and captures failures.
  it "exec command runs and captures output" do

    tests = [{name: "invalid command", cmd: "invalid", expect_err: true}]
    {% unless flag?(:win32) %}
      tests << {name: "true", cmd: "true", expect_err: false}
      tests << {name: "false", cmd: "false", expect_err: true}
    {% end %}

    tests.each do |tc|
      output = IO::Memory.new
      input = IO::Memory.new
      model = TestExecModel.new(tc[:cmd])
      program = Term2::Program.new(model, input: input, output: output)

      program.run

      if tc[:expect_err]
        model.err.should_not be_nil
      else
        model.err.should be_nil
      end
    end
  end

  it "exec propagation of exit errors" do
    # On Windows only invalid command case is meaningful.
    tests = [{name: "invalid command", cmd: "invalid", expect_err: true}]
    {% unless flag?(:win32) %}
      tests << {name: "false exits non-zero", cmd: "false", expect_err: true}
    {% end %}

    tests.each do |tc|
      output = IO::Memory.new
      input = IO::Memory.new
      model = TestExecErrorModel.new(tc[:cmd])
      program = Term2::Program.new(model, input: input, output: output)

      program.run

      if tc[:expect_err]
        model.err.should_not be_nil
      else
        model.err.should be_nil
      end
    end
  end
end
