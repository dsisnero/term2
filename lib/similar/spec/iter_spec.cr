require "./spec_helper"

describe Similar do
  describe "ChangesIter" do
    it "iterates over equal operations" do
      old = [1, 2, 3]
      new = [1, 2, 3]
      op = Similar::DiffOp::Equal.new(0, 0, 3)
      iter = Similar::ChangesIter(typeof(old), typeof(new), Int32).new(old, new, op)

      changes = iter.to_a
      changes.size.should eq(3)
      changes[0].tag.should eq(Similar::ChangeTag::Equal)
      changes[0].value.should eq(1)
      changes[0].old_index.should eq(0)
      changes[0].new_index.should eq(0)
      changes[1].value.should eq(2)
      changes[2].value.should eq(3)
    end

    it "iterates over delete operations" do
      old = [1, 2, 3]
      new = [] of Int32
      op = Similar::DiffOp::Delete.new(0, 3, 0)
      iter = Similar::ChangesIter(typeof(old), typeof(new), Int32).new(old, new, op)

      changes = iter.to_a
      changes.size.should eq(3)
      changes[0].tag.should eq(Similar::ChangeTag::Delete)
      changes[0].value.should eq(1)
      changes[0].old_index.should eq(0)
      changes[0].new_index.should be_nil
      changes[1].value.should eq(2)
      changes[2].value.should eq(3)
    end

    it "iterates over insert operations" do
      old = [] of Int32
      new = [1, 2, 3]
      op = Similar::DiffOp::Insert.new(0, 0, 3)
      iter = Similar::ChangesIter(typeof(old), typeof(new), Int32).new(old, new, op)

      changes = iter.to_a
      changes.size.should eq(3)
      changes[0].tag.should eq(Similar::ChangeTag::Insert)
      changes[0].value.should eq(1)
      changes[0].old_index.should be_nil
      changes[0].new_index.should eq(0)
      changes[1].value.should eq(2)
      changes[2].value.should eq(3)
    end

    it "iterates over replace operations" do
      old = [1, 2, 3]
      new = [4, 5]
      op = Similar::DiffOp::Replace.new(0, 3, 0, 2)
      iter = Similar::ChangesIter(typeof(old), typeof(new), Int32).new(old, new, op)

      changes = iter.to_a
      # Replace yields deletes first, then inserts
      changes.size.should eq(5) # 3 deletes + 2 inserts
      changes[0].tag.should eq(Similar::ChangeTag::Delete)
      changes[0].value.should eq(1)
      changes[1].tag.should eq(Similar::ChangeTag::Delete)
      changes[1].value.should eq(2)
      changes[2].tag.should eq(Similar::ChangeTag::Delete)
      changes[2].value.should eq(3)
      changes[3].tag.should eq(Similar::ChangeTag::Insert)
      changes[3].value.should eq(4)
      changes[4].tag.should eq(Similar::ChangeTag::Insert)
      changes[4].value.should eq(5)
    end
  end

  describe "AllChangesIter" do
    it "iterates over multiple operations" do
      old = [1, 2, 3, 4, 5]
      new = [1, 2, 6, 7, 5]
      # Simulate ops: Equal(2), Replace(2,2), Equal(1)
      ops = [
        Similar::DiffOp::Equal.new(0, 0, 2),
        Similar::DiffOp::Replace.new(2, 2, 2, 2),
        Similar::DiffOp::Equal.new(4, 4, 1),
      ]
      iter = Similar::AllChangesIter(typeof(old), typeof(new), Int32).new(old, new, ops)

      changes = iter.to_a
      changes.size.should eq(7) # 2 equal + 2 delete + 2 insert + 1 equal
      tags = changes.map(&.tag)
      tags.should eq([
        Similar::ChangeTag::Equal,
        Similar::ChangeTag::Equal,
        Similar::ChangeTag::Delete,
        Similar::ChangeTag::Delete,
        Similar::ChangeTag::Insert,
        Similar::ChangeTag::Insert,
        Similar::ChangeTag::Equal,
      ])
      values = changes.map(&.value)
      values.should eq([1, 2, 3, 4, 6, 7, 5])
    end

    it "handles empty ops" do
      old = [] of Int32
      new = [] of Int32
      ops = [] of Similar::DiffOp
      iter = Similar::AllChangesIter(typeof(old), typeof(new), Int32).new(old, new, ops)

      changes = iter.to_a
      changes.should be_empty
    end
  end

  describe "DiffOp.iter_changes" do
    it "returns iterator for changes" do
      old = [1, 2, 3]
      new = [1, 2, 4]
      op = Similar::DiffOp::Replace.new(0, 3, 0, 3)

      changes = op.iter_changes(old, new).to_a
      changes.size.should eq(6) # 3 deletes + 3 inserts
      changes[0].tag.should eq(Similar::ChangeTag::Delete)
      changes[0].value.should eq(1)
      changes[3].tag.should eq(Similar::ChangeTag::Insert)
      changes[3].value.should eq(1)
    end
  end
end
