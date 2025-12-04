ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/table-resize/main"

describe "Example: table-resize" do
  it "renders table with resized dimensions" do
    tm = Term2::Teatest::TestModel(TableResizeModel).new(
      TableResizeModel.new,
      Term2::Teatest.with_initial_term_size(80, 20),
    )

    tm.quit
    output = tm.final_output
    output.should contain("Pikachu")
  end
end
