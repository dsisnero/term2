require "../spec_helper"

class FilterModel
  include Term2::Model
  getter filtered = Atomic(Bool).new(false)

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      {self, Term2::Cmds.quit}
    when FilteredMsg
      @filtered.set(true)
      {self, Term2::Cmds.quit}
    else
      {self, nil}
    end
  end

  def view : String
    "ok"
  end
end

class FilteredMsg < Term2::Message; end

describe "BubbleTea parity: message filter" do
  it "applies filter before update" do
    filter = ->(msg : Term2::Msg) do
      msg.is_a?(Term2::KeyMsg) ? FilteredMsg.new : msg
    end
    opts = Term2::ProgramOptions.new(Term2::WithFilter.new(filter))
    program = Term2::Program(FilterModel).new(FilterModel.new, input: IO::Memory.new("q"), output: IO::Memory.new, options: opts)
    program.run
    program.model.as(FilterModel).filtered.get.should be_true
  end
end
