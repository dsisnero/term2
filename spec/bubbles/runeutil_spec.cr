require "../spec_helper"
require "../../src/components/rune_util"

describe Term2::Components::RuneUtil do
  it "sanitizes rune arrays" do
    td = [
      {input: "", output: ""},
      {input: "x", output: "x"},
      {input: "\n", output: "XX"},
      {input: "\na\n", output: "XXaXX"},
      {input: "\n\n", output: "XXXX"},
      {input: "\t", output: ""},
      {input: "hello", output: "hello"},
      {input: "hel\nlo", output: "helXXlo"},
      {input: "hel\rlo", output: "helXXlo"},
      {input: "hel\tlo", output: "hello"},
      {input: "he\n\nl\tlo", output: "heXXXXllo"},
      {input: "he\tl\n\nlo", output: "helXXXXlo"},
      {input: "hel\x1blo", output: "hello"},
    ]

    sanitizer = Term2::Components::RuneUtil.new_sanitizer(
      Term2::Components::RuneUtil.replace_newlines("XX"),
      Term2::Components::RuneUtil.replace_tabs("")
    )

    td.each do |tc|
      result = sanitizer.sanitize(tc[:input].chars)
      result.join.should eq tc[:output]
    end
  end
end
