require "../spec_helper"

describe Term2::ZoneInfo do
  before_each do
    Term2::Zone.reset
  end

  it "returns correct coordinates" do
    Term2::Zone.scan("test\nfoo\naaa " + Term2::Zone.mark("foo", "bar\ntest123456789") + " aaa\nbaz")
    sleep 50.milliseconds
    zone = Term2::Zone.get("foo")
    zone.is_zero?.should be_false
    zone.start_x.should eq(4)
    zone.start_y.should eq(2)
    zone.end_x.should eq(12)
    zone.end_y.should eq(3)
  end

  it "handles in_bounds? correctly" do
    Term2::Zone.scan("test\nfoo\naaa " + Term2::Zone.mark("foo", "bar\ntest123456789") + " aaa\nbaz")
    sleep 50.milliseconds
    zone = Term2::Zone.get("foo")
    zone.is_zero?.should be_false

    zone.in_bounds?(4, 2).should be_true
    zone.in_bounds?(12, 3).should be_true
    zone.in_bounds?(8, 2).should be_true
    zone.in_bounds?(4, 3).should be_true

    zone.in_bounds?(0, 0).should be_false
    zone.in_bounds?(3, 3).should be_false
    zone.in_bounds?(99, 99).should be_false
    zone.in_bounds?(13, 3).should be_false
    zone.in_bounds?(4, 1).should be_false
    zone.in_bounds?(4, 4).should be_false
  end

  it "returns false for zero or unknown zones" do
    zero = Term2::ZoneInfo.new
    zero.in_bounds?(0, 0).should be_false

    unknown = Term2::Zone.get("missing")
    unknown.is_zero?.should be_true
    unknown.in_bounds?(0, 0).should be_false
  end

  it "returns relative positions" do
    Term2::Zone.scan("test\nfoo\naaa " + Term2::Zone.mark("foo", "bar\ntest123456789") + " aaa\nbaz")
    sleep 50.milliseconds
    zone = Term2::Zone.get("foo")
    zone.is_zero?.should be_false

    x, y = zone.pos(4, 2)
    x.should eq(0); y.should eq(0)

    x, y = zone.pos(5, 2)
    x.should eq(1); y.should eq(0)

    x, y = zone.pos(4, 3)
    x.should eq(0); y.should eq(1)

    x, y = zone.pos(12, 3)
    x.should eq(8); y.should eq(1)
  end

  it "returns -1,-1 for out-of-bounds or zero" do
    zone = Term2::ZoneInfo.new
    x, y = zone.pos(0, 0)
    x.should eq(-1); y.should eq(-1)

    Term2::Zone.scan("test\nfoo\naaa " + Term2::Zone.mark("foo", "bar\ntest123456789") + " aaa\nbaz")
    sleep 50.milliseconds
    zone = Term2::Zone.get("foo")
    x, y = zone.pos(0, 0)
    x.should eq(-1); y.should eq(-1)
  end

  it "updates bounds across scans" do
    Term2::Zone.scan("test\nfoo\naaa " + Term2::Zone.mark("foo", "bar\ntest123456789") + " aaa\nbaz")
    sleep 50.milliseconds
    Term2::Zone.scan("test " + Term2::Zone.mark("foo", "bar\nt") + " other things here")
    sleep 50.milliseconds
    zone = Term2::Zone.get("foo")
    zone.in_bounds?(2, 1).should be_false
  end
end
