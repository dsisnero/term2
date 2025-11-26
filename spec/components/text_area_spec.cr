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
    msg = Term2::KeyMsg.new(Term2::Key.new("a"))
    ta, _ = ta.update(msg)
    ta.value.should eq "a"
    ta.cursor_col.should eq 1

    # Enter (newline)
    msg = Term2::KeyMsg.new(Term2::Key.new("enter"))
    ta, _ = ta.update(msg)
    ta.value.should eq "a\n"
    ta.cursor_line.should eq 1
    ta.cursor_col.should eq 0

    # Insert 'b'
    msg = Term2::KeyMsg.new(Term2::Key.new("b"))
    ta, _ = ta.update(msg)
    ta.value.should eq "a\nb"
  end

  it "handles navigation" do
    ta = Term2::Components::TextArea.new
    ta.focus
    ta.value = "line1\nline2"

    # Start at 0,0
    ta.cursor_line.should eq 0
    ta.cursor_col.should eq 0

    # Down
    msg = Term2::KeyMsg.new(Term2::Key.new("down"))
    ta, _ = ta.update(msg)
    ta.cursor_line.should eq 1

    # Right
    msg = Term2::KeyMsg.new(Term2::Key.new("right"))
    ta, _ = ta.update(msg)
    ta.cursor_col.should eq 1

    # Up
    msg = Term2::KeyMsg.new(Term2::Key.new("up"))
    ta, _ = ta.update(msg)
    ta.cursor_line.should eq 0
    ta.cursor_col.should eq 1
  end

  it "renders with line numbers" do
    ta = Term2::Components::TextArea.new
    ta.focus
    ta.value = "hello"

    # Line 1: "  1 ┃ hello" (with cursor)
    view = ta.view
    view.should contain "  1 ┃ "
    view.should contain "ello" # 'h' is inside cursor style

  end
end
