require "../spec_helper"

describe Similar::Algorithms::Capture do
  it "test_capture_hook_grouping" do
    rng = (1..100).to_a
    rng_new = rng.dup
    rng_new[10] = 1000
    rng_new[13] = 1000
    rng_new[16] = 1000
    rng_new[34] = 1000

    d = Similar::Algorithms::Replace.new(Similar::Algorithms::Capture.new)
    Similar::Algorithms.diff_slices(Similar::Algorithm::Myers, d, rng, rng_new)

    ops = d.inner.grouped_ops(3)
    tags = ops.map do |group|
      group.map(&.as_tag_tuple)
    end

    # Verify structure matches Rust snapshot expectations
    # With 4 changes at indices 10, 13, 16, 34 and context radius 3:
    # - Changes at 10, 13, 16 are close (within context) -> 1 cluster
    # - Change at 34 is separate -> 2nd cluster
    ops.size.should eq(2)

    # First cluster should have 7 ops
    ops[0].size.should eq(7)

    # Verify first cluster ops match expected pattern
    ops[0][0].should be_a(Similar::DiffOp::Equal)
    ops[0][0].as(Similar::DiffOp::Equal).old_index.should eq(7)
    ops[0][0].as(Similar::DiffOp::Equal).new_index.should eq(7)
    ops[0][0].as(Similar::DiffOp::Equal).len.should eq(3)

    ops[0][1].should be_a(Similar::DiffOp::Replace)
    ops[0][1].as(Similar::DiffOp::Replace).old_index.should eq(10)
    ops[0][1].as(Similar::DiffOp::Replace).old_len.should eq(1)
    ops[0][1].as(Similar::DiffOp::Replace).new_index.should eq(10)
    ops[0][1].as(Similar::DiffOp::Replace).new_len.should eq(1)

    ops[0][2].should be_a(Similar::DiffOp::Equal)
    ops[0][2].as(Similar::DiffOp::Equal).old_index.should eq(11)
    ops[0][2].as(Similar::DiffOp::Equal).new_index.should eq(11)
    ops[0][2].as(Similar::DiffOp::Equal).len.should eq(2)

    ops[0][3].should be_a(Similar::DiffOp::Replace)
    ops[0][3].as(Similar::DiffOp::Replace).old_index.should eq(13)
    ops[0][3].as(Similar::DiffOp::Replace).old_len.should eq(1)
    ops[0][3].as(Similar::DiffOp::Replace).new_index.should eq(13)
    ops[0][3].as(Similar::DiffOp::Replace).new_len.should eq(1)

    ops[0][4].should be_a(Similar::DiffOp::Equal)
    ops[0][4].as(Similar::DiffOp::Equal).old_index.should eq(14)
    ops[0][4].as(Similar::DiffOp::Equal).new_index.should eq(14)
    ops[0][4].as(Similar::DiffOp::Equal).len.should eq(2)

    ops[0][5].should be_a(Similar::DiffOp::Replace)
    ops[0][5].as(Similar::DiffOp::Replace).old_index.should eq(16)
    ops[0][5].as(Similar::DiffOp::Replace).old_len.should eq(1)
    ops[0][5].as(Similar::DiffOp::Replace).new_index.should eq(16)
    ops[0][5].as(Similar::DiffOp::Replace).new_len.should eq(1)

    ops[0][6].should be_a(Similar::DiffOp::Equal)
    ops[0][6].as(Similar::DiffOp::Equal).old_index.should eq(17)
    ops[0][6].as(Similar::DiffOp::Equal).new_index.should eq(17)
    ops[0][6].as(Similar::DiffOp::Equal).len.should eq(3)

    # Second cluster should have 3 ops
    ops[1].size.should eq(3)

    ops[1][0].should be_a(Similar::DiffOp::Equal)
    ops[1][0].as(Similar::DiffOp::Equal).old_index.should eq(31)
    ops[1][0].as(Similar::DiffOp::Equal).new_index.should eq(31)
    ops[1][0].as(Similar::DiffOp::Equal).len.should eq(3)

    ops[1][1].should be_a(Similar::DiffOp::Replace)
    ops[1][1].as(Similar::DiffOp::Replace).old_index.should eq(34)
    ops[1][1].as(Similar::DiffOp::Replace).old_len.should eq(1)
    ops[1][1].as(Similar::DiffOp::Replace).new_index.should eq(34)
    ops[1][1].as(Similar::DiffOp::Replace).new_len.should eq(1)

    ops[1][2].should be_a(Similar::DiffOp::Equal)
    ops[1][2].as(Similar::DiffOp::Equal).old_index.should eq(35)
    ops[1][2].as(Similar::DiffOp::Equal).new_index.should eq(35)
    ops[1][2].as(Similar::DiffOp::Equal).len.should eq(3)

    # Total ops should be 10 (7 + 3)
    ops.sum(&.size).should eq(10)

    # Verify tags structure
    tags.size.should eq(2)
    tags[0].size.should eq(7)
    tags[1].size.should eq(3)

    # Verify tag types
    tags[0][0][0].should eq(Similar::DiffTag::Equal)
    tags[0][1][0].should eq(Similar::DiffTag::Replace)
    tags[0][2][0].should eq(Similar::DiffTag::Equal)
    tags[0][3][0].should eq(Similar::DiffTag::Replace)
    tags[0][4][0].should eq(Similar::DiffTag::Equal)
    tags[0][5][0].should eq(Similar::DiffTag::Replace)
    tags[0][6][0].should eq(Similar::DiffTag::Equal)

    tags[1][0][0].should eq(Similar::DiffTag::Equal)
    tags[1][1][0].should eq(Similar::DiffTag::Replace)
    tags[1][2][0].should eq(Similar::DiffTag::Equal)
  end
end
