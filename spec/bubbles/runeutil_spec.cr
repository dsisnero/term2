require "../spec_helper"
require "../../src/components/rune_util"

describe Term2::Components::RuneUtil do
  it "sanitizes rune arrays" do
    td = [
      {input: "", output: ""},
      {input: "x", output: "x"},
      {input: "\n", output: " "},
      {input: "\na\n", output: " a "},
      {input: "\n\n", output: "  "},
      {input: "\t", output: "    "},
      {input: "hello", output: "hello"},
      {input: "hel\nlo", output: "hel lo"},
      {input: "hel\rlo", output: "hel lo"},
      {input: "hel\tlo", output: "hel    lo"},
      {input: "he\n\nl\tlo", output: "he  l    lo"},
      {input: "he\tl\n\nlo", output: "he    l  lo"},
      {input: "hel\x1blo", output: "hello"},
    ]

    td.each do |tc|
      result = Term2::Components::RuneUtil.sanitize(tc[:input])
      result.should eq tc[:output]
    end
  end
end
