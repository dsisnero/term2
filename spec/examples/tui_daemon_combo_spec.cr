ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/tui-daemon-combo/main"

describe "Example: tui-daemon-combo" do
  it "renders spinner and logs results" do
    Log.setup(:info, Log::IOBackend.new(IO::Memory.new))
    model = TuiDaemonModel.new
    model.init # warm up spinner command (ignored here)
    model, _cmd = model.update(ProcessFinishedMsg.new(100.milliseconds))
    model.results.any? { |(_, duration)| duration > Time::Span.zero }.should be_true
  end
end
