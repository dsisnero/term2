require "./spec_helper"

private class TimerModelWrapper < Term2::Model
  getter timer : Term2::Components::CountdownTimer::Model

  def initialize(@timer : Term2::Components::CountdownTimer::Model)
  end
end

private class TimerHarness < Term2::Application(TimerModelWrapper)
  getter finished_count : Int32

  def initialize(@duration : Time::Span)
    @timer = Term2::Components::CountdownTimer.new(interval: 5.milliseconds)
    @finished_count = 0
  end

  def init : {TimerModelWrapper, Term2::Cmd}
    timer_model, cmd = @timer.init(@duration)
    {TimerModelWrapper.new(timer_model), cmd}
  end

  def update(msg : Term2::Message, model : TimerModelWrapper)
    wrapper = model
    timer_model, cmd = @timer.update(msg, wrapper.timer)
    new_wrapper = TimerModelWrapper.new(timer_model)
    extra = Term2::Cmd.none

    if msg.is_a?(Term2::Components::CountdownTimer::Finished)
      @finished_count += 1
      extra = Term2::Cmd.quit
    end

    {new_wrapper, Term2::Cmd.batch(cmd, extra)}
  end

  def view(model : TimerModelWrapper) : String
    @timer.view(model.timer)
  end
end

describe Term2::Components::CountdownTimer do
  it "counts down and notifies when finished" do
    output = IO::Memory.new
    app = TimerHarness.new(20.milliseconds)
    program = Term2::Program.new(app, input: nil, output: output)

    evt = CML.choose([
      CML.wrap(CML.spawn_evt { program.run }) { |model| {model.as(Term2::Model?), :ok} },
      CML.wrap(CML.timeout(1.second)) { |_| {nil.as(Term2::Model?), :timeout} },
    ])

    result = CML.sync(evt)
    result.should_not eq({nil, :timeout})
    app.finished_count.should eq(1)
    output.to_s.should contain("finished")

    timer_model = result[0].as(TimerModelWrapper).timer
    timer_model.remaining.should be <= Time::Span.zero
    timer_model.running?.should be_false
  end
end
