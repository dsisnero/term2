ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/split-editors/main"

describe "Example: split-editors", tags: "interactive" do
  it "cycles focus across editors" do
    tm = Term2::Teatest::TestModel(SplitEditorsModel).new(
      SplitEditorsModel.new,
      Term2::Teatest.with_initial_term_size(80, 20),
    )
    tm.send(Term2::WindowSizeMsg.new(80, 20))

    tm.send(Term2::TestHelpers.uv_key("tab"))
    tm.send(Term2::TestHelpers.uv_key("tab"))
    tm.quit

    output = tm.final_output
    output.should contain("tab")
    output.should contain("shift+tab")
  end
end
