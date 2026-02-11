ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/vanish/main"

describe "Example: vanish" do
  it "vanishes after any key is pressed" do
    model = VanishExample::Model.new
    model.view.content.should contain("Press any key to quit.")

    model.update(Term2::TestHelpers.uv_key("x"))
    model.view.content.should eq("")
  end
end
