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

  def view : Term2::View
    @executed.set(true)
    Term2.new_view("success\n")
  end
end

describe "BubbleTea parity: wait with concurrent callers" do
  it "allows multiple wait calls" do
    output_io = IO::Memory.new
    model = TeaConcurrencyModel.new
    options = Term2::ProgramOptions.new(Term2::WithoutSignalHandler.new)
    program = Term2::Program(TeaConcurrencyModel).new(model, input: IO::Memory.new, output: output_io, options: options)

    err_chan = Channel(Exception?).new(3)

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

    spawn { program.stop }

    # Collect errors
    3.times do
      if ex = err_chan.receive
        raise ex
      end
    end
  end
end
