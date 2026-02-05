require "./spec_helper"

describe Similar do
  it "test_non_string_iter_change" do
    old = [1, 2, 3]
    new = [1, 2, 4]

    # Use low-level algorithm with Capture hook (generic)
    d = Similar::Algorithms::Replace.new(Similar::Algorithms::Capture.new)
    Similar::Algorithms.diff_slices(Similar::Algorithm::Myers, d, old, new)
    ops = d.inner.ops

    # Iterate through ops to get changes
    changes = [] of Similar::Change(Int32)
    ops.each do |op|
      op.iter_changes(old, new).each do |change|
        changes << change
      end
    end

    changes.size.should eq(4)
    changes[0].tag.should eq(Similar::ChangeTag::Equal)
    changes[0].value.should eq(1)
    changes[1].tag.should eq(Similar::ChangeTag::Equal)
    changes[1].value.should eq(2)
    changes[2].tag.should eq(Similar::ChangeTag::Delete)
    changes[2].value.should eq(3)
    changes[3].tag.should eq(Similar::ChangeTag::Insert)
    changes[3].value.should eq(4)
  end
end
