# spec/bubblezone/unit/messages_spec.cr
# Port of messages_test.go tests

require "../spec_helper"

class TestModel
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

class TestModelValue
  include Term2::Model

  getter received = [] of Term2::Msg

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::MouseEvent
      return Term2::Zone.any_in_bounds_and_update(self, msg)
    when Term2::ZoneInBoundsMsg
      @received << msg
    end
    {self, nil}
  end

  def view : String
    "test\nfoo\naaa " + Term2::Zone.mark("foo", "bar\ntest123456789") + " aaa\nbaz"
  end
end

describe "Term2::Zone message functionality" do
  describe "any_in_bounds" do
    it "sends ZoneInBoundsMsg when mouse is in zone bounds" do
      model = TestModel.new
      Term2::Zone.scan(model.view)
      sleep 100.milliseconds

      zone = Term2::Zone.get("foo")
      zone.zero?.should be_false

      # Simulate mouse click inside zone
      model.update(Term2::MouseEvent.new(x: 4, y: 2, button: Term2::MouseEvent::Button::Left, action: Term2::MouseEvent::Action::Press))
      sleep 100.milliseconds

      # Check that ZoneInBoundsMsg was received
      contains = false
      model.received.each do |msg|
        if msg.is_a?(Term2::ZoneInBoundsMsg)
          if msg.zone.id == zone.id
            contains = true
            break
          end
        end
      end

      contains.should be_true
    end
  end

  describe "any_in_bounds_and_update" do
    it "returns updated model with ZoneInBoundsMsg when mouse is in zone bounds" do
      model = TestModelValue.new
      Term2::Zone.scan(model.view)
      sleep 100.milliseconds

      zone = Term2::Zone.get("foo")
      zone.zero?.should be_false

      # Simulate mouse click inside zone
      updated_model, _cmd = model.update(Term2::MouseEvent.new(x: 4, y: 2, button: Term2::MouseEvent::Button::Left, action: Term2::MouseEvent::Action::Press))
      sleep 100.milliseconds

      # Check that ZoneInBoundsMsg was received
      contains = false
      updated_model.as(TestModelValue).received.each do |msg|
        if msg.is_a?(Term2::ZoneInBoundsMsg)
          if msg.zone.id == zone.id
            contains = true
            break
          end
        end
      end

      contains.should be_true
    end
  end

  describe "mouse event handling" do
    it "does not send ZoneInBoundsMsg when mouse is outside zone" do
      model = TestModel.new
      Term2::Zone.scan(model.view)
      sleep 100.milliseconds

      zone = Term2::Zone.get("foo")
      zone.zero?.should be_false

      # Simulate mouse click outside zone
      model.update(Term2::MouseEvent.new(x: 0, y: 0, button: Term2::MouseEvent::Button::Left, action: Term2::MouseEvent::Action::Press))
      sleep 100.milliseconds

      # Should not receive ZoneInBoundsMsg
      model.received.any?(Term2::ZoneInBoundsMsg).should be_false
    end

    it "handles multiple mouse events correctly" do
      model = TestModel.new
      Term2::Zone.scan(model.view)
      sleep 100.milliseconds

      zone = Term2::Zone.get("foo")
      zone.zero?.should be_false

      # Multiple mouse events - only one inside zone
      model.update(Term2::MouseEvent.new(x: 0, y: 0, button: Term2::MouseEvent::Button::Left, action: Term2::MouseEvent::Action::Press))
      model.update(Term2::MouseEvent.new(x: 4, y: 2, button: Term2::MouseEvent::Button::Left, action: Term2::MouseEvent::Action::Press))
      model.update(Term2::MouseEvent.new(x: 99, y: 99, button: Term2::MouseEvent::Button::Left, action: Term2::MouseEvent::Action::Press))
      sleep 150.milliseconds

      # Should have exactly one ZoneInBoundsMsg
      zone_msgs = model.received.select(Term2::ZoneInBoundsMsg)
      zone_msgs.size.should eq(1)

      msg = zone_msgs.first.as(Term2::ZoneInBoundsMsg)
      msg.zone.id.should eq(zone.id)
    end
  end
end
