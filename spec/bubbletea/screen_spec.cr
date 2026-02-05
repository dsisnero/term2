require "../spec_helper"
require "golden"

# Port of screen_test.go from bubbletea

# TestViewOpts corresponds to testViewOpts in Go
class TestViewOpts < Term2::Message
  property alt_screen : Bool = false
  property mouse_mode : Term2::MouseMode = Term2::MouseMode::None
  property show_cursor : Bool = false
  property disable_bracketed_paste : Bool = false
  property key_releases : Bool = false
  property bg_color : Lipgloss::Color? = nil

  def initialize(
    @alt_screen = false,
    @mouse_mode = Term2::MouseMode::None,
    @show_cursor = false,
    @disable_bracketed_paste = false,
    @key_releases = false,
    @bg_color = nil,
  )
  end
end

# Base test model (similar to testModel in tea_test.go)
class ScreenTestModel
  include Term2::Model
  getter executed = Atomic(Bool).new(false)
  getter counter = Atomic(Int32).new(0)

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      {self, Term2::Cmds.quit}
    else
      {self, nil}
    end
  end

  def view : Term2::View
    @executed.set(true)
    Term2.new_view("success")
  end
end

# TestViewModel wraps ScreenTestModel and applies TestViewOpts
class TestViewModel
  include Term2::Model
  @base_model : ScreenTestModel
  property opts : TestViewOpts = TestViewOpts.new

  def initialize
    @base_model = ScreenTestModel.new
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when TestViewOpts
      @opts = msg
      {self, nil}
    else
      # Delegate to base model
      new_base, cmd = @base_model.update(msg)
      @base_model = new_base.as(ScreenTestModel)
      {self, cmd}
    end
  end

  def view : Term2::View
    view = @base_model.view
    view.alt_screen = @opts.alt_screen
    view.mouse_mode = @opts.mouse_mode
    view.disable_bracketed_paste_mode = @opts.disable_bracketed_paste
    view.keyboard_enhancements = Term2::KeyboardEnhancements.new(report_event_types: @opts.key_releases)
    view.background_color = @opts.bg_color
    if @opts.show_cursor
      view.cursor = Term2::Cursor.new(0, 0)
    end
    view
  end
end

# Helper to read golden files from bubbletea/testdata
def read_golden(test_name : String, subtest : String) : String
  golden_path = File.join("..", "..", "bubbletea", "testdata", test_name, "#{subtest}.golden")
  File.read(golden_path)
rescue ex
  raise "Failed to read golden file #{golden_path}: #{ex}"
end

describe "Bubbletea parity: screen_test.go" do
  # TestViewModel tests (matching TestViewModel in Go)
  describe "TestViewModel" do
    test_cases = [
      {
        name: "altscreen",
        opts: [
          TestViewOpts.new(alt_screen: true),
          TestViewOpts.new(alt_screen: false),
        ],
      },
      {
        name: "altscreen_autoexit",
        opts: [
          TestViewOpts.new(alt_screen: true),
        ],
      },
      {
        name: "mouse_cellmotion",
        opts: [
          TestViewOpts.new(mouse_mode: Term2::MouseMode::CellMotion),
        ],
      },
      {
        name: "mouse_allmotion",
        opts: [
          TestViewOpts.new(mouse_mode: Term2::MouseMode::AllMotion),
        ],
      },
      {
        name: "mouse_disable",
        opts: [
          TestViewOpts.new(mouse_mode: Term2::MouseMode::AllMotion),
          TestViewOpts.new(mouse_mode: Term2::MouseMode::None),
        ],
      },
      {
        name: "cursor_hide",
        opts: [
          TestViewOpts.new,
        ],
      },
      {
        name: "cursor_hideshow",
        opts: [
          TestViewOpts.new(show_cursor: false),
          TestViewOpts.new(show_cursor: true),
        ],
      },
      {
        name: "bp_stop_start",
        opts: [
          TestViewOpts.new(disable_bracketed_paste: true),
          TestViewOpts.new(disable_bracketed_paste: false),
        ],
      },
      {
        name: "kitty_stop_startreleases",
        opts: [
          TestViewOpts.new,
          TestViewOpts.new(key_releases: true),
        ],
      },
      {
        name: "bg_set_color",
        opts: [
          TestViewOpts.new(bg_color: Lipgloss::Color.rgb(255, 255, 255)),
        ],
      },
    ]

    test_cases.each do |tc|
      it tc[:name] do
        io = IO::Memory.new
        input = IO::Memory.new
        model = TestViewModel.new

        # Create commands for each option
        cmds = tc[:opts].map do |opt|
          -> { opt.as(Term2::Msg?) }
        end

        # Add quit command at the end
        cmds << Term2::Cmds.quit

        program = Term2::Program(TestViewModel).new(
          model,
          input: input,
          output: io,
          options: Term2::ProgramOptions.new(
            Term2::WithWindowSize.new(80, 24),
            Term2::WithColorProfile.new(Lipgloss::ColorProfile::ANSI256),
            Term2::WithEnvironment.new(["TERM=xterm-256color"])
          )
        )

        # Send sequence of commands
        spawn do
          cmds.each do |cmd|
            if cmd
              program.dispatch(Term2::SequenceMsg.new([cmd]))
            end
          end
        end

        program.run

        Golden.require_equal("TestViewModel/#{tc[:name]}", io.to_s, File.join(__DIR__, "..", "..", "bubbletea", "testdata"))
      end
    end
  end

  # TestClearMsg tests (matching TestClearMsg in Go)
  describe "TestClearMsg" do
    test_cases = [
      {
        name: "clear_screen",
        cmds: [Term2::Cmds.clear_screen],
      },
      {
        name: "read_set_clipboard",
        cmds: [Term2::Cmds.read_clipboard, Term2::Cmds.set_clipboard("success")],
      },
      {
        name: "bg_fg_cur_color",
        cmds: [
          Term2::Cmds.request_foreground_color,
          Term2::Cmds.request_background_color,
          Term2::Cmds.request_cursor_color,
        ],
      },
    ]

    test_cases.each do |tc|
      it tc[:name] do
        io = IO::Memory.new
        input = IO::Memory.new
        model = ScreenTestModel.new

        cmds = tc[:cmds] + [Term2::Cmds.quit]

        program = Term2::Program(ScreenTestModel).new(
          model,
          input: input,
          output: io,
          options: Term2::ProgramOptions.new(
            Term2::WithWindowSize.new(80, 24),
            Term2::WithColorProfile.new(Lipgloss::ColorProfile::ANSI256),
            Term2::WithEnvironment.new(["TERM=xterm-256color"])
          )
        )

        spawn do
          cmds.each do |cmd|
            if cmd
              program.dispatch(Term2::SequenceMsg.new([cmd]))
            end
          end
        end

        program.run

        Golden.require_equal("TestClearMsg/#{tc[:name]}", io.to_s, File.join(__DIR__, "..", "..", "bubbletea", "testdata"))
      end
    end
  end
end
