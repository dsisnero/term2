require "../spec_helper"

class TeaFilterModel
  include Term2::Model
  getter shutdowns = Atomic(Int32).new(0)

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::QuitMsg
      {self, Term2::Cmds.quit}
    else
      {self, nil}
    end
  end

  def view : String
    "ok"
  end
end

describe "BubbleTea parity: filter prevents quit" do
  it "filters QuitMsg configurable times" do
    [0, 1, 2].each do |prevent_count|
      io = IO::Memory.new
      model = TeaFilterModel.new
      shutdowns = Atomic(Int32).new(0)
      filter = ->(msg : Term2::Msg?) do
        if msg.is_a?(Term2::QuitMsg) && shutdowns.get < prevent_count
          shutdowns.add(1)
          nil
        else
          msg
        end
      end
      opts = Term2::ProgramOptions.new(Term2::WithFilter.new(filter.as(Proc(Term2::Msg?, Term2::Msg?))))
      program = Term2::Program(TeaFilterModel).new(model, input: IO::Memory.new, output: io, options: opts)

      done = Channel(Nil).new
      spawn do
        program.run
        done.send(nil)
      end

      # Send quit messages; once we've filtered enough, send a final quit to exit.
      20.times do
        program.quit
        sleep 1.millisecond
        if shutdowns.get >= prevent_count
          program.quit
          break
        end
      end

      select
      when done.receive
      when timeout(2.seconds)
        raise "program did not finish"
      end
      program.wait
      shutdowns.get.should eq(prevent_count)
    end
  end
end
