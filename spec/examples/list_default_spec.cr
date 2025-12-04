ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/list-default/main"

describe "Example: list-default" do
  it "renders list title and quits" do
    tm = Term2::Teatest::TestModel(ListDefaultModel).new(
      ListDefaultModel.new,
      Term2::Teatest.with_initial_term_size(80, 20),
    )
    tm.send(Term2::WindowSizeMsg.new(80, 20))

    tm.send(Term2::KeyMsg.new(Term2::Key.new("ctrl+c")))

    output = tm.final_output
    output.should contain("My Fave Things")
  end
end
