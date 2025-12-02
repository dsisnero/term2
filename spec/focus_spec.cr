require "./spec_helper"

private class FocusSpecModel
  include Term2::Model

  getter? focused : Bool = false
  getter? blurred : Bool = false

  def initialize(@focused : Bool = false, @blurred : Bool = false)
  end

  def init : Term2::Cmd
    Term2::Cmds.none
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::FocusMsg
      {FocusSpecModel.new(focused: true, blurred: blurred?), Term2::Cmds.none}
    when Term2::BlurMsg
      {FocusSpecModel.new(focused: focused?, blurred: true), Term2::Cmds.quit}
    else
      {self, Term2::Cmds.none}
    end
  end

  def view : String
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

    model = FocusSpecModel.new
    program = Term2::Program.new(model, input: input, output: output)
    program.enable_focus_reporting

    # Run program
    final_model = program.run.as(FocusSpecModel)

    final_model.focused?.should be_true
    final_model.blurred?.should be_true
  end
end
