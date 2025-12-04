ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/table/main"

describe "Example: table" do
  it "selects a row and prints action" do
    tm = Term2::Teatest::TestModel(TableModel).new(
      TableModel.new,
      Term2::Teatest.with_initial_term_size(80, 15),
    )

    15.times { tm.send(Term2::KeyMsg.new(Term2::Key.new("down"))) }
    tm.send(Term2::KeyMsg.new(Term2::Key.new("enter")))
    tm.quit

    output = tm.final_output
    output.should contain("Let's go to")
    output.should contain("Osaka")
  end
end
