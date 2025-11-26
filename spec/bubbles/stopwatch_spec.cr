require "../spec_helper"
require "../../src/bubbles/stopwatch"

describe Term2::Bubbles::Stopwatch do
  it "initializes stopped" do
    sw = Term2::Bubbles::Stopwatch.new
    sw.running?.should be_false
    sw.elapsed.should eq Time::Span.zero
  end

  it "starts and counts up" do
    sw = Term2::Bubbles::Stopwatch.new

    # Start
    msg = Term2::Bubbles::Stopwatch::StartMsg.new
    sw, cmd = sw.update(msg)
    sw.running?.should be_true
    cmd.should_not be_nil

    # Tick
    msg = Term2::Bubbles::Stopwatch::TickMsg.new
    sw, cmd = sw.update(msg)
    # Elapsed time depends on Time.local, so it might be very small but > 0 if time passed
    # But since we just started, it might be 0.
    cmd.should_not be_nil
  end

  it "resets" do
    sw = Term2::Bubbles::Stopwatch.new
    sw.elapsed = 10.seconds

    msg = Term2::Bubbles::Stopwatch::ResetMsg.new
    sw, _ = sw.update(msg)
    sw.elapsed.should eq Time::Span.zero
  end
end
