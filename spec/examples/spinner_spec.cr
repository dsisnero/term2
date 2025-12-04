ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/spinner/main"

describe "Example: spinner" do
  it "ticks and quits" do
    tm = Term2::Teatest::TestModel(SpinnerModel).new(
      SpinnerModel.new,
      Term2::Teatest.with_initial_term_size(40, 10),
    )

    tm.send(Term2::KeyMsg.new(Term2::Key.new("q")))
    model = tm.final_model
    model.quitting?.should be_true
  end
end
