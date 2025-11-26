require "../spec_helper"
require "../../src/bubbles/progress"

describe Term2::Bubbles::Progress do
  it "initializes with defaults" do
    prog = Term2::Bubbles::Progress.new
    prog.percent.should eq 0.0
    prog.width.should eq 30
  end

  it "updates percent" do
    prog = Term2::Bubbles::Progress.new

    msg = Term2::Bubbles::Progress::SetPercentMsg.new(0.5)
    prog, _ = prog.update(msg)
    prog.percent.should eq 0.5

    msg = Term2::Bubbles::Progress::IncrementMsg.new(0.1)
    prog, _ = prog.update(msg)
    prog.percent.should be_close(0.6, 0.001)

    # Clamping
    msg = Term2::Bubbles::Progress::SetPercentMsg.new(1.5)
    prog, _ = prog.update(msg)
    prog.percent.should eq 1.0
  end

  it "renders correctly" do
    prog = Term2::Bubbles::Progress.new(width: 10)
    prog.show_percentage = false
    prog.percent = 0.5

    # 5 filled, 5 empty
    expected = "█████░░░░░"
    prog.view.gsub(/\e\[[0-9;]*m/, "").should eq expected
  end

  it "renders with percentage" do
    prog = Term2::Bubbles::Progress.new(width: 10)
    prog.show_percentage = true
    prog.percent = 0.5

    # " 50%" is 4 chars. Bar width = 6.
    # 50% of 6 is 3.
    # 3 filled, 3 empty.
    expected = "███░░░ 50%"
    prog.view.gsub(/\e\[[0-9;]*m/, "").should eq expected
  end
end
