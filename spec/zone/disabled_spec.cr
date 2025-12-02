require "../spec_helper"

describe "Term2::Zone when disabled" do
  before_each do
    Term2::Zone.reset
    Term2::Zone.enabled = false
  end

  after_each do
    Term2::Zone.enabled = true
    Term2::Zone.reset
  end

  it "returns plain content from mark" do
    Term2::Zone.mark("foo", "bar").should eq("bar")
    Term2::Zone.mark("foo", "").should eq("")
  end

  it "scans without registering zones" do
    content = "a" + Term2::Zone.mark("foo", "b") + "c"
    Term2::Zone.scan(content).should eq("abc")
    sleep 50.milliseconds
    Term2::Zone.get("foo").is_zero?.should be_true
  end
end
