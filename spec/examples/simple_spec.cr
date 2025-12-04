ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/simple/main"

describe "Example: simple" do
  it "counts down and quits" do
    tm = Term2::Teatest::TestModel(SimpleModel).new(
      SimpleModel.new(2),
      Term2::Teatest.with_initial_term_size(40, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(40, 10))

    model = tm.final_model(Term2::Teatest.with_final_timeout(3.seconds))
    model.remaining.should be <= 0
  end
end
