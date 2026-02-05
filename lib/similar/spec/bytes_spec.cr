require "./spec_helper"

describe Similar::Text do
  describe "tokenize_lines (bytes)" do
    it "splits bytes into line slices" do
      bytes = Bytes[0x61, 0x0A, 0x62, 0x0D, 0x63, 0x0D, 0x0A, 0x64]
      result = Similar::Text.tokenize_lines(bytes)
      result.map(&.to_s).should eq(["a\n", "b\r", "c\r\n", "d"])
    end
  end

  describe "tokenize_words (bytes)" do
    it "splits bytes into words and whitespace" do
      bytes = Bytes[0x66, 0x6F, 0x6F, 0x20, 0x20, 0x62, 0x61, 0x72]
      result = Similar::Text.tokenize_words(bytes)
      result.map(&.to_s).should eq(["foo", "  ", "bar"])
    end
  end

  describe "tokenize_chars (bytes)" do
    it "splits bytes into single-byte tokens" do
      bytes = Bytes[0x61, 0x62, 0x63]
      result = Similar::Text.tokenize_chars(bytes)
      result.map(&.to_s).should eq(["a", "b", "c"])
    end
  end
end

describe Similar::TextDiff do
  it "creates byte diffs" do
    old_bytes = Bytes[0x61, 0x62, 0x63]
    new_bytes = Bytes[0x61, 0x62, 0x64]
    diff = Similar::TextDiff.from_chars(old_bytes, new_bytes)
    changes = diff.iter_all_changes.to_a

    changes.size.should eq(4)
    changes[0].tag.should eq(Similar::ChangeTag::Equal)
    changes[0].value.to_s.should eq("a")
    changes[1].tag.should eq(Similar::ChangeTag::Equal)
    changes[1].value.to_s.should eq("b")
    changes[2].tag.should eq(Similar::ChangeTag::Delete)
    changes[2].value.to_s.should eq("c")
    changes[3].tag.should eq(Similar::ChangeTag::Insert)
    changes[3].value.to_s.should eq("d")
  end
end
