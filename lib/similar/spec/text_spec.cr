require "./spec_helper"

describe Similar::Text do
  describe "tokenize_lines" do
    it "splits lines with newlines attached" do
      result = Similar::Text.tokenize_lines("first\nsecond\rthird\r\nfourth\nlast")
      result.should eq(["first\n", "second\r", "third\r\n", "fourth\n", "last"])
    end

    it "handles multiple newlines" do
      result = Similar::Text.tokenize_lines("\n\n")
      result.should eq(["\n", "\n"])
    end

    it "handles single newline" do
      result = Similar::Text.tokenize_lines("\n")
      result.should eq(["\n"])
    end

    it "returns empty array for empty string" do
      result = Similar::Text.tokenize_lines("")
      result.should eq([] of String)
    end
  end

  describe "tokenize_words" do
    it "splits words and whitespace" do
      result = Similar::Text.tokenize_words("foo    bar baz\n\n  aha")
      result.should eq(["foo", "    ", "bar", " ", "baz", "\n\n  ", "aha"])
    end
  end

  describe "tokenize_chars" do
    it "splits into UTF-8 characters" do
      result = Similar::Text.tokenize_chars("abcfö❄️")
      # Note: ❄️ is actually two Unicode codepoints: ❄ (U+2744) and ◌️ (U+FE0F)
      result.should eq(["a", "b", "c", "f", "ö", "❄", "️"])
    end
  end

  describe "ends_with_newline" do
    it "detects newline endings" do
      Similar::Text.ends_with_newline("hello\n").should be_true
      Similar::Text.ends_with_newline("hello\r").should be_true
      Similar::Text.ends_with_newline("hello\r\n").should be_true
      Similar::Text.ends_with_newline("hello").should be_false
    end
  end

  describe "tokenize_unicode_words" do
    it "splits by character categories" do
      result = Similar::Text.tokenize_unicode_words("Hello World!")
      result.should eq(["Hello", " ", "World", "!"])
    end

    it "handles unicode characters" do
      result = Similar::Text.tokenize_unicode_words("abcfö❄️")
      # Letters are all alphanumeric category, snowflake + variation selector are "other" category
      result.should eq(["abcfö", "❄️"])
    end
  end

  describe "tokenize_graphemes" do
    it "splits into grapheme clusters" do
      result = Similar::Text.tokenize_graphemes("abcfö❄️")
      result.should eq(["a", "b", "c", "f", "ö", "❄️"])
    end

    it "combines base characters with combining marks" do
      # c with cedilla (U+0327) - should be one grapheme
      result = Similar::Text.tokenize_graphemes("c\u{0327}")
      result.should eq(["c\u{0327}"])
    end
  end
end

describe Similar::TextDiff do
  it "creates line diff" do
    diff = Similar::TextDiff.from_lines("a\nb\nc", "a\nb\nC")
    changes = diff.iter_all_changes.to_a

    changes.size.should eq(4)
    changes[0].tag.should eq(Similar::ChangeTag::Equal)
    changes[0].value.should eq("a\n")
    changes[1].tag.should eq(Similar::ChangeTag::Equal)
    changes[1].value.should eq("b\n")
    changes[2].tag.should eq(Similar::ChangeTag::Delete)
    changes[2].value.should eq("c")
    changes[3].tag.should eq(Similar::ChangeTag::Insert)
    changes[3].value.should eq("C")
  end

  it "creates word diff" do
    diff = Similar::TextDiff.from_words("foo bar baz", "foo BAR baz")
    changes = diff.iter_all_changes.to_a

    changes.size.should eq(6)
    changes[0].tag.should eq(Similar::ChangeTag::Equal)
    changes[0].value.should eq("foo")
    changes[1].tag.should eq(Similar::ChangeTag::Equal)
    changes[1].value.should eq(" ")
    changes[2].tag.should eq(Similar::ChangeTag::Delete)
    changes[2].value.should eq("bar")
    changes[3].tag.should eq(Similar::ChangeTag::Insert)
    changes[3].value.should eq("BAR")
    changes[4].tag.should eq(Similar::ChangeTag::Equal)
    changes[4].value.should eq(" ")
    changes[5].tag.should eq(Similar::ChangeTag::Equal)
    changes[5].value.should eq("baz")
  end

  it "creates char diff" do
    diff = Similar::TextDiff.from_chars("abcdef", "abcDDf")
    changes = diff.iter_all_changes.to_a

    # Should have: a, b, c equal, d delete, e delete, D insert, D insert, f equal
    changes.size.should eq(8)
  end

  it "calculates ratio" do
    diff = Similar::TextDiff.from_chars("abcd", "bcde")
    diff.ratio.should be_close(0.75, 0.01)
  end

  it "works with empty strings" do
    diff = Similar::TextDiff.from_lines("", "")
    diff.ops.size.should eq(0)
    diff.iter_all_changes.to_a.size.should eq(0)
  end

  it "can use different algorithms" do
    diff = Similar::TextDiff.configure.algorithm(Similar::Algorithm::Patience).diff_lines("a\nb\nc", "a\nb\nC")
    diff.algorithm.should eq(Similar::Algorithm::Patience)
  end

  it "supports from_slices" do
    old = ["foo", "bar", "baz"]
    new = ["foo", "BAR", "baz"]
    diff = Similar::TextDiff.from_slices(old, new)
    changes = diff.iter_all_changes.to_a

    changes.size.should eq(4)
    changes[0].tag.should eq(Similar::ChangeTag::Equal)
    changes[0].value.should eq("foo")
    changes[1].tag.should eq(Similar::ChangeTag::Delete)
    changes[1].value.should eq("bar")
    changes[2].tag.should eq(Similar::ChangeTag::Insert)
    changes[2].value.should eq("BAR")
    changes[3].tag.should eq(Similar::ChangeTag::Equal)
    changes[3].value.should eq("baz")
  end

  it "supports generic slices with StringWrapper" do
    old = [Similar::StringWrapper.new("foo"), Similar::StringWrapper.new("bar")]
    new = [Similar::StringWrapper.new("foo"), Similar::StringWrapper.new("baz")]
    diff = Similar::TextDiff.from_slices(old, new)
    changes = diff.iter_all_changes.to_a

    changes.size.should eq(3)
    changes[0].tag.should eq(Similar::ChangeTag::Equal)
    changes[0].value.to_s.should eq("foo")
    changes[1].tag.should eq(Similar::ChangeTag::Delete)
    changes[1].value.to_s.should eq("bar")
    changes[2].tag.should eq(Similar::ChangeTag::Insert)
    changes[2].value.to_s.should eq("baz")
  end

  it "test_captured_ops" do
    diff = Similar::TextDiff.from_lines(
      "Hello World\nsome stuff here\nsome more stuff here\n",
      "Hello World\nsome amazing stuff here\nsome more stuff here\n"
    )

    ops = diff.ops
    # Based on Rust snapshot (similar__text__captured_ops.snap)
    ops.size.should eq(3)

    # First op: Equal { old_index: 0, new_index: 0, len: 1 }
    ops[0].should be_a(Similar::DiffOp::Equal)
    equal1 = ops[0].as(Similar::DiffOp::Equal)
    equal1.old_index.should eq(0)
    equal1.new_index.should eq(0)
    equal1.len.should eq(1)

    # Second op: Replace { old_index: 1, old_len: 1, new_index: 1, new_len: 1 }
    ops[1].should be_a(Similar::DiffOp::Replace)
    replace = ops[1].as(Similar::DiffOp::Replace)
    replace.old_index.should eq(1)
    replace.old_len.should eq(1)
    replace.new_index.should eq(1)
    replace.new_len.should eq(1)

    # Third op: Equal { old_index: 2, new_index: 2, len: 1 }
    ops[2].should be_a(Similar::DiffOp::Equal)
    equal2 = ops[2].as(Similar::DiffOp::Equal)
    equal2.old_index.should eq(2)
    equal2.new_index.should eq(2)
    equal2.len.should eq(1)
  end

  it "test_captured_word_ops" do
    diff = Similar::TextDiff.from_words(
      "Hello World\nsome stuff here\nsome more stuff here\n",
      "Hello World\nsome amazing stuff here\nsome more stuff here\n"
    )

    # Get all changes by iterating through ops
    changes = [] of Similar::Change(String)
    diff.ops.each do |op|
      diff.iter_changes(op).each do |change|
        changes << change
      end
    end

    # Based on Rust snapshot, we expect 20 changes
    changes.size.should eq(20)

    # Expected values from Rust snapshot (similar__text__captured_word_ops.snap)
    expected_tags = [
      Similar::ChangeTag::Equal,
      Similar::ChangeTag::Equal,
      Similar::ChangeTag::Equal,
      Similar::ChangeTag::Equal,
      Similar::ChangeTag::Equal,
      Similar::ChangeTag::Equal,
      Similar::ChangeTag::Insert,
      Similar::ChangeTag::Insert,
      Similar::ChangeTag::Equal,
      Similar::ChangeTag::Equal,
      Similar::ChangeTag::Equal,
      Similar::ChangeTag::Equal,
      Similar::ChangeTag::Equal,
      Similar::ChangeTag::Equal,
      Similar::ChangeTag::Equal,
      Similar::ChangeTag::Equal,
      Similar::ChangeTag::Equal,
      Similar::ChangeTag::Equal,
      Similar::ChangeTag::Equal,
      Similar::ChangeTag::Equal,
    ]

    expected_values = [
      "Hello",
      " ",
      "World",
      "\n",
      "some",
      " ",
      "amazing",
      " ",
      "stuff",
      " ",
      "here",
      "\n",
      "some",
      " ",
      "more",
      " ",
      "stuff",
      " ",
      "here",
      "\n",
    ]

    # Expected old and new indices from Rust snapshot
    expected_old_indices = [
      0, 1, 2, 3, 4, 5, nil, nil, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
    ]

    expected_new_indices = [
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
    ]

    changes.each_with_index do |change, i|
      change.tag.should eq(expected_tags[i])
      change.value.should eq(expected_values[i])
      change.old_index.should eq(expected_old_indices[i])
      change.new_index.should eq(expected_new_indices[i])
    end
  end

  it "test_virtual_newlines" do
    diff = Similar::TextDiff.from_lines("a\nb", "a\nc\n")

    # Newline terminated should be true for line diffs
    diff.newline_terminated.should be_true

    changes = diff.iter_all_changes.to_a

    # Based on Rust snapshot (similar__text__virtual_newlines.snap)
    changes.size.should eq(3)

    changes[0].tag.should eq(Similar::ChangeTag::Equal)
    changes[0].value.should eq("a\n")
    changes[0].old_index.should eq(0)
    changes[0].new_index.should eq(0)

    changes[1].tag.should eq(Similar::ChangeTag::Delete)
    changes[1].value.should eq("b")
    changes[1].old_index.should eq(1)
    changes[1].new_index.should be_nil

    changes[2].tag.should eq(Similar::ChangeTag::Insert)
    changes[2].value.should eq("c\n")
    changes[2].old_index.should be_nil
    changes[2].new_index.should eq(1)
  end

  it "test_line_ops" do
    a = "Hello World\nsome stuff here\nsome more stuff here\n"
    b = "Hello World\nsome amazing stuff here\nsome more stuff here\n"
    diff = Similar::TextDiff.from_lines(a, b)

    diff.newline_terminated.should be_true

    changes = diff.iter_all_changes.to_a

    # Based on Rust snapshot (similar__text__line_ops.snap)
    changes.size.should eq(4)

    changes[0].tag.should eq(Similar::ChangeTag::Equal)
    changes[0].value.should eq("Hello World\n")
    changes[0].old_index.should eq(0)
    changes[0].new_index.should eq(0)

    changes[1].tag.should eq(Similar::ChangeTag::Delete)
    changes[1].value.should eq("some stuff here\n")
    changes[1].old_index.should eq(1)
    changes[1].new_index.should be_nil

    changes[2].tag.should eq(Similar::ChangeTag::Insert)
    changes[2].value.should eq("some amazing stuff here\n")
    changes[2].old_index.should be_nil
    changes[2].new_index.should eq(1)

    changes[3].tag.should eq(Similar::ChangeTag::Equal)
    changes[3].value.should eq("some more stuff here\n")
    changes[3].old_index.should eq(2)
    changes[3].new_index.should eq(2)
  end

  # Add other newline termination tests here

  it "test_line_ops_inline" do
    diff = Similar::TextDiff.from_lines(
      "Hello World\nsome stuff here\nsome more stuff here\n\nAha stuff here\nand more stuff",
      "Stuff\nHello World\nsome amazing stuff here\nsome more stuff here\n"
    )
    diff.newline_terminated.should be_true

    changes = [] of Similar::InlineChange
    diff.ops.each do |op|
      changes.concat(diff.iter_inline_changes(op))
    end

    # Based on Rust snapshot (similar__text__inline__line_ops_inline.snap)
    changes.size.should eq(8)

    # First change: Insert "Stuff\n"
    changes[0].tag.should eq(Similar::ChangeTag::Insert)
    changes[0].old_index.should be_nil
    changes[0].new_index.should eq(0)
    changes[0].values.should eq([{false, "Stuff\n"}])

    # Second change: Equal "Hello World\n"
    changes[1].tag.should eq(Similar::ChangeTag::Equal)
    changes[1].old_index.should eq(0)
    changes[1].new_index.should eq(1)
    changes[1].values.should eq([{false, "Hello World\n"}])

    # Third change: Delete "some stuff here\n" (split into two parts)
    changes[2].tag.should eq(Similar::ChangeTag::Delete)
    changes[2].old_index.should eq(1)
    changes[2].new_index.should be_nil
    changes[2].values.should eq([{false, "some "}, {false, "stuff here\n"}])

    # Fourth change: Insert "some amazing stuff here\n" with "amazing " emphasized
    changes[3].tag.should eq(Similar::ChangeTag::Insert)
    changes[3].old_index.should be_nil
    changes[3].new_index.should eq(2)
    changes[3].values.should eq([{false, "some "}, {true, "amazing "}, {false, "stuff here\n"}])

    # Fifth change: Equal "some more stuff here\n"
    changes[4].tag.should eq(Similar::ChangeTag::Equal)
    changes[4].old_index.should eq(2)
    changes[4].new_index.should eq(3)
    changes[4].values.should eq([{false, "some more stuff here\n"}])

    # Sixth change: Delete "\n"
    changes[5].tag.should eq(Similar::ChangeTag::Delete)
    changes[5].old_index.should eq(3)
    changes[5].new_index.should be_nil
    changes[5].values.should eq([{false, "\n"}])

    # Seventh change: Delete "Aha stuff here\n"
    changes[6].tag.should eq(Similar::ChangeTag::Delete)
    changes[6].old_index.should eq(4)
    changes[6].new_index.should be_nil
    changes[6].values.should eq([{false, "Aha stuff here\n"}])

    # Eighth change: Delete "and more stuff"
    changes[7].tag.should eq(Similar::ChangeTag::Delete)
    changes[7].old_index.should eq(5)
    changes[7].new_index.should be_nil
    changes[7].values.should eq([{false, "and more stuff"}])
  end

  describe "get_close_matches" do
    it "finds close matches" do
      matches = Similar.get_close_matches("appel", ["ape", "apple", "peach", "puppy"], 3, 0.6)
      matches.should eq(["apple", "ape"])
    end

    it "respects cutoff and n parameters" do
      matches = Similar.get_close_matches(
        "hulo",
        ["hi", "hulu", "hali", "hoho", "amaz", "zulo", "blah", "hopp", "uulo", "aulo"],
        5,
        0.7
      )
      matches.should eq(["aulo", "hulu", "uulo", "zulo"])
    end

    it "returns empty array when n <= 0" do
      matches = Similar.get_close_matches("test", ["test"], 0, 0.5)
      matches.should eq([] of String)
    end

    it "returns empty array when no possibilities" do
      matches = Similar.get_close_matches("test", [] of String, 3, 0.5)
      matches.should eq([] of String)
    end
  end
end
