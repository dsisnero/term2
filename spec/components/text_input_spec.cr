require "../spec_helper"
require "../../src/components/text_input"

describe Term2::Components::TextInput do
  it "initializes empty" do
    ti = Term2::Components::TextInput.new
    ti.value.should eq ""
    ti.cursor_pos.should eq 0
    ti.focused?.should be_false
  end

  it "handles input" do
    ti = Term2::Components::TextInput.new
    ti.focus

    # Insert 'a'
    msg = Term2::KeyMsg.new(Term2::Key.new("a"))
    ti, _ = ti.update(msg)
    ti.value.should eq "a"
    ti.cursor_pos.should eq 1

    # Insert 'b'
    msg = Term2::KeyMsg.new(Term2::Key.new("b"))
    ti, _ = ti.update(msg)
    ti.value.should eq "ab"
    ti.cursor_pos.should eq 2
  end

  it "handles cursor movement" do
    ti = Term2::Components::TextInput.new
    ti.focus
    ti.value = "abc"
    ti.cursor_pos = 3

    # Left
    msg = Term2::KeyMsg.new(Term2::Key.new("left"))
    ti, _ = ti.update(msg)
    ti.cursor_pos.should eq 2

    # Home
    msg = Term2::KeyMsg.new(Term2::Key.new("home"))
    ti, _ = ti.update(msg)
    ti.cursor_pos.should eq 0

    # Right
    msg = Term2::KeyMsg.new(Term2::Key.new("right"))
    ti, _ = ti.update(msg)
    ti.cursor_pos.should eq 1

    # End
    msg = Term2::KeyMsg.new(Term2::Key.new("end"))
    ti, _ = ti.update(msg)
    ti.cursor_pos.should eq 3
  end

  it "handles deletion" do
    ti = Term2::Components::TextInput.new
    ti.focus
    ti.value = "abc"
    ti.cursor_pos = 3

    # Backspace
    msg = Term2::KeyMsg.new(Term2::Key.new("backspace"))
    ti, _ = ti.update(msg)
    ti.value.should eq "ab"
    ti.cursor_pos.should eq 2

    # Move left
    ti.cursor_pos = 1

    # Delete (forward)
    msg = Term2::KeyMsg.new(Term2::Key.new("delete"))
    ti, _ = ti.update(msg)
    ti.value.should eq "a"
    ti.cursor_pos.should eq 1
  end

  it "renders correctly" do
    ti = Term2::Components::TextInput.new
    ti.value = "abc"
    ti.cursor_pos = 1
    ti.focus

    # Prompt "> "
    # Left "a"
    # Cursor "b" (reversed)
    # Right "c"

    # We expect ANSI codes for reverse video on 'b'
    # And prompt

    view = ti.view
    view.should contain "> "
    view.should contain "a"
    view.should contain "c"
    # Check for reverse video code around 'b'
    # \e[7mb\e[0m or similar
    view.should match /\e\[0;7mb\e\[0m/
  end
end
