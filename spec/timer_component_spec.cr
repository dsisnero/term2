require "./spec_helper"

private class TimerTestModel < Term2::Model
  getter timer : Term2::Components::CountdownTimer
  getter finished_count : Int32

  def initialize(duration : Time::Span)
    @timer = Term2::Components::CountdownTimer.new(duration, interval: 5.milliseconds)
    @finished_count = 0
  end

  def init : Term2::Cmd
    @timer.init
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::Components::CountdownTimer::Finished
      @finished_count += 1
      return {self, Term2::Cmd.quit}
    end

    new_timer, cmd = @timer.update(msg)
    @timer = new_timer.as(Term2::Components::CountdownTimer)
    {self, cmd}
  end

  def view : String
    @timer.view
  end
end

describe Term2::Components::CountdownTimer do
  it "counts down and notifies when finished" do
    output = IO::Memory.new
    model = TimerTestModel.new(20.milliseconds)
    program = Term2::Program.new(model, input: nil, output: output)

    evt = CML.choose([
      CML.wrap(CML.spawn_evt { program.run }) { |model| {model.as(Term2::Model?), :ok} },
      CML.wrap(CML.timeout(1.second)) { |_| {nil.as(Term2::Model?), :timeout} },
    ])

    result = CML.sync(evt)
    result.should_not eq({nil, :timeout})

    final_model = result[0].as(TimerTestModel)
    final_model.finished_count.should eq(1)
    final_model.timer.running?.should be_false
  end
end
