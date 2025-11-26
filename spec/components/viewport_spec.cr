require "../spec_helper"
require "../../src/components/viewport"

describe Term2::Components::Viewport do
  it "renders content correctly" do
    vp = Term2::Components::Viewport.new(20, 3)
    vp.content = "Line 1\nLine 2\nLine 3\nLine 4\nLine 5"

    # Should show first 3 lines
    output = vp.view
    # Strip ANSI codes for easier testing
    plain_output = output.gsub(/\e\[[0-9;]*[mH]/, "").gsub(/\e\[[0-9;]*[A-Z]/, "")
    # The renderer might output "Line 1Line 2Line 3" if it uses absolute positioning without newlines
    # So we check if it contains the lines
    plain_output.should contain "Line 1"
    plain_output.should contain "Line 2"
    plain_output.should contain "Line 3"
    plain_output.should_not contain "Line 4"
  end

  it "scrolls down" do
    vp = Term2::Components::Viewport.new(20, 3)
    vp.content = "Line 1\nLine 2\nLine 3\nLine 4\nLine 5"

    # Scroll down one line
    msg = Term2::KeyMsg.new(Term2::Key.new("down"))
    vp, _ = vp.update(msg)
    vp.y_offset.should eq 1

    # Scroll down two lines
    msg = Term2::KeyMsg.new(Term2::Key.new("down"))
    vp, _ = vp.update(msg)
    vp.y_offset.should eq 2

    # Try to scroll down past the end
    msg = Term2::KeyMsg.new(Term2::Key.new("down"))
    vp, _ = vp.update(msg)
    vp.y_offset.should eq 2 # Clamped
  end

  it "scrolls up" do
    vp = Term2::Components::Viewport.new(20, 3)
    vp.content = "Line 1\nLine 2\nLine 3\nLine 4\nLine 5"

    # Scroll down to bottom
    vp.goto_bottom
    vp.y_offset.should eq 2

    # Scroll up one line
    msg = Term2::KeyMsg.new(Term2::Key.new("up"))
    vp, _ = vp.update(msg)
    vp.y_offset.should eq 1

    # Scroll up two lines
    msg = Term2::KeyMsg.new(Term2::Key.new("up"))
    vp, _ = vp.update(msg)
    vp.y_offset.should eq 0

    # Try to scroll up past the top
    msg = Term2::KeyMsg.new(Term2::Key.new("up"))
    vp, _ = vp.update(msg)
    vp.y_offset.should eq 0 # Clamped
  end

  it "handles page scrolling" do
    vp = Term2::Components::Viewport.new(20, 3)
    vp.content = "Line 1\nLine 2\nLine 3\nLine 4\nLine 5"

    # Page down (Space is also bound to page down)
    msg = Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Space))
    vp, _ = vp.update(msg)
    vp.y_offset.should eq 2

    # Page down again (clamped)
    msg = Term2::KeyMsg.new(Term2::Key.new("pgdn"))
    vp, _ = vp.update(msg)
    vp.y_offset.should eq 2

    # Page up
    msg = Term2::KeyMsg.new(Term2::Key.new("pgup"))
    vp, _ = vp.update(msg)
    vp.y_offset.should eq 0

    # Page up again (clamped)
    msg = Term2::KeyMsg.new(Term2::Key.new("pgup"))
    vp, _ = vp.update(msg)
    vp.y_offset.should eq 0
  end
end
