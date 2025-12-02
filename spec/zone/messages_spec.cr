require "../spec_helper"

class ZoneTestModel
  include Term2::Model

  getter received = [] of Term2::Msg

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::MouseEvent
      spawn { Term2::Zone.any_in_bounds(self, msg) }
    when Term2::ZoneInBoundsMsg
      @received << msg
    end
    {self, nil}
  end

  def view : String
    "test\nfoo\naaa " + Term2::Zone.mark("foo", "bar\ntest123456789") + " aaa\nbaz"
  end
end

class ZoneTestModelValue
  include Term2::Model

  getter received = [] of Term2::Msg

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::MouseEvent
      Term2::Zone.any_in_bounds_and_update(self, msg)
    when Term2::ZoneInBoundsMsg
      @received << msg
    end
    {self, nil}
  end

  def view : String
    "test\nfoo\naaa " + Term2::Zone.mark("foo", "bar\ntest123456789") + " aaa\nbaz"
  end
end

describe "Term2::Zone in-bounds messaging" do
  before_each do
    Term2::Zone.reset
  end

  it "sends ZoneInBoundsMsg via any_in_bounds" do
    model = ZoneTestModel.new
    Term2::Zone.scan(model.view)
    sleep 50.milliseconds
    zone = Term2::Zone.get("foo")
    zone.is_zero?.should be_false

    model.update(Term2::MouseEvent.new(4, 2, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press))
    sleep 50.milliseconds

    model.received.any? { |m| m.is_a?(Term2::ZoneInBoundsMsg) && m.as(Term2::ZoneInBoundsMsg).zone.id == zone.id }.should be_true
  end

  it "returns updated model via any_in_bounds_and_update" do
    model = ZoneTestModelValue.new
    Term2::Zone.scan(model.view)
    sleep 50.milliseconds
    zone = Term2::Zone.get("foo")
    zone.is_zero?.should be_false

    updated, _cmd = model.update(Term2::MouseEvent.new(4, 2, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press))
    sleep 50.milliseconds

    updated.as(ZoneTestModelValue).received.any? { |m| m.is_a?(Term2::ZoneInBoundsMsg) && m.as(Term2::ZoneInBoundsMsg).zone.id == zone.id }.should be_true
  end
end
