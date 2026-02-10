ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/stopwatch/main"

describe "Example: stopwatch", tags: "interactive" do
  it "starts and resets" do
    tm = Term2::Teatest::TestModel(StopwatchModel).new(
      StopwatchModel.new,
      Term2::Teatest.with_initial_term_size(40, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(40, 10))

    tm.send(Term2::TestHelpers.uv_key("s"))
    tm.send(Term2::TestHelpers.uv_key("r"))
    tm.quit

    model = tm.final_model
    model.stopwatch.elapsed.should be >= Time::Span.zero
  end
end
