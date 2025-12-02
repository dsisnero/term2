require "../spec_helper"

record ScanTestCase,
  name : String,
  input : String,
  want : String,
  ids : Array(String)

style = ->(s : String) { "\e[31m#{s}\e[0m" }

def build_tests(style)
  [
    ScanTestCase.new("empty", "", "", [] of String),
    ScanTestCase.new("single", "a", "a", [] of String),
    ScanTestCase.new("double", "aa", "aa", [] of String),
    ScanTestCase.new("triple", "aaa", "aaa", [] of String),
    ScanTestCase.new("quad", "aaaa", "aaaa", [] of String),
    ScanTestCase.new("lipgloss-empty", style.call(""), style.call(""), [] of String),
    ScanTestCase.new("lipgloss-basic", style.call("testing"), style.call("testing"), [] of String),
    ScanTestCase.new("lipgloss-basic-start", "a" + style.call("testing"), "a" + style.call("testing"), [] of String),
    ScanTestCase.new("lipgloss-basic-end", style.call("testing") + "a", style.call("testing") + "a", [] of String),
    ScanTestCase.new("lipgloss-basic-start-end", "a" + style.call("testing") + "a", "a" + style.call("testing") + "a", [] of String),
    ScanTestCase.new("lipgloss-basic-between", style.call("testing") + "a" + style.call("testing"), style.call("testing") + "a" + style.call("testing"), [] of String),
    ScanTestCase.new("id-empty", Term2::Zone.mark("testing1", ""), "", [] of String),
    ScanTestCase.new("id-single-start", "a" + Term2::Zone.mark("testing2", "a"), "aa", ["testing2"]),
    ScanTestCase.new("id-single-end", Term2::Zone.mark("testing3", "a") + "a", "aa", ["testing3"]),
    ScanTestCase.new("id-single-start-end", "a" + Term2::Zone.mark("testing4", "b") + "a", "aba", ["testing4"]),
    ScanTestCase.new("id-single-between", Term2::Zone.mark("testing5", "b") + "a" + Term2::Zone.mark("testing6", "b"), "bab", ["testing5", "testing6"]),
    ScanTestCase.new("id-with-lipgloss-start", style.call(Term2::Zone.mark("testing7", "testing") + "testing"), style.call("testingtesting"), ["testing7"]),
    ScanTestCase.new("id-with-lipgloss-end", style.call("testing" + Term2::Zone.mark("testing8", "testing")), style.call("testingtesting"), ["testing8"]),
    ScanTestCase.new("id-multi-empty", Term2::Zone.mark("foo1", "") + Term2::Zone.mark("bar1", ""), "", [] of String),
    ScanTestCase.new("id-multi-start", "a" + Term2::Zone.mark("foo2", "b") + Term2::Zone.mark("bar2", "c"), "abc", ["foo2", "bar2"]),
    ScanTestCase.new("id-multi-end", Term2::Zone.mark("foo3", "a") + Term2::Zone.mark("bar3", "b") + "c", "abc", ["foo3", "bar3"]),
    ScanTestCase.new("id-multi-start-end", "a" + Term2::Zone.mark("foo4", "b") + Term2::Zone.mark("bar4", "c") + "d", "abcd", ["foo4", "bar4"]),
    ScanTestCase.new("inception", Term2::Zone.mark("foo", Term2::Zone.mark("bar", "b")), "b", ["foo", "bar"]),
    ScanTestCase.new("long-x1", "a" + Term2::Zone.mark("longtest5", "testing") + "a", "atestinga", ["longtest5"]),
    ScanTestCase.new("long-x2", ("a" + Term2::Zone.mark("longtest", "testing") + "a") * 1, ("a" + "testing" + "a") * 1, ["longtest"]),
    ScanTestCase.new("long-x4", ("a" + Term2::Zone.mark("longtest", "testing") + "a") * 4, ("a" + "testing" + "a") * 4, ["longtest"]),
    ScanTestCase.new("long-x6", ("a" + Term2::Zone.mark("longtest", "testing") + "a") * 6, ("a" + "testing" + "a") * 6, ["longtest"]),
    ScanTestCase.new("long-x8", ("a" + Term2::Zone.mark("longtest", "testing") + "a") * 8, ("a" + "testing" + "a") * 8, ["longtest"]),
    ScanTestCase.new("long-x10", ("a" + Term2::Zone.mark("longtest", "testing") + "a") * 10, ("a" + "testing" + "a") * 10, ["longtest"]),
    ScanTestCase.new("invalid-no-bracket", "a\x1B12345Zb", "a\x1B12345Zb", [] of String),
    ScanTestCase.new("invalid-no-bracket-end", "a\x1B", "a\x1B", [] of String),
    ScanTestCase.new("invalid-no-numbers", "a\x1BZb", "a\x1BZb", [] of String),
    ScanTestCase.new("invalid-no-numbers-end", "a\x1BZ", "a\x1BZ", [] of String),
    ScanTestCase.new("invalid-marker-end", "a\x1B12345b", "a\x1B12345b", [] of String),
    ScanTestCase.new("invalid-marker-end-2", "a\x1B12345", "a\x1B12345", [] of String),
    ScanTestCase.new("invalid-run-of-numbers", "a\x1B12345b6Z", "a\x1B12345b6Z", [] of String),
    ScanTestCase.new("invalid-misc", "\x1Ba\x1B\x1B\x1B12345b6Z\x1B", "\x1Ba\x1B\x1B\x1B12345b6Z\x1B", [] of String),
  ]
end

describe "Term2::Zone.scan" do
  before_each do
    Term2::Zone.reset
  end

  it "mirrors bubblezone scan cases" do
    tests = build_tests(style)
    tests.each do |test|
      got = Term2::Zone.scan(test.input)
      got.should eq(test.want)

      next if test.ids.empty?
      sleep 50.milliseconds
      test.ids.each do |id|
        Term2::Zone.get(id).is_zero?.should be_false
      end
    end
  end

  it "handles disabled scanning" do
    tests = build_tests(style)
    Term2::Zone.enabled = false
    tests.each do |test|
      got = Term2::Zone.scan(test.input)
      got.should eq(test.want)
    end
    sleep 50.milliseconds
    Term2::Zone.get("testing2").is_zero?.should be_true
    Term2::Zone.enabled = true
  end
end
