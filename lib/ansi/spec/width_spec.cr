require "./spec_helper"

WIDTH_CASES = [
  {name: "empty", input: "", stripped: "", width: 0, wcwidth: 0},
  {name: "ascii", input: "hello", stripped: "hello", width: 5, wcwidth: 5},
  {name: "emoji", input: "👋", stripped: "👋", width: 2, wcwidth: 2},
  {name: "wideemoji", input: "🫧", stripped: "🫧", width: 2, wcwidth: 2},
  {name: "combining", input: "a\u0300", stripped: "à", width: 1, wcwidth: 1},
  {name: "control", input: "\x1b[31mhello\x1b[0m", stripped: "hello", width: 5, wcwidth: 5},
  {name: "csi8", input: "\x9b38;5;1mhello\x9bm", stripped: "hello", width: 5, wcwidth: 5},
  {name: "osc", input: "\x9d2;charmbracelet: ~/Source/bubbletea\x9c", stripped: "", width: 0, wcwidth: 0},
  {name: "controlemoji", input: "\x1b[31m👋\x1b[0m", stripped: "👋", width: 2, wcwidth: 2},
  {name: "oscwideemoji", input: "\x1b]2;title👨‍👩‍👦\x07", stripped: "", width: 0, wcwidth: 0},
  {name: "oscwideemoji", input: "\x1b[31m👨‍👩‍👦\x1b[m", stripped: "👨\u200d👩\u200d👦", width: 2, wcwidth: 2},
  {name: "multiemojicsi", input: "👨‍👩‍👦\x9b38;5;1mhello\x9bm", stripped: "👨‍👩‍👦hello", width: 7, wcwidth: 7},
  {name: "osc8eastasianlink", input: "\x9d8;id=1;https://example.com/\x9c打豆豆\x9d8;id=1;\x07", stripped: "打豆豆", width: 6, wcwidth: 6},
  {name: "dcsarabic", input: "\x1bP?123$pسلام\x1b\\اهلا", stripped: "اهلا", width: 4, wcwidth: 4},
  {name: "newline", input: "hello\nworld", stripped: "hello\nworld", width: 10, wcwidth: 10},
  {name: "tab", input: "hello\tworld", stripped: "hello\tworld", width: 10, wcwidth: 10},
  {name: "controlnewline", input: "\x1b[31mhello\x1b[0m\nworld", stripped: "hello\nworld", width: 10, wcwidth: 10},
  {name: "style", input: "\x1b[38;2;249;38;114mfoo", stripped: "foo", width: 3, wcwidth: 3},
  {name: "unicode", input: "\x1b[35m“box”\x1b[0m", stripped: "“box”", width: 5, wcwidth: 5},
  {name: "just_unicode", input: "Claire’s Boutique", stripped: "Claire’s Boutique", width: 17, wcwidth: 17},
  {name: "unclosed_ansi", input: "Hey, \x1b[7m\n猴", stripped: "Hey, \n猴", width: 7, wcwidth: 7},
  {name: "double_asian_runes", input: " 你\x1b[8m好.", stripped: " 你好.", width: 6, wcwidth: 6},
  {name: "flag", input: "🇸🇦", stripped: "🇸🇦", width: 2, wcwidth: 1},
]

describe "Ansi width helpers" do
  it "strips ANSI sequences" do
    WIDTH_CASES.each do |test_case|
      Ansi.strip(test_case[:input]).should eq test_case[:stripped]
    end
  end

  it "calculates string width" do
    WIDTH_CASES.each do |test_case|
      Ansi.string_width(test_case[:input]).should eq test_case[:width]
    end
  end

  it "calculates wc string width" do
    WIDTH_CASES.each do |test_case|
      Ansi.string_width_wc(test_case[:input]).should eq test_case[:wcwidth]
    end
  end
end
