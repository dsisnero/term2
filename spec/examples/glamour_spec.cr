ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/glamour/main"

describe "Example: glamour" do
  it "renders content and quits" do
    tm = Term2::Teatest::TestModel(GlamourModel).new(
      GlamourModel.new,
      Term2::Teatest.with_initial_term_size(80, 24),
    )
    tm.send(Term2::WindowSizeMsg.new(80, 24))
    tm.quit
    out = tm.final_output
    out.should contain("Today’s Menu")
  end
end
