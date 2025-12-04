ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/mouse/main"

describe "Example: mouse" do
  it "quits on keypress" do
    tm = Term2::Teatest::TestModel(MouseModel).new(
      MouseModel.new,
      Term2::Teatest.with_initial_term_size(40, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(40, 10))

    tm.send(Term2::KeyMsg.new(Term2::Key.new("q")))
    tm.final_output
  end
end
