ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/splash/main"

describe "Example: splash" do
  it "renders gradient content in altscreen mode after size is known" do
    model = SplashExample::Model.new
    view = model.view
    view.content.should eq("Initializing...")
    view.alt_screen.should be_true

    model.update(Term2::WindowSizeMsg.new(20, 6))
    rendered = model.view
    rendered.alt_screen.should be_true
    rendered.content.should contain("▀")
    rendered.content.includes?("Initializing...").should be_false
  end
end
