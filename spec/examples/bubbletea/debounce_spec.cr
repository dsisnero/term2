ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/debounce/main"

describe "Example: debounce", tags: "interactive" do
  it "debounces key presses" do
    tm = Term2::Teatest::TestModel(DebounceModel).new(DebounceModel.new, Term2::Teatest.with_initial_term_size(40, 10))
    tm.send(Term2::WindowSizeMsg.new(40, 10))

    tm.send(Term2::TestHelpers.uv_key("a"))
    tm.send(Term2::TestHelpers.uv_key("b"))
    tm.quit

    model = tm.final_model
    model.tag.should eq(2)
  end
end
