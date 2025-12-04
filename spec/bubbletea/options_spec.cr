require "../spec_helper"

describe "Bubbletea parity: options_test.go" do
  it "sets custom output" do
    buf = IO::Memory.new
    program = Term2::Program(Term2::Model?).new(nil, output: buf)
    program.output_io.should eq(buf)
  end

  it "sets custom input" do
    buf = IO::Memory.new
    program = Term2::Program(Term2::Model?).new(nil, input: buf)
    program.input_io.should eq(buf)
  end

  it "disables renderer via option" do
    opts = Term2::ProgramOptions.new(Term2::WithoutRenderer.new)
    program = Term2::Program(Term2::Model?).new(nil, options: opts)
    program.renderer_enabled?.should be_false
  end

  it "applies without signals option" do
    opts = Term2::ProgramOptions.new(Term2::WithoutSignalHandler.new)
    program = Term2::Program(Term2::Model?).new(nil, options: opts)
    program.signal_handling_enabled?.should be_false
  end

  it "applies filter option" do
    filter_called = false
    filter = ->(msg : Term2::Msg) do
      filter_called = true
      msg
    end
    opts = Term2::ProgramOptions.new(Term2::WithFilter.new(filter.as(Proc(Term2::Msg, Term2::Msg))))
    program = Term2::Program(Term2::Model?).new(nil, options: opts)
    program.filter_present?.should be_true
  end

  it "external context option parity" do
    ctx = Term2::ProgramContext.new
    opts = Term2::ProgramOptions.new(Term2::WithContext.new(ctx))
    program = Term2::Program(Term2::Model?).new(nil, options: opts)
    program.context.should eq(ctx)
  end

  it "input options parity (TTY vs custom)" do
    tty_program = Term2::Program(Term2::Model?).new(nil, options: Term2::ProgramOptions.new(Term2::WithInputTTY.new))
    tty_program.input_type.should eq(:tty)

    buf = IO::Memory.new
    custom_program = Term2::Program(Term2::Model?).new(nil, options: Term2::ProgramOptions.new(Term2::WithInput.new(buf)))
    custom_program.input_type.should eq(:custom)
    custom_program.input_io.should eq(buf)
  end

  it "startup options parity (alt screen, bracketed paste, ANSI compressor, catch panics)" do
    alt = Term2::Program(Term2::Model?).new(nil, options: Term2::ProgramOptions.new(Term2::WithAltScreen.new))
    alt.startup_options.should contain(:alt_screen)

    bp = Term2::Program(Term2::Model?).new(nil, options: Term2::ProgramOptions.new(Term2::WithoutBracketedPaste.new))
    bp.startup_options.should contain(:without_bracketed_paste)

    ansi = Term2::Program(Term2::Model?).new(nil, options: Term2::ProgramOptions.new(Term2::WithANSICompressor.new))
    ansi.startup_options.should contain(:ansi_compressor)

    no_panic = Term2::Program(Term2::Model?).new(nil, options: Term2::ProgramOptions.new(Term2::WithoutCatchPanics.new))
    no_panic.startup_options.should contain(:without_catch_panics)

    no_sig = Term2::Program(Term2::Model?).new(nil, options: Term2::ProgramOptions.new(Term2::WithoutSignalHandler.new))
    no_sig.startup_options.should contain(:without_signal_handler)
  end

  it "mouse motion options precedence" do
    cell_first = Term2::Program(Term2::Model?).new(nil, options: Term2::ProgramOptions.new(Term2::WithMouseAllMotion.new, Term2::WithMouseCellMotion.new))
    cell_first.startup_options.should contain(:mouse_cell_motion)
    cell_first.startup_options.should_not contain(:mouse_all_motion)

    all_first = Term2::Program(Term2::Model?).new(nil, options: Term2::ProgramOptions.new(Term2::WithMouseCellMotion.new, Term2::WithMouseAllMotion.new))
    all_first.startup_options.should contain(:mouse_all_motion)
    all_first.startup_options.should_not contain(:mouse_cell_motion)
  end
end
