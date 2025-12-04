ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/timer/main"

describe "Example: timer" do
  it "starts and times out" do
    ENV["TERM2_TIMER_TIMEOUT"] = "0"

    tm = Term2::Teatest::TestModel(TimerModel).new(
      TimerModel.new(50.milliseconds),
      Term2::Teatest.with_initial_term_size(40, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(40, 10))

    model = tm.final_model(
      Term2::Teatest.with_final_timeout(1.second),
      Term2::Teatest.with_timeout_fn { tm.quit },
    )
    model.quitting?.should be_true
  end
end
