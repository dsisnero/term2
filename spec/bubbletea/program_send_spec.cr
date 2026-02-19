require "../spec_helper"

class SendModel
  include Term2::Model
  getter count = Atomic(Int32).new(0)

  class IncrementMsg < Term2::Message; end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when IncrementMsg
      current = @count.get
      @count.set(current + 1)
      {self, Term2::Cmds.quit}
    else
      {self, nil}
    end
  end

  def view : Term2::View
    Term2.new_view("")
  end
end

describe "Program.send (Bubble Tea parity)" do
  it "routes external messages like dispatch" do
    opts = Term2::ProgramOptions.new(Term2::WithoutRenderer.new, Term2::WithoutSignalHandler.new)
    model = SendModel.new
    program = Term2::Program(SendModel).new(model, input: IO::Memory.new, output: IO::Memory.new, options: opts)
    program.send(SendModel::IncrementMsg.new)
    # Without a running loop, send only enqueues; it should not raise/crash.
    model.count.get.should eq(0)
  end

  it "delivers before run starts" do
    opts = Term2::ProgramOptions.new(Term2::WithoutRenderer.new, Term2::WithoutSignalHandler.new)
    model = SendModel.new
    program = Term2::Program(SendModel).new(model, input: IO::Memory.new, output: IO::Memory.new, options: opts)
    program.send(SendModel::IncrementMsg.new)
    model.count.get.should eq(0)
  end

  it "is a no-op after quit" do
    opts = Term2::ProgramOptions.new(Term2::WithoutRenderer.new, Term2::WithoutSignalHandler.new)
    model = SendModel.new
    program = Term2::Program(SendModel).new(model, input: IO::Memory.new, output: IO::Memory.new, options: opts)
    program.process_message(Term2::QuitMsg.new)
    program.send(SendModel::IncrementMsg.new)
    model.count.get.should eq(0)
  end
end
