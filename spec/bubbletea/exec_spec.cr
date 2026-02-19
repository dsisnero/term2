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

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd?}
    case msg
    when ExecFinishedMsg
      @err = msg.err
      {self, Term2::Cmds.quit}
    else
      {self, nil}
    end
  end

  def view : Term2::View
    Term2.new_view("\n")
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

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd?}
    case msg
    when ExecErrorMsg
      @err = msg.err
      {self, Term2::Cmds.quit}
    else
      {self, nil}
    end
  end

  def view : Term2::View
    Term2.new_view("\n")
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
      program = Term2::Program.new(TestExecModel.new(tc[:cmd]), input: IO::Memory.new, output: output, options: Term2::ProgramOptions.new(Term2::WithoutSignalHandler.new))
      done = Channel(Exception?).new(1)
      callback = ->(err : Exception?) { done.send(err); nil.as(Term2::Msg?) }
      program.process_message(Term2::ExecMsg.new(tc[:cmd], callback: callback))
      err = done.receive

      if tc[:expect_err]
        err.should_not be_nil
      else
        err.should be_nil
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
      program = Term2::Program.new(TestExecErrorModel.new(tc[:cmd]), input: IO::Memory.new, output: output, options: Term2::ProgramOptions.new(Term2::WithoutSignalHandler.new))
      done = Channel(Exception?).new(1)
      callback = ->(err : Exception?) { done.send(err); nil.as(Term2::Msg?) }
      program.process_message(Term2::ExecMsg.new(tc[:cmd], callback: callback))
      err = done.receive

      if tc[:expect_err]
        err.should_not be_nil
      else
        err.should be_nil
      end
    end
  end
end
