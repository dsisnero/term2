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

  def view : String
    ""
  end
end

describe "Program.send (Bubble Tea parity)" do
  it "routes external messages like dispatch" do
    io_out = IO::Memory.new
    program = Term2::Program(SendModel).new(SendModel.new, input: IO::Memory.new, output: io_out)

    result_chan = Channel(SendModel).new(1)
    spawn do
      model = program.run
      result_chan.send(model)
    end

    sleep 20.milliseconds
    program.send(SendModel::IncrementMsg.new)

    final_model = result_chan.receive
    final_model.count.get.should eq(1)
  end

  it "blocks before run starts and then delivers" do
    program = Term2::Program(SendModel).new(SendModel.new, input: IO::Memory.new, output: IO::Memory.new)
    done = Channel(Nil).new(1)

    spawn do
      program.send(SendModel::IncrementMsg.new)
      done.send(nil)
    end

    program.run
    select
    when done.receive
    when timeout(1.second)
      raise "send did not unblock"
    end
  end

  it "is a no-op after quit" do
    program = Term2::Program(SendModel).new(SendModel.new, input: IO::Memory.new("q"), output: IO::Memory.new)
    program.run

    program.send(SendModel::IncrementMsg.new) # should not block
  end
end
