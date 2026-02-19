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

  def view : Term2::View
    @executed = true
    Term2.new_view("success\n")
  end
end

describe "BubbleTea parity: tea lifecycle basics" do
  it "produces a non-empty view" do
    model = TeaLifecycleModel.new
    view = model.view
    view.content.should_not be_empty
  end
end
