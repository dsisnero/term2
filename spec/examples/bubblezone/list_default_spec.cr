ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubblezone/list-default/main"

describe "Bubblezone example: list-default", tags: "interactive" do
  it "renders and selects items via zone bounds checks" do
    model = BubblezoneListDefaultExample::Model.new
    model, _ = model.update(Term2::WindowSizeMsg.new(60, 18))
    model = model.as(BubblezoneListDefaultExample::Model)

    frame = model.view
    Term2::Zone.scan(frame)

    zone = Term2::Zone.get("item_2")
    zone.zero?.should be_false

    model.list.index.should eq 0

    click = Term2::MouseEvent.new(
      x: zone.start_x,
      y: zone.start_y,
      button: Term2::MouseEvent::Button::Left,
      action: Term2::MouseEvent::Action::Release,
    )

    model, _ = model.update(click)
    model = model.as(BubblezoneListDefaultExample::Model)
    model.list.index.should eq 1

    frame.should contain("Left click on an items title to select it")
    frame.should contain("Nutella")
  end

  it "moves the cursor with the mouse wheel" do
    model = BubblezoneListDefaultExample::Model.new
    model, _ = model.update(Term2::WindowSizeMsg.new(60, 18))
    model = model.as(BubblezoneListDefaultExample::Model)

    model.list.index.should eq 0
    wheel = Term2::MouseEvent.new(
      x: 0,
      y: 0,
      button: Term2::MouseEvent::Button::WheelDown,
      action: Term2::MouseEvent::Action::Press,
    )
    model, _ = model.update(wheel)
    model = model.as(BubblezoneListDefaultExample::Model)
    model.list.index.should eq 1
  end
end
