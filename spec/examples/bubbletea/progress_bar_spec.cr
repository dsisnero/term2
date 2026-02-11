ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/progress-bar/main"

describe "Example: progress-bar" do
  it "exposes progress bar state in the returned view" do
    model = ProgressBarExample::Model.new
    model.update(Term2::WindowSizeMsg.new(80, 24))

    view = model.view
    view.progress_bar.should_not be_nil
    view.progress_bar.not_nil!.state.should eq(Term2::ProgressBarState::Indeterminate)
    view.progress_bar.not_nil!.value.should eq(0)
  end
end
