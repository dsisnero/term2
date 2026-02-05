require "./spec_helper"

describe Similar do
  it "has version" do
    Similar::VERSION.should be_a(String)
  end

  it "can diff simple arrays with Myers algorithm" do
    a = [1, 2, 3]
    b = [1, 2, 4]
    d = Similar::Algorithms::Replace.new(Similar::Algorithms::Capture.new)
    Similar::Algorithms.diff_slices(Similar::Algorithm::Myers, d, a, b)
    ops = d.inner.ops
    ops.size.should eq(2)
    ops[0].should be_a(Similar::DiffOp::Equal)
    ops[0].as(Similar::DiffOp::Equal).len.should eq(2)
    ops[1].should be_a(Similar::DiffOp::Replace)
  end
end
