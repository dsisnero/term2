ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/set-terminal-color/main"

describe "Example: set-terminal-color" do
  it "applies a foreground color from hex input" do
    model = SetTerminalColorExample::Model.new

    model.update(Term2::TestHelpers.uv_key("enter")) # choose foreground
    "#12c78f".each_char { |ch| model.update(Term2::TestHelpers.uv_key(ch)) }
    model.update(Term2::TestHelpers.uv_key("enter"))

    view = model.view
    view.foreground_color.should eq(Lipgloss::Color.hex("#12c78f"))
    view.background_color.should be_nil
  end

  it "shows an error for invalid hex input" do
    model = SetTerminalColorExample::Model.new

    model.update(Term2::TestHelpers.uv_key("enter"))
    "zzzzzz".each_char { |ch| model.update(Term2::TestHelpers.uv_key(ch)) }
    model.update(Term2::TestHelpers.uv_key("enter"))

    model.view.content.should contain("Error: invalid color: zzzzzz")
  end
end
