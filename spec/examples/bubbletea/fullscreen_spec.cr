ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/fullscreen/main"

describe "Example: fullscreen", tags: "interactive" do
  it "counts down and quits" do
    model = FullscreenModel.new(2)
    model, cmd = model.update(FullscreenTickMsg.new(Time.utc))
    model.countdown.should eq(1)
    model, cmd = model.update(FullscreenTickMsg.new(Time.utc))
    model.countdown.should eq(0)
  end
end
