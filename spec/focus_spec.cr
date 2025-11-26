require "./spec_helper"

private class FocusTestApp < Term2::Application
  class Model < Term2::Model
    getter focused : Bool = false
    getter blurred : Bool = false

    def initialize(@focused : Bool = false, @blurred : Bool = false)
    end
  end

  def init
    Model.new
  end

  def update(msg : Term2::Message, model : Term2::Model)
    m = model.as(Model)
    case msg
    when Term2::FocusMsg
      {Model.new(focused: true, blurred: m.blurred), Term2::Cmd.none}
    when Term2::BlurMsg
      {Model.new(focused: m.focused, blurred: true), Term2::Cmd.quit}
    else
      {model, Term2::Cmd.none}
    end
  end

  def view(model : Term2::Model) : String
    ""
  end
end

describe "Focus Reporting" do
  it "handles focus and blur events" do
    input = IO::Memory.new
    output = IO::Memory.new

    # Simulate FocusIn (\e[I) then Blur (\e[O)
    input.print "\e[I"
    input.print "\e[O"
    input.rewind

    app = FocusTestApp.new
    program = Term2::Program.new(app, input: input, output: output)
    program.enable_focus_reporting

    # Run program
    final_model = program.run.as(FocusTestApp::Model)

    final_model.focused.should be_true
    final_model.blurred.should be_true
  end
end
