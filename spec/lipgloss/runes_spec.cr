require "../spec_helper"

describe "Lipgloss parity: StyleRunes" do
  it "styles selected rune indices" do
    matched = Term2::Style.new.reverse(true)
    unmatched = Term2::Style.new

    cases = [
      {name: "hello 0", input: "hello", indices: [0], expected: "\e[7mh\e[0mello"},
      {name: "你好 1", input: "你好", indices: [1], expected: "你\e[7m好\e[0m"},
      {name: "hello 你好 6,7", input: "hello 你好", indices: [6, 7], expected: "hello \e[7m你好\e[0m"},
      {name: "hello 1,3", input: "hello", indices: [1, 3], expected: "h\e[7me\e[0ml\e[7ml\e[0mo"},
      {name: "你好 0,1", input: "你好", indices: [0, 1], expected: "\e[7m你好\e[0m"},
    ]

    cases.each do |c|
      Term2.style_runes(c[:input], c[:indices], matched, unmatched).should eq(c[:expected]), c[:name]
    end
  end
end