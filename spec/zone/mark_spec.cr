require "../spec_helper"

describe "Term2::Zone.mark" do
  before_each do
    Term2::Zone.reset
  end

  it "wraps content with stable markers" do
    first = Term2::Zone.mark("foo", "bar")
    second = Term2::Zone.mark("foo", "bar")
    first.should eq(second)
    first.should contain("\e[")
    first.should contain("z")
    first.should contain("bar")
  end

  it "generates different markers for different ids" do
    first = Term2::Zone.mark("foo", "bar")
    second = Term2::Zone.mark("bar", "bar")
    first.should_not eq(second)
  end

  it "returns content unchanged when empty" do
    Term2::Zone.mark("foo", "").should eq("")
  end

  it "respects disabled state" do
    Term2::Zone.enabled = false
    Term2::Zone.mark("foo", "bar").should eq("bar")
    Term2::Zone.enabled = true
  end

  it "can be scanned to recover zone data" do
    marked = Term2::Zone.mark("demo", "content")
    Term2::Zone.scan(marked).should eq("content")
    sleep 50.milliseconds
    Term2::Zone.get("demo").is_zero?.should be_false
  end
end
