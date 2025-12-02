require "../spec_helper"

describe "Term2::Zone.handle_mouse" do
  before_each do
    Term2::Zone.reset
  end

  it "returns nil when no zone exists at the mouse position" do
    event = Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)
    Term2::Zone.handle_mouse(event).should be_nil
  end

  it "returns a ZoneClickMsg for a matching zone" do
    content = Term2::Zone.mark("demo", "X")
    Term2::Zone.scan(content)
    sleep 10.milliseconds

    event = Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)
    msg = Term2::Zone.handle_mouse(event)

    msg.should be_a(Term2::ZoneClickMsg)
    click = msg.as(Term2::ZoneClickMsg)
    click.id.should eq("demo")
    click.x.should eq(0)
    click.y.should eq(0)
  end
end
