require "../spec_helper"

class TeaModel
  include Term2::Model
  getter quit_called = false

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::QuitMsg
      @quit_called = true
      {self, nil}
    else
      {self, nil}
    end
  end

  def view : String
    "ok"
  end
end

describe "BubbleTea parity: program lifecycle" do
  it "handles quit" do
    model = TeaModel.new
    program = Term2::Program(TeaModel).new(model, input: IO::Memory.new, output: IO::Memory.new)
    program.process_message(Term2::QuitMsg.new)
    model.quit_called.should be_true
  end
end