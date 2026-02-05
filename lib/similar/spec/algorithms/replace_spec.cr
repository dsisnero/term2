require "../spec_helper"

describe Similar::Algorithms::Replace do
  it "test_mayers_replace" do
    a = [
      ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n",
      "a\n",
      "b\n",
      "c\n",
      "================================\n",
      "d\n",
      "e\n",
      "f\n",
      "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n",
    ]
    b = [
      ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n",
      "x\n",
      "b\n",
      "c\n",
      "================================\n",
      "y\n",
      "e\n",
      "f\n",
      "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n",
    ]

    d = Similar::Algorithms::Replace.new(Similar::Algorithms::Capture.new)
    Similar::Algorithms.diff_slices(Similar::Algorithm::Myers, d, a, b)
    ops = d.inner.ops

    ops.size.should eq(5)

    # Expected ops from Rust snapshot:
    # Equal { old_index: 0, new_index: 0, len: 1 }
    # Replace { old_index: 1, old_len: 1, new_index: 1, new_len: 1 }
    # Equal { old_index: 2, new_index: 2, len: 3 }
    # Replace { old_index: 5, old_len: 1, new_index: 5, new_len: 1 }
    # Equal { old_index: 6, new_index: 6, len: 3 }
    ops[0].should be_a(Similar::DiffOp::Equal)
    ops[0].as(Similar::DiffOp::Equal).old_index.should eq(0)
    ops[0].as(Similar::DiffOp::Equal).new_index.should eq(0)
    ops[0].as(Similar::DiffOp::Equal).len.should eq(1)

    ops[1].should be_a(Similar::DiffOp::Replace)
    ops[1].as(Similar::DiffOp::Replace).old_index.should eq(1)
    ops[1].as(Similar::DiffOp::Replace).old_len.should eq(1)
    ops[1].as(Similar::DiffOp::Replace).new_index.should eq(1)
    ops[1].as(Similar::DiffOp::Replace).new_len.should eq(1)

    ops[2].should be_a(Similar::DiffOp::Equal)
    ops[2].as(Similar::DiffOp::Equal).old_index.should eq(2)
    ops[2].as(Similar::DiffOp::Equal).new_index.should eq(2)
    ops[2].as(Similar::DiffOp::Equal).len.should eq(3)

    ops[3].should be_a(Similar::DiffOp::Replace)
    ops[3].as(Similar::DiffOp::Replace).old_index.should eq(5)
    ops[3].as(Similar::DiffOp::Replace).old_len.should eq(1)
    ops[3].as(Similar::DiffOp::Replace).new_index.should eq(5)
    ops[3].as(Similar::DiffOp::Replace).new_len.should eq(1)

    ops[4].should be_a(Similar::DiffOp::Equal)
    ops[4].as(Similar::DiffOp::Equal).old_index.should eq(6)
    ops[4].as(Similar::DiffOp::Equal).new_index.should eq(6)
    ops[4].as(Similar::DiffOp::Equal).len.should eq(3)
  end

  it "test_replace" do
    a = [0, 1, 2, 3, 4]
    b = [0, 1, 2, 7, 8, 9]

    d = Similar::Algorithms::Replace.new(Similar::Algorithms::Capture.new)
    Similar::Algorithms.diff_slices(Similar::Algorithm::Myers, d, a, b)
    ops = d.inner.ops

    ops.size.should eq(2)

    # Expected ops from Rust snapshot:
    # Equal { old_index: 0, new_index: 0, len: 3 }
    # Replace { old_index: 3, old_len: 2, new_index: 3, new_len: 3 }
    ops[0].should be_a(Similar::DiffOp::Equal)
    ops[0].as(Similar::DiffOp::Equal).old_index.should eq(0)
    ops[0].as(Similar::DiffOp::Equal).new_index.should eq(0)
    ops[0].as(Similar::DiffOp::Equal).len.should eq(3)

    ops[1].should be_a(Similar::DiffOp::Replace)
    ops[1].as(Similar::DiffOp::Replace).old_index.should eq(3)
    ops[1].as(Similar::DiffOp::Replace).old_len.should eq(2)
    ops[1].as(Similar::DiffOp::Replace).new_index.should eq(3)
    ops[1].as(Similar::DiffOp::Replace).new_len.should eq(3)
  end
end
