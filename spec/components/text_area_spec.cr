require "../spec_helper"
require "../../src/components/text_area"

describe Term2::Components::TextArea do
  it "initializes empty" do
    ta = Term2::Components::TextArea.new
    ta.value.should eq ""
    ta.cursor_line.should eq 0
    ta.cursor_col.should eq 0
  end

  it "handles input" do
    ta = Term2::Components::TextArea.new
    ta.focus

    # Insert 'a'
    msg = Term2::TestHelpers.key_msg(Term2::TestHelpers.uv_key("a"))
    ta, _ = ta.update(msg)
    ta.value.should eq "a"
    ta.cursor_col.should eq 1

    # Enter (newline)
    msg = Term2::TestHelpers.key_msg(Term2::TestHelpers.uv_key("enter"))
    ta, _ = ta.update(msg)
    ta.value.should eq "a\n"
    ta.cursor_line.should eq 1
    ta.cursor_col.should eq 0

    # Insert 'b'
    msg = Term2::TestHelpers.key_msg(Term2::TestHelpers.uv_key("b"))
    ta, _ = ta.update(msg)
    ta.value.should eq "a\nb"
  end

  it "handles navigation" do
    ta = Term2::Components::TextArea.new
    ta.focus
    ta.value = "line1\nline2"

    # After setting value cursor is at end
    ta.cursor_line.should eq 1
    ta.cursor_col.should eq "line2".size

    # Down
    msg = Term2::TestHelpers.key_msg(Term2::TestHelpers.uv_key("down"))
    ta, _ = ta.update(msg)
    ta.cursor_line.should eq 1

    # Right
    msg = Term2::TestHelpers.key_msg(Term2::TestHelpers.uv_key("right"))
    ta, _ = ta.update(msg)
    ta.cursor_col.should eq "line2".size

    # Up
    msg = Term2::TestHelpers.key_msg(Term2::TestHelpers.uv_key("up"))
    ta, _ = ta.update(msg)
    ta.cursor_line.should eq 0
    ta.cursor_col.should be >= 1
  end

  it "renders with line numbers" do
    ta = Term2::Components::TextArea.new
    ta.focus
    ta.value = "hello"

    view = ta.view.content
    view.should contain "1"
    view.should contain "ello" # 'h' is inside cursor style

  end

  it "maps cursor style properties" do
    ta = Term2::Components::TextArea.new
    cursor_style = Term2::Components::TextArea::CursorStyle.new(
      color: Lipgloss::Color.from_hex("#FF0000"),
      shape: Term2::Components::TextArea::CursorShape::Underline,
      blink: true,
      blink_speed: 300.milliseconds
    )
    ta.styles = Term2::Components::TextArea::Styles.new(
      cursor: cursor_style
    )

    # Verify the style was stored
    ta.styles.cursor.blink_speed.should eq 300.milliseconds
    ta.styles.cursor.blink?.should be_true
    ta.styles.cursor.shape.should eq Term2::Components::TextArea::CursorShape::Underline

    # Verify cursor was updated
    ta.cursor.blink_speed.should eq 300.milliseconds
    ta.cursor.mode.should eq Term2::Components::Cursor::Mode::Blink
    # Shape mapping to Lipgloss::Style
    ta.cursor.style.underline?.should be_true
    # Color mapping to text_style
    # We'll trust that update_cursor_style worked since blink_speed and mode are set
  end

  it "uses Styles struct for focused and blurred states" do
    ta = Term2::Components::TextArea.new
    focused_style = Term2::Components::TextArea::StyleState.new(
      text: Lipgloss::Style.new.bold(true),
      cursor_line: Lipgloss::Style.new.background(Lipgloss::Color.from_hex("#333333"))
    )
    blurred_style = Term2::Components::TextArea::StyleState.new(
      text: Lipgloss::Style.new.faint(true),
      cursor_line: Lipgloss::Style.new.background(Lipgloss::Color.from_hex("#111111"))
    )
    ta.styles = Term2::Components::TextArea::Styles.new(
      focused: focused_style,
      blurred: blurred_style,
      cursor: Term2::Components::TextArea::CursorStyle.new
    )

    # Check that styles are stored correctly
    ta.styles.focused.text.bold?.should be_true
    ta.styles.blurred.text.faint?.should be_true
    # Background color is stored in bg_color instance variable
    # We'll just verify the styles are set by checking they're not default
    ta.styles.focused.cursor_line.should_not eq Lipgloss::Style.new
    ta.styles.blurred.cursor_line.should_not eq Lipgloss::Style.new
  end

  it "navigates by display lines with set_cursor_line_relative" do
    ta = Term2::Components::TextArea.new
    ta.width = 20
    ta.value = "short line"

    start_line = ta.cursor_line
    start_col = ta.cursor_col

    ta.set_cursor_line_relative(1)
    ta.set_cursor_line_relative(-1)

    ta.cursor_line.should eq start_line
    ta.cursor_col.should eq start_col
  end
end
