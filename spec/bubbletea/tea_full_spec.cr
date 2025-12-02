require "../spec_helper"

class TeaFullModel
  include Term2::Model
  getter executed = Atomic(Bool).new(false)
  getter counter = Atomic(Int32).new(0)
  getter panic_seen = Atomic(Bool).new(false)

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      {self, Term2::Cmds.quit}
    when PanicMsg
      @panic_seen.set(true)
      {self, nil}
    when IncrementMsg
      @counter.add(1)
      {self, nil}
    else
      {self, nil}
    end
  end

  def view : String
    @executed.set(true)
    "success\n"
  end
end

class PanicMsg < Term2::Message; end

class IncrementMsg < Term2::Message; end

describe "BubbleTea parity: tea lifecycle basics (partial)" do
  it "runs and quits on key" do
    output_io = IO::Memory.new
    input = IO::Memory.new("q")
    program = Term2::Program(TeaFullModel).new(TeaFullModel.new, input: input, output: output_io)
    program.run
    output_io.to_s.should_not be_empty
  end
end