ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/suspend/main"

describe "Example: suspend" do
  it "toggles suspending flag" do
    ENV["TERM2_DISABLE_SUSPEND"] = "1"
    tm = Term2::Teatest::TestModel(SuspendModel).new(
      SuspendModel.new,
      Term2::Teatest.with_initial_term_size(40, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(40, 10))

    tm.send(Term2::KeyMsg.new(Term2::Key.new("ctrl+z")))
    tm.send(Term2::ResumeMsg.new)
    tm.send(Term2::KeyMsg.new(Term2::Key.new("q")))

    model = tm.final_model(Term2::Teatest.with_final_timeout(1.second))
    model.suspending?.should be_false
  end
end
