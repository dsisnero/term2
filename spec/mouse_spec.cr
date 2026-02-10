require "./spec_helper"

describe "Ultraviolet mouse helpers" do
  it "creates click events with expected coordinates" do
    event = Term2::TestHelpers.mouse_click(10, 20)
    event.mouse.x.should eq(10)
    event.mouse.y.should eq(20)
    event.mouse.button.should eq(UV::MouseButton::Left)
  end
end
