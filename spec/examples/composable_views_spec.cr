ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/composable-views/main"

describe "Example: composable-views" do
  it "switches focus and cycles spinner" do
    tm = Term2::Teatest::TestModel(ComposableModel).new(ComposableModel.new, Term2::Teatest.with_initial_term_size(30, 10))

    tm.send(Term2::KeyMsg.new(Term2::Key.new("tab")))
    tm.send(Term2::KeyMsg.new(Term2::Key.new("n")))
    tm.send(Term2::KeyMsg.new(Term2::Key.new("q")))

    out = tm.final_output
    out.should contain("tab: focus next")
  end
end
