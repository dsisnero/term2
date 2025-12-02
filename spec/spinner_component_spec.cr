require "./spec_helper"

private class SpinnerTestModel
  include Term2::Model

  getter spinner : Term2::Components::Spinner
  getter tick_count : Int32
  getter limit : Int32

  def initialize(@limit : Int32 = 3)
    type = Term2::Components::Spinner::Type.new(["1", "2"], 5.milliseconds)
    @spinner = Term2::Components::Spinner.new(type)
    @tick_count = 0
  end

  def init : Term2::Cmd
    @spinner.tick
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::Components::Spinner::TickMsg
      @tick_count += 1
      if @tick_count >= @limit
        return {self, Term2::Cmds.quit}
      end
    end

    new_spinner, cmd = @spinner.update(msg)
    @spinner = new_spinner
    {self, cmd}
  end

  def view : String
    @spinner.view
  end
end

describe Term2::Components::Spinner do
  it "cycles frames and stops when requested" do
    output = IO::Memory.new
    model = SpinnerTestModel.new(4)
    program = Term2::Program.new(model, input: nil, output: output)

    program.run

    model.tick_count.should be >= 4
    output.to_s.should contain("1")
  end

  it "renders correctly" do
    type = Term2::Components::Spinner::Type.new(["*"], 10.milliseconds)
    spinner = Term2::Components::Spinner.new(type)
    spinner.view.should eq("*")
  end
end
