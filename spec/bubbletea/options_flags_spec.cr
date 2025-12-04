require "../spec_helper"

class OptionsFlagModel
  include Term2::Model

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    {self, nil}
  end

  def view : String
    "success"
  end
end

describe "BubbleTea parity: startup options flags" do
  it "sets custom input type when WithInputTTY is used" do
    opts = Term2::ProgramOptions.new(Term2::WithInputTTY.new)
    program = Term2::Program(OptionsFlagModel).new(OptionsFlagModel.new, options: opts)
    program.input_tty?.should be_true
  end

  it "disables bracketed paste when WithoutBracketedPaste is used" do
    opts = Term2::ProgramOptions.new(Term2::WithoutBracketedPaste.new)
    program = Term2::Program(OptionsFlagModel).new(OptionsFlagModel.new, options: opts)
    program.bracketed_paste_enabled?.should be_false
  end

  it "last mouse option wins (cell over all motion)" do
    opts = Term2::ProgramOptions.new(Term2::WithMouseAllMotion.new, Term2::WithMouseCellMotion.new)
    program = Term2::Program(OptionsFlagModel).new(OptionsFlagModel.new, options: opts)
    program.mouse_cell_motion_enabled?.should be_true
    program.mouse_all_motion_enabled?.should be_false
  end

  it "last mouse option wins (all motion over cell motion)" do
    opts = Term2::ProgramOptions.new(Term2::WithMouseCellMotion.new, Term2::WithMouseAllMotion.new)
    program = Term2::Program(OptionsFlagModel).new(OptionsFlagModel.new, options: opts)
    program.mouse_all_motion_enabled?.should be_true
    program.mouse_cell_motion_enabled?.should be_false
  end
end
