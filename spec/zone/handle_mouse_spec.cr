require "../spec_helper"

# Simple test model that captures messages
class ZoneMouseTestModel
  include Term2::Model
  getter received = [] of Term2::Msg

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    @received << msg
    {self, nil}
  end

  def view : String
    ""
  end
end

describe "Term2::Zone mouse handling (v2‑exp)" do
  before_each do
    Term2::Zone.reset
  end

  it "sends no ZoneInBoundsMsg when no zone exists at the mouse position" do
    model = ZoneMouseTestModel.new
    event = Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)
    updated, cmd = Term2::Zone.any_in_bounds_and_update(model, event)
    updated.received.select(Term2::ZoneInBoundsMsg).should be_empty
    cmd.should be_nil
  end

  it "sends a ZoneInBoundsMsg for a matching zone" do
    content = Term2::Zone.mark("demo", "X")
    Term2::Zone.scan(content)
    sleep 10.milliseconds

    model = ZoneMouseTestModel.new
    event = Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)
    updated, cmd = Term2::Zone.any_in_bounds_and_update(model, event)

    msgs = updated.received.select(Term2::ZoneInBoundsMsg)
    msgs.size.should eq(1)
    msg = msgs.first.as(Term2::ZoneInBoundsMsg)
    msg.zone.id.should eq("demo")
    msg.event.x.should eq(0)
    msg.event.y.should eq(0)
    cmd.should be_nil
  end
end
