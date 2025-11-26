require "../spec_helper"
require "../../src/bubbles/timer"

describe Term2::Bubbles::Timer do
  it "initializes running" do
    timer = Term2::Bubbles::Timer.new(5.seconds)
    timer.running?.should be_true
    timer.timed_out?.should be_false
  end

  it "counts down" do
    timer = Term2::Bubbles::Timer.new(2.seconds, 1.second)

    # Simulate tick
    msg = Term2::Bubbles::Timer::TickMsg.new(timer.id, 0, false)
    timer, cmd = timer.update(msg)

    timer.timeout.should eq 1.second
    timer.timed_out?.should be_false
    cmd.should_not be_nil

    # Next tick -> timeout
    msg = Term2::Bubbles::Timer::TickMsg.new(timer.id, 0, false)
    timer, _ = timer.update(msg)

    timer.timeout.should eq 0.seconds
    timer.timed_out?.should be_true
    timer.running?.should be_false

    # Cmd should be TimeoutMsg
    # We can't easily check the content of Cmd if it's a message wrapper without running it.
    # But we know the state changed.
  end

  it "can be stopped and started" do
    timer = Term2::Bubbles::Timer.new(5.seconds)

    # Stop
    msg = Term2::Bubbles::Timer::StartStopMsg.new(timer.id, false)
    timer, _ = timer.update(msg)
    timer.running?.should be_false

    # Start
    msg = Term2::Bubbles::Timer::StartStopMsg.new(timer.id, true)
    timer, cmd = timer.update(msg)
    timer.running?.should be_true
    cmd.should_not be_nil
  end
end
