require "../spec_helper"

class HasRunFinishPatience < Similar::Algorithms::DiffHook
  @called = false

  def called? : Bool
    @called
  end

  def equal(old_index : Int32, new_index : Int32, len : Int32) : Nil
  end

  def delete(old_index : Int32, old_len : Int32, new_index : Int32) : Nil
  end

  def insert(old_index : Int32, new_index : Int32, new_len : Int32) : Nil
  end

  def replace(old_index : Int32, old_len : Int32, new_index : Int32, new_len : Int32) : Nil
  end

  def finish : Nil
    @called = true
  end
end

describe Similar::Algorithms::Patience do
  it "test_patience" do
    a = [11, 1, 2, 2, 3, 4, 4, 4, 5, 47, 19]
    b = [10, 1, 2, 2, 8, 9, 4, 4, 7, 47, 18]

    d = Similar::Algorithms::Replace.new(Similar::Algorithms::Capture.new)
    Similar::Algorithms.diff_slices(Similar::Algorithm::Patience, d, a, b)
    ops = d.inner.ops

    ops.size.should eq(7)

    # Expected ops from snapshot
    ops[0].should be_a(Similar::DiffOp::Replace)
    ops[0].as(Similar::DiffOp::Replace).old_index.should eq(0)
    ops[0].as(Similar::DiffOp::Replace).old_len.should eq(1)
    ops[0].as(Similar::DiffOp::Replace).new_index.should eq(0)
    ops[0].as(Similar::DiffOp::Replace).new_len.should eq(1)

    ops[1].should be_a(Similar::DiffOp::Equal)
    ops[1].as(Similar::DiffOp::Equal).old_index.should eq(1)
    ops[1].as(Similar::DiffOp::Equal).new_index.should eq(1)
    ops[1].as(Similar::DiffOp::Equal).len.should eq(3)

    ops[2].should be_a(Similar::DiffOp::Replace)
    ops[2].as(Similar::DiffOp::Replace).old_index.should eq(4)
    ops[2].as(Similar::DiffOp::Replace).old_len.should eq(1)
    ops[2].as(Similar::DiffOp::Replace).new_index.should eq(4)
    ops[2].as(Similar::DiffOp::Replace).new_len.should eq(2)

    ops[3].should be_a(Similar::DiffOp::Equal)
    ops[3].as(Similar::DiffOp::Equal).old_index.should eq(5)
    ops[3].as(Similar::DiffOp::Equal).new_index.should eq(6)
    ops[3].as(Similar::DiffOp::Equal).len.should eq(2)

    ops[4].should be_a(Similar::DiffOp::Replace)
    ops[4].as(Similar::DiffOp::Replace).old_index.should eq(7)
    ops[4].as(Similar::DiffOp::Replace).old_len.should eq(2)
    ops[4].as(Similar::DiffOp::Replace).new_index.should eq(8)
    ops[4].as(Similar::DiffOp::Replace).new_len.should eq(1)

    ops[5].should be_a(Similar::DiffOp::Equal)
    ops[5].as(Similar::DiffOp::Equal).old_index.should eq(9)
    ops[5].as(Similar::DiffOp::Equal).new_index.should eq(9)
    ops[5].as(Similar::DiffOp::Equal).len.should eq(1)

    ops[6].should be_a(Similar::DiffOp::Replace)
    ops[6].as(Similar::DiffOp::Replace).old_index.should eq(10)
    ops[6].as(Similar::DiffOp::Replace).old_len.should eq(1)
    ops[6].as(Similar::DiffOp::Replace).new_index.should eq(10)
    ops[6].as(Similar::DiffOp::Replace).new_len.should eq(1)
  end

  it "test_patience_out_of_bounds_bug" do
    a = [1, 2, 3, 4]
    b = [1, 2, 3]

    d = Similar::Algorithms::Replace.new(Similar::Algorithms::Capture.new)
    Similar::Algorithms.diff_slices(Similar::Algorithm::Patience, d, a, b)
    ops = d.inner.ops

    ops.size.should eq(2)

    ops[0].should be_a(Similar::DiffOp::Equal)
    ops[0].as(Similar::DiffOp::Equal).old_index.should eq(0)
    ops[0].as(Similar::DiffOp::Equal).new_index.should eq(0)
    ops[0].as(Similar::DiffOp::Equal).len.should eq(3)

    ops[1].should be_a(Similar::DiffOp::Delete)
    ops[1].as(Similar::DiffOp::Delete).old_index.should eq(3)
    ops[1].as(Similar::DiffOp::Delete).old_len.should eq(1)
    ops[1].as(Similar::DiffOp::Delete).new_index.should eq(3)
  end

  it "test_finish_called" do
    d = HasRunFinishPatience.new
    slice = [1, 2]
    slice2 = [1, 2, 3]
    Similar::Algorithms::Patience.diff(slice, 0...slice.size, slice2, 0...slice2.size, d)
    d.called?.should be_true

    d = HasRunFinishPatience.new
    Similar::Algorithms::Patience.diff(slice, 0...slice.size, slice, 0...slice.size, d)
    d.called?.should be_true

    d = HasRunFinishPatience.new
    empty_slice = [] of Int32
    Similar::Algorithms::Patience.diff(empty_slice, 0...empty_slice.size, empty_slice, 0...empty_slice.size, d)
    d.called?.should be_true
  end
end
