ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/tui-daemon-combo/main"

describe "Example: tui-daemon-combo" do
  it "renders spinner and logs results" do
    tm = Term2::Teatest::TestModel(TuiDaemonModel).new(
      TuiDaemonModel.new,
      Term2::Teatest.with_initial_term_size(60, 15),
    )

    tm.send(ProcessFinishedMsg.new(100.milliseconds))
    tm.quit
    output = tm.final_output
    (output.includes?("Job finished") || output.includes?("Press any key")).should be_true
  end
end
