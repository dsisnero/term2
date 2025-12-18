# spec/bubblezone/unit/zoneinfo_spec.cr
# Port of zoneinfo_test.go tests

require "../spec_helper"

def mouse(x : Int32, y : Int32)
  Term2::MouseEvent.new(x, y, Term2::MouseEvent::Button::None, Term2::MouseEvent::Action::Press)
end

def zero_zone
  Term2::ZoneInfo.new("", 0, 0, -1, -1, 0)
end

describe "Term2::Zone zoneinfo functionality" do
  describe "valid_position" do
    it "correctly calculates zone position from scanned text" do
      # Test from Go: Starts at X:4, Y:2, ends at X:12, Y:3.
      text = "test\nfoo\naaa " + Term2::Zone.mark("foo", "bar\ntest123456789") + " aaa\nbaz"

      result = BubbleZoneHelpers.scan_and_wait(text, 100)

      # The scanned text should have markers removed.
      expected = "test\nfoo\naaa bar\ntest123456789 aaa\nbaz"
      result.should eq(expected)

      zone = Term2::Zone.get("foo")
      zone.zero?.should be_false

      zone.start_x.should eq(4)
      zone.start_y.should eq(2)
      zone.end_x.should eq(12)
      zone.end_y.should eq(3)
    end
  end

  describe "in_bounds?" do
    it "correctly checks if points are within zone bounds" do
      # Setup zone: Starts at X:4, Y:2, ends at X:12, Y:3.
      text = "test\nfoo\naaa " + Term2::Zone.mark("foo", "bar\ntest123456789") + " aaa\nbaz"
      BubbleZoneHelpers.scan_and_wait(text, 100)

      zone = Term2::Zone.get("foo")
      zone.zero?.should be_false

      # Outside left
      zone.in_bounds?(mouse(0, 0)).should be_false

      # Outside directly left
      zone.in_bounds?(mouse(3, 3)).should be_false

      # Outside right
      zone.in_bounds?(mouse(99, 99)).should be_false

      # Outside directly right
      zone.in_bounds?(mouse(13, 3)).should be_false

      # Outside top
      zone.in_bounds?(mouse(4, 1)).should be_false

      # Outside bottom
      zone.in_bounds?(mouse(4, 4)).should be_false

      # Inside left top
      zone.in_bounds?(mouse(4, 2)).should be_true

      # Inside right bottom
      zone.in_bounds?(mouse(12, 3)).should be_true

      # Test with different zone
      text2 = "test " + Term2::Zone.mark("foo", "bar\nt") + " other things here"
      BubbleZoneHelpers.scan_and_wait(text2, 100)

      zone2 = Term2::Zone.get("foo")
      zone2.in_bounds?(mouse(2, 1)).should be_false
    end
  end

  describe "in_bounds with zero zone" do
    it "returns false for zero zone" do
      empty_zone = zero_zone
      empty_zone.in_bounds?(mouse(0, 0)).should be_false

      non_existent = Term2::Zone.get("non-existent")
      non_existent.in_bounds?(mouse(0, 0)).should be_false
    end
  end

  describe "pos" do
    it "calculates relative position within zone" do
      # Setup zone: Starts at X:4, Y:2, ends at X:12, Y:3.
      text = "test\nfoo\naaa " + Term2::Zone.mark("foo", "bar\ntest123456789") + " aaa\nbaz"
      BubbleZoneHelpers.scan_and_wait(text, 100)

      zone = Term2::Zone.get("foo")
      zone.zero?.should be_false

      # Top-left corner
      x, y = zone.pos(mouse(4, 2))
      x.should eq(0)
      y.should eq(0)

      # One right from top-left
      x, y = zone.pos(mouse(5, 2))
      x.should eq(1)
      y.should eq(0)

      # Test with zero zone
      empty_zone = zero_zone
      x, y = empty_zone.pos(mouse(0, 0))
      x.should eq(-1)
      y.should eq(-1)

      # Test with non-existent zone
      non_existent = Term2::Zone.get("non-existent")
      x, y = non_existent.pos(mouse(0, 0))
      x.should eq(-1)
      y.should eq(-1)
    end
  end

  describe "zone dimensions" do
    it "calculates width and height correctly" do
      zone = Term2::ZoneInfo.new("test", 5, 10, 15, 20)
      zone.width.should eq(11)  # 15 - 5 + 1
      zone.height.should eq(11) # 20 - 10 + 1

      zone2 = Term2::ZoneInfo.new("test2", 0, 0, 0, 0)
      zone2.width.should eq(1)
      zone2.height.should eq(1)
    end
  end
end
