ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/stopwatch/main"

describe "Example: stopwatch" do
  it "starts and resets" do
    tm = Term2::Teatest::TestModel(StopwatchModel).new(
      StopwatchModel.new,
      Term2::Teatest.with_initial_term_size(40, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(40, 10))

    tm.send(Term2::KeyMsg.new(Term2::Key.new("s")))
    tm.send(Term2::KeyMsg.new(Term2::Key.new("r")))
    tm.quit

    model = tm.final_model
    model.stopwatch.elapsed.should be >= Time::Span.zero
  end
end
