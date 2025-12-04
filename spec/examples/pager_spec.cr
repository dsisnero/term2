ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/pager/main"

describe "Example: pager" do
  it "initializes viewport after size and quits" do
    tm = Term2::Teatest::TestModel(PagerModel).new(
      PagerModel.new,
      Term2::Teatest.with_initial_term_size(80, 20),
    )
    tm.send(Term2::WindowSizeMsg.new(80, 20))

    tm.send(Term2::KeyMsg.new(Term2::Key.new("q")))

    model = tm.final_model
    model.ready?.should be_true
  end
end
