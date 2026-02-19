ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/altscreen-toggle/main"

describe "Example: altscreen-toggle" do
  it "toggles altscreen state and renders quit/suspend views like Go example" do
    model = AltScreenModel.new

    initial = model.view
    model.altscreen?.should be_false
    initial.should contain("inline mode")

    model.update(Term2::TestHelpers.uv_key(" "))
    toggled = model.view
    model.altscreen?.should be_true
    toggled.should contain("altscreen mode")

    model.update(Term2::ResumeMsg.new)
    model.update(Term2::TestHelpers.uv_key("q"))
    quit_view = model.view
    model.altscreen?.should be_true
    quit_view.should eq("")
  end
end
