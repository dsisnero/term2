require "./spec_helper"

describe Similar::Utils::SliceRemapper do
  it "remaps token ranges" do
    source = "foo bar baz"
    tokens = Similar::Text.tokenize_words(source)
    wrapped_source = Similar::StringWrapper.new(source)
    wrapped_tokens = tokens.map { |token| Similar::StringWrapper.new(token) }

    remapper = Similar::Utils::SliceRemapper(Similar::StringWrapper).new(
      wrapped_source,
      wrapped_tokens
    )

    remapper.slice(0...3).try(&.to_s).should eq("foo bar")
    remapper.slice(1...3).try(&.to_s).should eq(" bar")
    remapper.slice(0...1).try(&.to_s).should eq("foo")
    remapper.slice(0...5).try(&.to_s).should eq("foo bar baz")
    remapper.slice(0...6).should be_nil
  end
end

describe Similar::Utils do
  it "diffs slices" do
    old = ["foo", "bar", "baz"]
    new = ["foo", "bar", "BAZ"]
    changes = Similar::Utils.diff_slices(Similar::Algorithm::Myers, old, new)
    changes.should eq([
      {Similar::ChangeTag::Equal, ["foo", "bar"]},
      {Similar::ChangeTag::Delete, ["baz"]},
      {Similar::ChangeTag::Insert, ["BAZ"]},
    ])
  end

  it "diffs words" do
    changes = Similar::Utils.diff_words(Similar::Algorithm::Myers, "foo bar", "foo BAR")
    changes.should eq([
      {Similar::ChangeTag::Equal, "foo"},
      {Similar::ChangeTag::Equal, " "},
      {Similar::ChangeTag::Delete, "bar"},
      {Similar::ChangeTag::Insert, "BAR"},
    ])
  end
end
