require "../spec_helper"

describe "Lipgloss parity: StyleRanges" do
  it "applies style ranges" do
    prev_profile = Term2::StyleRenderer.default.color_profile
    Term2::StyleRenderer.default.color_profile = Term2::ColorProfile::ANSI

    tests = [
      {name: "empty ranges", input: "hello world", ranges: [] of Term2::Range, expected: "hello world"},
      {name: "single range in middle", input: "hello world", ranges: [Term2::Range.new(6, 11, Term2::Style.new.bold(true))], expected: "hello \e[1mworld\e[0m"},
      {name: "multiple ranges", input: "hello world", ranges: [Term2::Range.new(0, 5, Term2::Style.new.bold(true)), Term2::Range.new(6, 11, Term2::Style.new.italic(true))], expected: "\e[1mhello\e[0m \e[3mworld\e[0m"},
      {name: "overlapping with ansi", input: "hello \e[32mworld\e[0m", ranges: [Term2::Range.new(0, 5, Term2::Style.new.bold(true))], expected: "\e[1mhello\e[0m \e[32mworld\e[0m"},
      {name: "style at start", input: "hello world", ranges: [Term2::Range.new(0, 5, Term2::Style.new.bold(true))], expected: "\e[1mhello\e[0m world"},
      {name: "style at end", input: "hello world", ranges: [Term2::Range.new(6, 11, Term2::Style.new.bold(true))], expected: "hello \e[1mworld\e[0m"},
      {name: "multiple styles with gap", input: "hello beautiful world", ranges: [Term2::Range.new(0, 5, Term2::Style.new.bold(true)), Term2::Range.new(16, 23, Term2::Style.new.italic(true))], expected: "\e[1mhello\e[0m beautiful \e[3mworld\e[0m"},
      {name: "adjacent ranges", input: "hello world", ranges: [Term2::Range.new(0, 5, Term2::Style.new.bold(true)), Term2::Range.new(6, 11, Term2::Style.new.italic(true))], expected: "\e[1mhello\e[0m \e[3mworld\e[0m"},
      {name: "wide-width characters", input: "Hello 你好 世界", ranges: [Term2::Range.new(0, 5, Term2::Style.new.bold(true)), Term2::Range.new(7, 10, Term2::Style.new.italic(true)), Term2::Range.new(11, 50, Term2::Style.new.bold(true))], expected: "\e[1mHello\e[0m \e[3m你好\e[0m \e[1m世界\e[0m"},
      {name: "ansi and emoji", input: "\e[90m\ue615\e[39m \e[3mDownloads", ranges: [Term2::Range.new(2, 5, Term2::Style.new.foreground(Term2::Color.indexed(2)))], expected: "\e[90m\ue615\e[39m \e[3m\e[32mDow\e[0m\e[90m\e[39m\e[3mnloads"},
    ]

    tests.each do |t|
      Term2.style_ranges(t[:input], t[:ranges]).should eq(t[:expected]), t[:name]
    end

    Term2::StyleRenderer.default.color_profile = prev_profile
  end
end