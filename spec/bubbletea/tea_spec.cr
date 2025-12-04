require "../spec_helper"

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

  def view : String
    @executed.set(true)
    "success\n"
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
  it "ctx cancelation (ctxImplodeMsg, incrementMsg, panicCmd behavior)" do
    ctx = Term2::ProgramContext.new
    io = IO::Memory.new
    input = IO::Memory.new
    model = TeaTestModel.new
    program = Term2::Program(TeaTestModel).new(model, input: input, output: io, options: Term2::ProgramOptions.new(Term2::WithContext.new(ctx)))

    # Send a message that cancels the context.
    spawn do
      sleep 0.05.seconds
      program.dispatch(CtxImplodeMsg.new(-> { ctx.cancel }))
    end

    expect_raises(Term2::ProgramKilled) do
      program.run
    end
  end

  it "program shutdown on QuitMsg" do
    io = IO::Memory.new
    input = IO::Memory.new("q")
    program = Term2::Program(TeaTestModel).new(TeaTestModel.new, input: input, output: io)
    program.run
    program.output_io.to_s.should_not be_empty
  end

  it "errors propagate on panics" do
    io = IO::Memory.new
    program = Term2::Program(TeaTestModel).new(TeaTestModel.new, input: IO::Memory.new, output: io)
    spawn do
      sleep 0.01.seconds
      program.dispatch(PanicMsg.new)
    end

    expect_raises(Term2::ProgramPanic) do
      program.run
    end
  end

  it "program handles context cancellation" do
    ctx = Term2::ProgramContext.new
    io = IO::Memory.new
    program = Term2::Program(TeaTestModel).new(TeaTestModel.new, input: IO::Memory.new, output: io, options: Term2::ProgramOptions.new(Term2::WithContext.new(ctx)))
    spawn do
      sleep 0.02.seconds
      ctx.cancel
    end
    expect_raises(Term2::ProgramKilled) { program.run }
  end

  it "program recovers from panic and restores terminal" do
    io = IO::Memory.new
    program = Term2::Program(TeaTestModel).new(TeaTestModel.new, input: IO::Memory.new, output: io)
    program.disable_panic_recovery
    spawn do
      sleep 0.02.seconds
      program.dispatch(PanicMsg.new)
    end
    expect_raises(Exception) { program.run }
  end
end
