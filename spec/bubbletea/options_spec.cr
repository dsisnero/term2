require "../spec_helper"

class OptionsDummyModel
  include Term2::Model

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    {self, nil}
  end

  def view : String
    "success"
  end
end

describe "BubbleTea parity: program options" do
  it "sets custom output" do
    io = IO::Memory.new
    program = Term2::Program(OptionsDummyModel).new(OptionsDummyModel.new, output: io)
    program.output_io.should eq(io)
  end

  it "sets custom input" do
    io = IO::Memory.new
    program = Term2::Program(OptionsDummyModel).new(OptionsDummyModel.new, input: io)
    program.input_io.should eq(io)
  end

  it "sets nil renderer when disabled" do
    opts = Term2::ProgramOptions.new(Term2::WithoutRenderer.new)
    program = Term2::Program(OptionsDummyModel).new(OptionsDummyModel.new, options: opts)
    program.renderer.should be_a(Term2::NilRenderer)
  end
end