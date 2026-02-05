require "../spec_helper"

class HasRunFinish < Similar::Algorithms::DiffHook
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

describe Similar::Algorithms::Myers do
  it "test_find_middle_snake" do
    a = "ABCABBA".bytes
    b = "CBABAC".bytes
    max_d = Similar::Algorithms::Myers.max_d(a.size, b.size)
    vf = Similar::Algorithms::Myers::V.new(max_d)
    vb = Similar::Algorithms::Myers::V.new(max_d)
    snake = Similar::Algorithms::Myers.find_middle_snake(a, 0...a.size, b, 0...b.size, vf, vb, nil)
    snake.should_not be_nil
    x_start, y_start = snake.not_nil!
    x_start.should eq(4)
    y_start.should eq(1)
  end

  it "test_diff" do
    a = [0, 1, 2, 3, 4]
    b = [0, 1, 2, 9, 4]

    d = Similar::Algorithms::Replace.new(Similar::Algorithms::Capture.new)
    Similar::Algorithms::Myers.diff(a, 0...a.size, b, 0...b.size, d)
    ops = d.inner.ops

    ops.size.should eq(3)

    # Expected: Equal(0,0,3), Replace(3,1,3,1), Equal(4,4,1)
    ops[0].should be_a(Similar::DiffOp::Equal)
    ops[0].as(Similar::DiffOp::Equal).old_index.should eq(0)
    ops[0].as(Similar::DiffOp::Equal).new_index.should eq(0)
    ops[0].as(Similar::DiffOp::Equal).len.should eq(3)

    ops[1].should be_a(Similar::DiffOp::Replace)
    ops[1].as(Similar::DiffOp::Replace).old_index.should eq(3)
    ops[1].as(Similar::DiffOp::Replace).old_len.should eq(1)
    ops[1].as(Similar::DiffOp::Replace).new_index.should eq(3)
    ops[1].as(Similar::DiffOp::Replace).new_len.should eq(1)

    ops[2].should be_a(Similar::DiffOp::Equal)
    ops[2].as(Similar::DiffOp::Equal).old_index.should eq(4)
    ops[2].as(Similar::DiffOp::Equal).new_index.should eq(4)
    ops[2].as(Similar::DiffOp::Equal).len.should eq(1)
  end

  it "test_contiguous" do
    a = [0, 1, 2, 3, 4, 4, 4, 5]
    b = [0, 1, 2, 8, 9, 4, 4, 7]

    d = Similar::Algorithms::Replace.new(Similar::Algorithms::Capture.new)
    Similar::Algorithms::Myers.diff(a, 0...a.size, b, 0...b.size, d)
    ops = d.inner.ops

    ops.size.should eq(4)

    # Expected from snapshot:
    # Equal(0,0,3), Replace(3,1,3,2), Equal(4,5,2), Replace(6,2,7,1)
    ops[0].should be_a(Similar::DiffOp::Equal)
    ops[0].as(Similar::DiffOp::Equal).old_index.should eq(0)
    ops[0].as(Similar::DiffOp::Equal).new_index.should eq(0)
    ops[0].as(Similar::DiffOp::Equal).len.should eq(3)

    ops[1].should be_a(Similar::DiffOp::Replace)
    ops[1].as(Similar::DiffOp::Replace).old_index.should eq(3)
    ops[1].as(Similar::DiffOp::Replace).old_len.should eq(1)
    ops[1].as(Similar::DiffOp::Replace).new_index.should eq(3)
    ops[1].as(Similar::DiffOp::Replace).new_len.should eq(2)

    ops[2].should be_a(Similar::DiffOp::Equal)
    ops[2].as(Similar::DiffOp::Equal).old_index.should eq(4)
    ops[2].as(Similar::DiffOp::Equal).new_index.should eq(5)
    ops[2].as(Similar::DiffOp::Equal).len.should eq(2)

    ops[3].should be_a(Similar::DiffOp::Replace)
    ops[3].as(Similar::DiffOp::Replace).old_index.should eq(6)
    ops[3].as(Similar::DiffOp::Replace).old_len.should eq(2)
    ops[3].as(Similar::DiffOp::Replace).new_index.should eq(7)
    ops[3].as(Similar::DiffOp::Replace).new_len.should eq(1)
  end

  it "test_pat" do
    a = [0, 1, 3, 4, 5]
    b = [0, 1, 4, 5, 8, 9]

    d = Similar::Algorithms::Capture.new
    Similar::Algorithms::Myers.diff(a, 0...a.size, b, 0...b.size, d)
    ops = d.ops

    ops.size.should eq(5)

    # Expected from snapshot:
    # Equal(0,0,2), Delete(2,1,2), Equal(3,2,2), Insert(5,4,1), Insert(5,5,1)
    ops[0].should be_a(Similar::DiffOp::Equal)
    ops[0].as(Similar::DiffOp::Equal).old_index.should eq(0)
    ops[0].as(Similar::DiffOp::Equal).new_index.should eq(0)
    ops[0].as(Similar::DiffOp::Equal).len.should eq(2)

    ops[1].should be_a(Similar::DiffOp::Delete)
    ops[1].as(Similar::DiffOp::Delete).old_index.should eq(2)
    ops[1].as(Similar::DiffOp::Delete).old_len.should eq(1)
    ops[1].as(Similar::DiffOp::Delete).new_index.should eq(2)

    ops[2].should be_a(Similar::DiffOp::Equal)
    ops[2].as(Similar::DiffOp::Equal).old_index.should eq(3)
    ops[2].as(Similar::DiffOp::Equal).new_index.should eq(2)
    ops[2].as(Similar::DiffOp::Equal).len.should eq(2)

    ops[3].should be_a(Similar::DiffOp::Insert)
    ops[3].as(Similar::DiffOp::Insert).old_index.should eq(5)
    ops[3].as(Similar::DiffOp::Insert).new_index.should eq(4)
    ops[3].as(Similar::DiffOp::Insert).new_len.should eq(1)

    ops[4].should be_a(Similar::DiffOp::Insert)
    ops[4].as(Similar::DiffOp::Insert).old_index.should eq(5)
    ops[4].as(Similar::DiffOp::Insert).new_index.should eq(5)
    ops[4].as(Similar::DiffOp::Insert).new_len.should eq(1)
  end

  it "test_finish_called" do
    d = HasRunFinish.new
    slice = [1, 2]
    slice2 = [1, 2, 3]
    Similar::Algorithms::Myers.diff(slice, 0...slice.size, slice2, 0...slice2.size, d)
    d.called?.should be_true

    d = HasRunFinish.new
    Similar::Algorithms::Myers.diff(slice, 0...slice.size, slice, 0...slice.size, d)
    d.called?.should be_true

    d = HasRunFinish.new
    empty_slice = [] of Int32
    Similar::Algorithms::Myers.diff(empty_slice, 0...empty_slice.size, empty_slice, 0...empty_slice.size, d)
    d.called?.should be_true
  end
end
