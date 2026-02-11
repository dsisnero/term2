ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/clickable/main"

describe "Example: clickable" do
  it "spawns and closes dialogs via layer hit messages" do
    model = ClickableExample::Model.new
    model.update(Term2::WindowSizeMsg.new(80, 24))

    click = Term2::MouseClickMsg.new(Term2::UV::Mouse.new(x: 10, y: 8, button: Term2::UV::MouseButton::Left))
    release = Term2::MouseReleaseMsg.new(Term2::UV::Mouse.new(x: 10, y: 8, button: Term2::UV::MouseButton::Left))

    model.update(ClickableExample::LayerHitMsg.new("bg", click))
    model.update(ClickableExample::LayerHitMsg.new("bg", release))
    model.dialogs.size.should eq(1)

    button_id = model.dialogs.first.button_id
    model.update(ClickableExample::LayerHitMsg.new(button_id, click))
    model.update(ClickableExample::LayerHitMsg.new(button_id, release))
    model.dialogs.should be_empty
  end
end
