ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/focus-blur/main"

describe "Example: focus-blur" do
  it "toggles reporting" do
    tm = Term2::Teatest::TestModel(FocusBlurModel).new(FocusBlurModel.new, Term2::Teatest.with_initial_term_size(40, 10))
    tm.send(Term2::WindowSizeMsg.new(40, 10))
    tm.send(Term2::KeyMsg.new(Term2::Key.new("t")))
    tm.quit
    tm.final_model.reporting?.should be_false
  end
end
