require "./spec_helper"

describe Term2::Components::Progress do
  it "initializes with zero progress" do
    bar = Term2::Components::Progress.new(width: 10)
    bar.full_char = '#'
    bar.empty_char = '.'

    view = bar.view.gsub(/\e\[[0-9;]*m/, "")
    # Percent uses a 3-wide field: "  0%" (4 chars), so bar width is 6.
    view.should contain("......")
    view.should contain("0%")
  end

  it "clamps progress and renders percentage" do
    bar = Term2::Components::Progress.new(width: 10)
    bar.full_char = '#'
    bar.empty_char = '.'

    msg = Term2::Components::Progress::SetPercentMsg.new(0.55)
    bar, cmd = bar.update(msg)
    cmd.should_not be_nil
    bar.percent.should be_close(0.55, 0.0001)

    view = bar.view_as(bar.percent).gsub(/\e\[[0-9;]*m/, "")
    # Width 10 includes " 55%" (4 chars), so bar width is 6.
    # 55% of 6 is 3.3 -> 3 (rounded).

    view.should contain("###")
    view.should contain("...")
    view.should contain("55%")

    msg_inc = Term2::Components::Progress::IncrementMsg.new(1.0)
    bar, cmd2 = bar.update(msg_inc)
    cmd2.should_not be_nil
    bar.percent.should eq 1.0

    view2 = bar.view_as(bar.percent).gsub(/\e\[[0-9;]*m/, "")
    # Width 10 includes "100%" (4 chars), so bar width is 6.

    view2.should contain("######")
    view2.should contain("100%")
  end
end
