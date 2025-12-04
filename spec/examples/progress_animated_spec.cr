ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/progress-animated/main"

describe "Example: progress-animated" do
  it "animates and quits at 100%" do
    tm = Term2::Teatest::TestModel(ProgressAnimatedModel).new(
      ProgressAnimatedModel.new,
      Term2::Teatest.with_initial_term_size(80, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(80, 10))

    model = tm.final_model(
      Term2::Teatest.with_final_timeout(2.seconds),
      Term2::Teatest.with_timeout_fn { tm.quit },
    )
    model.progress.percent.should be >= 0
  end
end
