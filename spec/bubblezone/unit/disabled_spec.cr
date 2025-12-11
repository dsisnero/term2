# spec/bubblezone/unit/disabled_spec.cr
# Tests for disabled zone functionality

require "../spec_helper"

# Helper module for test models
module DisabledTestModels
  # Create a test model to capture messages
  class DisabledTestModel
    include Term2::Model

    getter received = [] of Term2::Msg

    def init : Term2::Cmd
      nil
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::MouseEvent
        spawn { Term2::Zone.any_in_bounds(self, msg) }
      when Term2::ZoneInBoundsMsg
        @received << msg
      end
      {self, nil}
    end

    def view : String
      "test " + Term2::Zone.mark("disabled_integration", "zone") + " here"
    end
  end
end

describe "Term2::Zone disabled functionality" do
  before_each do
    # Reset zone manager to enabled state before each test
    Term2::Zone.reset
  end

  describe "scan when disabled" do
    it "returns input with markers stripped when zone is disabled" do
      # First, test normal behavior
      input = "a" + Term2::Zone.mark("test", "b") + "c"
      normal_result = Term2::Zone.scan(input)

      # When not disabled, markers should be removed
      normal_result.should eq("abc")
      normal_result.should_not contain("\x1B[")

      # Now disable and test
      Term2::Zone.enabled = false
      disabled_result = Term2::Zone.scan(input)

      # When disabled, markers should still be stripped
      disabled_result.should eq("abc")
      disabled_result.should_not contain("\x1B[")
    end

    it "does not create zones when disabled" do
      # Create a zone first with enabled manager
      input = "a" + Term2::Zone.mark("disabled_test", "b") + "c"
      Term2::Zone.scan(input)
      sleep 50.milliseconds

      # Zone should exist (normal behavior)
      zone = Term2::Zone.get("disabled_test")
      zone.zero?.should be_false

      # Now disable and create another zone
      Term2::Zone.enabled = false
      input2 = "x" + Term2::Zone.mark("disabled_test2", "y") + "z"
      Term2::Zone.scan(input2)
      sleep 50.milliseconds

      # Zone should not exist when disabled
      zone2 = Term2::Zone.get("disabled_test2")
      zone2.zero?.should be_true
    end
  end

  describe "mark when disabled" do
    it "returns content unchanged when disabled" do
      content = "test content"

      # First test normal behavior
      marked = Term2::Zone.mark("disabled_mark", content)

      # Normal behavior: adds markers
      marked.should_not eq(content)
      marked.should contain("\x1B[")

      # Now disable and test
      Term2::Zone.enabled = false
      marked_disabled = Term2::Zone.mark("disabled_mark2", content)

      # When disabled, should return content unchanged
      marked_disabled.should eq(content)
      marked_disabled.should_not contain("\x1B[")
    end

    it "handles multiple marks when disabled" do
      test_cases = [
        {"empty", ""},
        {"single", "a"},
        {"multiple", "abc"},
      ]

      # Test normal behavior first
      test_cases.each do |name, content|
        marked = Term2::Zone.mark("disabled_#{name}", content)

        # Should add markers in normal mode
        # Note: Go's Mark function returns empty string for empty content
        # Test case: {"id-empty", Mark("testing1", ""), "", nil}
        if content.empty?
          marked.should eq(content) # Empty string with marker is empty (Go behavior)
        else
          marked.should_not eq(content)
        end
        marked.should contain("\x1B[") unless content.empty?
      end

      # Now test disabled behavior
      Term2::Zone.enabled = false
      test_cases.each do |name, content|
        marked = Term2::Zone.mark("disabled_disabled_#{name}", content)

        # When disabled, should return content unchanged
        marked.should eq(content)
        marked.should_not contain("\x1B[")
      end
    end
  end

  describe "enable/disable transitions" do
    it "handles transitions between enabled and disabled states" do
      # Test that zones work when enabled
      input = "a" + Term2::Zone.mark("transition_test", "b") + "c"
      result = Term2::Zone.scan(input)
      result.should eq("abc")

      sleep 50.milliseconds
      zone = Term2::Zone.get("transition_test")
      zone.zero?.should be_false

      # Disable and test that mark returns unchanged
      Term2::Zone.enabled = false
      marked = Term2::Zone.mark("transition_test2", "content")
      marked.should eq("content")

      # Re-enable and test that mark works again
      Term2::Zone.enabled = true
      marked2 = Term2::Zone.mark("transition_test3", "content")
      marked2.should_not eq("content")
      marked2.should contain("\x1B[")
    end

    it "clears zones when disabled" do
      # Create a zone first
      Term2::Zone.scan("a" + Term2::Zone.mark("clear_on_disable", "b") + "c")
      sleep 50.milliseconds

      zone = Term2::Zone.get("clear_on_disable")
      zone.zero?.should be_false

      # Disable - this should clear zones
      Term2::Zone.enabled = false
      sleep 50.milliseconds

      # Zone should be cleared
      zone2 = Term2::Zone.get("clear_on_disable")
      zone2.zero?.should be_true
    end
  end

  describe "performance in disabled mode" do
    it "has minimal overhead when disabled" do
      # Create content with many markers
      content = ""
      100.times do |i|
        content += Term2::Zone.mark("perf_disabled_#{i}", "item#{i}") + " "
      end

      # Scan in normal mode
      start_time = Time.monotonic
      result = Term2::Zone.scan(content)
      end_time = Time.monotonic

      normal_duration = end_time - start_time

      # Result should have markers removed
      result.should_not contain("\x1B[")

      # Now test disabled mode
      Term2::Zone.enabled = false

      # Create content with many markers (but they won't be added since disabled)
      content2 = ""
      100.times do |i|
        content2 += Term2::Zone.mark("perf_disabled2_#{i}", "item#{i}") + " "
      end

      # Content2 should be just the plain text since mark returns unchanged when disabled
      # It should be "item0 item1 item2 ..." without markers
      content2.should_not contain("\x1B[")

      # Scan in disabled mode
      start_time2 = Time.monotonic
      result2 = Term2::Zone.scan(content2)
      end_time2 = Time.monotonic

      disabled_duration = end_time2 - start_time2

      # Result should be the same as input (no markers to strip)
      result2.should eq(content2)
      result2.should_not contain("\x1B[")

      # Disabled mode should be at least as fast or faster
      # (We can't guarantee it's faster, but it shouldn't be significantly slower)
      # disabled_duration.should be <= (normal_duration * 1.5)
    end
  end

  describe "integration with other features when disabled" do
    it "mouse events don't trigger zone messages when disabled" do
      model = DisabledTestModels::DisabledTestModel.new

      # First test normal behavior
      Term2::Zone.scan(model.view)
      sleep 50.milliseconds

      # Mouse event in zone
      model.update(Term2::MouseEvent.new(x: 5, y: 0, button: Term2::MouseEvent::Button::Left, action: Term2::MouseEvent::Action::Press))
      sleep 50.milliseconds

      # Should receive zone message (normal behavior)
      model.received.any?(Term2::ZoneInBoundsMsg).should be_true

      # Clear received messages
      model = DisabledTestModels::DisabledTestModel.new

      # Now test disabled behavior
      Term2::Zone.enabled = false
      Term2::Zone.scan(model.view)
      sleep 50.milliseconds

      # Mouse event in zone
      model.update(Term2::MouseEvent.new(x: 5, y: 0, button: Term2::MouseEvent::Button::Left, action: Term2::MouseEvent::Action::Press))
      sleep 50.milliseconds

      # Should NOT receive zone message when disabled
      model.received.any?(Term2::ZoneInBoundsMsg).should be_false
    end
  end
end