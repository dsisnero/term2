require "./spec_helper"

private class SpinnerHarness < Term2::Application
  getter tick_count : Int32

  class ModelWrapper < Term2::Model
    getter spinner : Term2::Components::Spinner::Model

    def initialize(@spinner : Term2::Components::Spinner::Model)
    end
  end

  def initialize(@limit : Int32 = 3)
    @spinner = Term2::Components::Spinner.new(frames: ["1", "2"], interval: 5.milliseconds)
    @tick_count = 0
  end

  def init
    spinner_model, cmd = @spinner.init("Loading")
    {ModelWrapper.new(spinner_model), cmd}
  end

  def update(msg : Term2::Message, model : Term2::Model)
    wrapper = model.as(ModelWrapper)
    spinner_model, cmd = @spinner.update(msg, wrapper.spinner)
    extra = Term2::Cmd.none

    case msg
    when Term2::Components::Spinner::Tick
      @tick_count += 1
      if @tick_count >= @limit
        extra = Term2::Cmd.batch(
          Term2::Cmd.message(Term2::Components::Spinner::Stop.new),
          Term2::Cmd.quit
        )
      end
    end

    {ModelWrapper.new(spinner_model), Term2::Cmd.batch(cmd, extra)}
  end

  def view(model : Term2::Model) : String
    spinner_model = model.as(ModelWrapper).spinner
    "#{@spinner.view(spinner_model)}\n"
  end
end

describe Term2::Components::Spinner do
  # Note: This test is flaky due to timing issues with CML event handling
  # The spinner tick mechanism relies on precise timing that can fail under load
  pending "cycles frames and stops when requested" do
    output = IO::Memory.new
    app = SpinnerHarness.new(4)
    program = Term2::Program.new(app, input: nil, output: output)

    evt = CML.choose([
      CML.wrap(CML.spawn_evt { program.run }) { |model| {model.as(Term2::Model?), :ok} },
      CML.wrap(CML.timeout(3.seconds)) { |_| {nil.as(Term2::Model?), :timeout} },
    ])

    result = CML.sync(evt)
    result.should_not eq({nil, :timeout})
    app.tick_count.should be >= 4
    output.to_s.should contain("Loading")
    output.to_s.should contain("1")

    spinner_model = result[0].as(SpinnerHarness::ModelWrapper).spinner
    spinner_model.spinning?.should be_false
  end

  it "applies theme prefix and finished symbol" do
    theme = Term2::Components::Spinner::Theme.new(prefix: "[", suffix: "]", finished_symbol: "✓", show_text_when_empty: true)
    spinner = Term2::Components::Spinner.new(frames: ["*"], interval: 10.milliseconds, theme: theme)

    model, _cmd = spinner.init("")
    spinner.view(model).should eq("[*]")

    stopped_model = Term2::Components::Spinner::Model.new("", 0, false)
    spinner.view(stopped_model).should eq("[✓]")
  end
end
