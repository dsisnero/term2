ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/table/main"

describe "Example: table", tags: "interactive" do
  it "selects a row and prints action" do
    tm = Term2::Teatest::TestModel(TableModel).new(
      TableModel.new,
      Term2::Teatest.with_initial_term_size(80, 15),
    )
    tm.send(Term2::WindowSizeMsg.new(80, 15))

    9.times { tm.send(Term2::TestHelpers.uv_key("down")) }
    tm.send(Term2::TestHelpers.uv_key("enter"))
    tm.quit

    output = tm.final_output
    output.should contain("Let's go to")
    output.should contain("Osaka")
  end
end
