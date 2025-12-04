require "../spec_helper"
require "../../src/components/cursor"

describe Term2::Components::Cursor do
  it "toggles visibility on valid blink messages" do
    cursor = Term2::Components::Cursor.new
    cursor.focus_cmd

    msg = Term2::Components::Cursor::BlinkMsg.new(1)
    cursor, cmd = cursor.update(msg)
    cursor.blink?.should be_false
    cmd.should_not be_nil
  end

  it "ignores stale blink messages after blur" do
    cursor = Term2::Components::Cursor.new
    cursor.focus_cmd
    cursor.blur

    stale = Term2::Components::Cursor::BlinkMsg.new(1)
    cursor, cmd = cursor.update(stale)

    cursor.blink?.should be_true
    cmd.should be_nil
  end
end
