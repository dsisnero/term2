ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/progress-download/main"

describe "Example: progress-download" do
  it "reaches completion and quits" do
    tm = Term2::Teatest::TestModel(ProgressDownloadModel).new(
      ProgressDownloadModel.new,
      Term2::Teatest.with_initial_term_size(80, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(80, 10))

    tm.send(ProgressMsg.new(1.0))
    model = tm.final_model(
      Term2::Teatest.with_final_timeout(2.seconds),
      Term2::Teatest.with_timeout_fn { tm.quit },
    )
    model.progress.percent.should be_close(1.0, 0.0001)
  end
end
