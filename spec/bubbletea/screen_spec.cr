require "../spec_helper"

class ScreenSpecModel
  include Term2::Model
  getter last_size = {0, 0}

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::WindowSizeMsg
      @last_size = {msg.width, msg.height}
    end
    {self, nil}
  end

  def view : String
    "ok"
  end
end

describe "Bubbletea parity: screen_test.go" do
  it "screen render and resize handling" do
    io = IO::Memory.new
    program = Term2::Program(ScreenSpecModel).new(ScreenSpecModel.new, output: io)
    program.process_message(Term2::WindowSizeMsg.new(80, 24))
    program.model.last_size.should eq({80, 24})

    program.process_message(Term2::ClearScreenMsg.new)
    io.to_s.should contain("\e[2J")
  end
end
