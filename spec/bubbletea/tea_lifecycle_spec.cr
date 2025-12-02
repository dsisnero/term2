require "../spec_helper"

class TeaLifecycleModel
  include Term2::Model
  getter executed : Bool = false
  getter counter : Int32 = 0

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      return {self, Term2::Cmds.quit}
    when Term2::Message
      # noop
    end
    {self, nil}
  end

  def view : String
    @executed = true
    "success\n"
  end
end

describe "BubbleTea parity: tea lifecycle basics" do
  it "runs and outputs view" do
    output_io = IO::Memory.new
    input = IO::Memory.new("q")
    program = Term2::Program(TeaLifecycleModel).new(TeaLifecycleModel.new, input: input, output: output_io, options: Term2::ProgramOptions.new)
    program.run
    output_io.to_s.should_not be_empty
  end
end