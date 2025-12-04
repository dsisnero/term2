ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/set-window-title/main"

describe "Example: set-window-title" do
  it "sends window title command" do
    tm = Term2::Teatest::TestModel(WindowTitleModel).new(
      WindowTitleModel.new,
      Term2::Teatest.with_initial_term_size(40, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(40, 10))

    tm.quit
    tm.final_output
  end
end
