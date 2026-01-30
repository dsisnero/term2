require "../spec_helper"
require "../../src/components/cursor"

describe Term2::Components::Cursor do
  it "initializes with defaults" do
    cursor = Term2::Components::Cursor.new
    cursor.mode.should eq Term2::Components::Cursor::Mode::Blink
    cursor.blink?.should be_true
    cursor.focus?.should be_false
  end

  it "handles focus and blur" do
    cursor = Term2::Components::Cursor.new

    # Focus
    cmd = cursor.focus_cmd
    cursor.focus?.should be_true
    # Bubble Tea parity: focused cursor starts in the visible "block" phase.
    cursor.blink?.should be_false
    cmd.should_not be_nil # Should return a blink command

    # Blur
    cursor.blur
    cursor.focus?.should be_false
    cursor.blink?.should be_true # Resets to visible on blur
  end

  it "toggles blink on BlinkMsg" do
    cursor = Term2::Components::Cursor.new
    cursor.focus_cmd # Start blinking, sets tag

    # We need to know the tag. It's private.
    # But we can inspect the cursor state.
    # Let's just simulate the message flow if we can guess the tag.
    # The tag starts at 0 and increments on focus.
    # So after one focus, tag should be 1.

    # Initial state after focus is blink=false (visible block).
    cursor.blink?.should be_false

    # First blink tick (tag 1) toggles to hidden (blink=true) and schedules next tick (tag 2).
    msg1 = Term2::Components::Cursor::BlinkMsg.new(1)
    cursor, cmd = cursor.update(msg1)
    cursor.blink?.should be_true
    cmd.should_not be_nil

    # Next tick (tag 2) toggles back to visible (blink=false).
    msg2 = Term2::Components::Cursor::BlinkMsg.new(2)
    cursor, _ = cursor.update(msg2)
    cursor.blink?.should be_false
  end

  it "ignores BlinkMsg with wrong tag" do
    cursor = Term2::Components::Cursor.new
    cursor.focus_cmd # tag becomes 1

    msg = Term2::Components::Cursor::BlinkMsg.new(999)

    cursor, _ = cursor.update(msg)
    cursor.blink?.should be_false # No change
    # cmd should be none? Wait, update returns {self, Cmd.none} by default.
    # We can't easily check if Cmd is none because it's a struct wrapping a proc.
    # But we can check if state changed.
  end

  it "renders correctly" do
    cursor = Term2::Components::Cursor.new
    cursor.char = "A"

    # Not focused -> renders text style (A)
    cursor.view.content.should eq "A"

    # Focused and visible -> renders cursor style (reverse A)
    cursor.focus_cmd
    # Default style is reverse.
    # Term2::Style.new.reverse(true).render("A") produces "\e[7mA\e[0m"
    cursor.view.content.should eq "\e[7mA\e[0m"

    # Focused and hidden (blink off)
    # We need to manually toggle blink state since we can't wait for timer
    # We can use a hack or just trust the update logic tested above.
    # Let's force blink to false by sending a message.
    msg = Term2::Components::Cursor::BlinkMsg.new(1)
    cursor.update(msg)
    cursor.view.content.should eq "A"
  end
end
