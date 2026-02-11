ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/space/main"

describe "Example: space" do
  it "renders animated space background in altscreen mode" do
    model = SpaceExample::Model.new
    model.update(Term2::WindowSizeMsg.new(24, 8))

    view = model.view
    view.alt_screen.should be_true
    view.content.should contain("Space")
    view.content.should contain("▀")
  end
end
