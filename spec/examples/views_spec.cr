ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/views/main"

describe "Example: views" do
  it "makes a choice and progresses" do
    tm = Term2::Teatest::TestModel(ViewsModel).new(
      ViewsModel.new,
      Term2::Teatest.with_initial_term_size(80, 20),
    )
    tm.send(Term2::WindowSizeMsg.new(80, 20))

    tm.send(Term2::KeyMsg.new(Term2::Key.new("enter")))
    tm.quit
    output = tm.final_output
    output.should contain("Doing cool stuff")
  end
end
