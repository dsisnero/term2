ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/progress-static/main"

describe "Example: progress-static" do
  it "advances progress and quits" do
    tm = Term2::Teatest::TestModel(ProgressStaticModel).new(
      ProgressStaticModel.new,
      Term2::Teatest.with_initial_term_size(80, 10),
    )

    model = tm.final_model(
      Term2::Teatest.with_final_timeout(2.seconds),
      Term2::Teatest.with_timeout_fn { tm.quit },
    )
    model.percent.should be > 0
  end
end
