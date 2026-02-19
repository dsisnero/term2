require "../spec_helper"

class TeaTestModel
  include Term2::Model
  getter executed = Atomic(Bool).new(false)
  getter counter = Atomic(Int32).new(0)

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when CtxImplodeMsg
      msg.cancel.call
      sleep 0.1.seconds
      {self, nil}
    when IncrementMsg
      current = @counter.get
      @counter.set(current + 1)
      {self, nil}
    when Term2::KeyMsg
      {self, Term2::Cmds.quit}
    when PanicMsg
      raise "testing panic behavior"
    else
      {self, nil}
    end
  end

  def view : Term2::View
    @executed.set(true)
    Term2.new_view("success")
  end
end

class CtxImplodeMsg < Term2::Message
  getter cancel : -> Nil

  def initialize(@cancel : -> Nil)
  end
end

class IncrementMsg < Term2::Message; end

class PanicMsg < Term2::Message; end

describe "Bubbletea parity: tea_test.go" do
  it "ctx cancelation (ctxImplodeMsg behavior)" do
    ctx = Term2::ProgramContext.new
    program = Term2::Program(TeaTestModel).new(
      TeaTestModel.new,
      input: IO::Memory.new,
      output: IO::Memory.new,
      options: Term2::ProgramOptions.new(Term2::WithContext.new(ctx), Term2::WithoutSignalHandler.new)
    )
    ctx.cancelled?.should be_false
    program.process_message(CtxImplodeMsg.new(-> { ctx.cancel }))
    ctx.cancelled?.should be_true
  end

  it "program shutdown on QuitMsg" do
    program = Term2::Program(TeaTestModel).new(
      TeaTestModel.new,
      input: IO::Memory.new,
      output: IO::Memory.new,
      options: Term2::ProgramOptions.new(Term2::WithoutSignalHandler.new)
    )
    program.process_message(Term2::QuitMsg.new)
  end

  it "errors propagate on panics" do
    program = Term2::Program(TeaTestModel).new(
      TeaTestModel.new,
      input: IO::Memory.new,
      output: IO::Memory.new,
      options: Term2::ProgramOptions.new(Term2::WithoutSignalHandler.new)
    )
    expect_raises(Term2::ProgramPanic) do
      program.process_message(PanicMsg.new)
    end
  end

  it "program handles context cancellation" do
    ctx = Term2::ProgramContext.new
    program = Term2::Program(TeaTestModel).new(
      TeaTestModel.new,
      input: IO::Memory.new,
      output: IO::Memory.new,
      options: Term2::ProgramOptions.new(Term2::WithContext.new(ctx), Term2::WithoutSignalHandler.new)
    )
    ctx.cancelled?.should be_false
    ctx.cancel
    ctx.cancelled?.should be_true
    ctx.cancel_evt.poll.is_a?(CML::Enabled(Bool)).should be_true
  end

  it "program recovers from panic and restores terminal" do
    program = Term2::Program(TeaTestModel).new(
      TeaTestModel.new,
      input: IO::Memory.new,
      output: IO::Memory.new,
      options: Term2::ProgramOptions.new(Term2::WithoutSignalHandler.new)
    )
    program.disable_panic_recovery
    expect_raises(Exception) { program.process_message(PanicMsg.new) }
  end
end
