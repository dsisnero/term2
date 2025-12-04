ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/textinputs/main"

describe "Example: textinputs" do
  it "cycles focus and quits on enter at submit" do
    tm = Term2::Teatest::TestModel(TextinputsModel).new(
      TextinputsModel.new,
      Term2::Teatest.with_initial_term_size(50, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(50, 10))

    tm.send(Term2::KeyMsg.new(Term2::Key.new("tab")))
    tm.send(Term2::KeyMsg.new(Term2::Key.new("tab")))
    tm.send(Term2::KeyMsg.new(Term2::Key.new("enter")))
    tm.send(Term2::KeyMsg.new(Term2::Key.new("q")))

    output = tm.final_output
    output.should contain("Submit")
  end
end
