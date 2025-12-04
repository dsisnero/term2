require "../spec_helper"

class TeaConcurrencyModel
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

  def view : String
    @executed.set(true)
    "success\n"
  end
end

describe "BubbleTea parity: wait with concurrent callers" do
  it "allows multiple wait calls" do
    output_io = IO::Memory.new
    model = TeaConcurrencyModel.new
    program = Term2::Program(TeaConcurrencyModel).new(model, input: IO::Memory.new("q"), output: output_io)

    err_chan = Channel(Exception?).new

    spawn do
      begin
        program.run
        err_chan.send(nil)
      rescue ex
        err_chan.send(ex)
      end
    end

    waits = [] of Fiber
    3.times do
      waits << spawn do
        begin
          program.wait
          err_chan.send(nil)
        rescue ex
          err_chan.send(ex)
        end
      end
    end

    # Collect errors
    4.times do
      if ex = err_chan.receive
        raise ex
      end
    end
  end
end
