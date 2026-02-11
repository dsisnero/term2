ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/canvas/main"

describe "Example: canvas", tags: "interactive" do
  it "renders layered cards and footer instructions" do
    tm = Term2::Teatest::TestModel(CanvasExample::Model).new(
      CanvasExample::Model.new,
      Term2::Teatest.with_initial_term_size(80, 24)
    )
    tm.send(Term2::WindowSizeMsg.new(80, 24))

    Term2::Teatest.wait_for(tm.output_reader, Term2::Teatest.with_duration(1.second)) do |txt|
      txt.includes?("Goodbye") &&
        txt.includes?("Press any key to swap the cards, or q to quit.") &&
        txt.includes?("+------------------+")
    end

    tm.quit
  end
end
