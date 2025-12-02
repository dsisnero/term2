require "../spec_helper"

describe "Term2::Zone manager semantics" do
  before_each do
    Term2::Zone.reset
  end

  it "clears specific zones" do
    Term2::Zone.register("foo", 0, 0, 5, 5)
    Term2::Zone.get("foo").is_zero?.should be_false
    Term2::Zone.clear("foo")
    sleep 10.milliseconds
    Term2::Zone.get("foo").is_zero?.should be_true
  end

  it "clears all zones" do
    Term2::Zone.register("foo", 0, 0, 5, 5)
    Term2::Zone.register("bar", 1, 1, 2, 2)
    Term2::Zone.clear_all
    sleep 10.milliseconds
    Term2::Zone.get("foo").is_zero?.should be_true
    Term2::Zone.get("bar").is_zero?.should be_true
  end

  it "clears old zones when new scan runs" do
    Term2::Zone.scan("a" + Term2::Zone.mark("foo", "b") + "c")
    sleep 20.milliseconds
    Term2::Zone.scan("a" + Term2::Zone.mark("bar", "b") + "c")
    sleep 20.milliseconds
    Term2::Zone.get("bar").is_zero?.should be_false
    Term2::Zone.get("foo").is_zero?.should be_true
  end

  it "stops tracking after close" do
    Term2::Zone.register("zone1", 0, 0, 5, 5)
    Term2::Zone.close
    sleep 10.milliseconds
    Term2::Zone.scan("a" + Term2::Zone.mark("foo", "b") + "c").should eq("abc")
    sleep 20.milliseconds
    Term2::Zone.get("foo").is_zero?.should be_true
  ensure
    Term2::Zone.reset
  end
end
