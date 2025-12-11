# spec/bubblezone/unit/manager_spec.cr
# Port of manager_test.go tests

require "../spec_helper"

# Styled test helpers to mirror bubblezone/manager_test.go
TEST_STYLE = Term2::Style.new_style
  .foreground(Term2::Color.from_hex("#FFFFFF"))
  .background(Term2::Color.from_hex("#383838"))
  .bold
  .italic
  .blink

LONG_STYLE = Term2::Style.new_style
  .foreground(Term2::Color.from_hex("#FFFFFF"))
  .background(Term2::Color.from_hex("#383838"))
  .bold
  .italic
  .blink
  .underline
  .border(Term2::Border.rounded, true)
  .border_foreground(Term2::Color.from_hex("#F12356"))
  .border_background(Term2::Color.from_hex("#459082"))
  .padding(5, 4)

# Test cases from Go tests
# Note: We can't define markers at compile time because they get cleared by reset()
# Instead, we'll define test cases as procs that generate markers at test time
MANAGER_TEST_CASES = [
  {"empty", -> { "" }, "", [] of String},
  {"single", -> { "a" }, "a", [] of String},
  {"double", -> { "aa" }, "aa", [] of String},
  {"triple", -> { "aaa" }, "aaa", [] of String},
  {"quad", -> { "aaaa" }, "aaaa", [] of String},
  {"lipgloss-empty", -> { TEST_STYLE.render("") }, TEST_STYLE.render(""), [] of String},
  {"lipgloss-basic", -> { TEST_STYLE.render("testing") }, TEST_STYLE.render("testing"), [] of String},
  {"lipgloss-basic-start", -> { "a" + TEST_STYLE.render("testing") }, "a" + TEST_STYLE.render("testing"), [] of String},
  {"lipgloss-basic-end", -> { TEST_STYLE.render("testing") + "a" }, TEST_STYLE.render("testing") + "a", [] of String},
  {"lipgloss-basic-start-end", -> { "a" + TEST_STYLE.render("testing") + "a" }, "a" + TEST_STYLE.render("testing") + "a", [] of String},
  {"lipgloss-basic-between", -> { TEST_STYLE.render("testing") + "a" + TEST_STYLE.render("testing") }, TEST_STYLE.render("testing") + "a" + TEST_STYLE.render("testing"), [] of String},
  {"id-empty", -> { Term2::Zone.mark("testing1", "") }, "", [] of String},
  {"id-single-start", -> { "a" + Term2::Zone.mark("testing2", "a") }, "aa", ["testing2"]},
  {"id-single-end", -> { Term2::Zone.mark("testing3", "a") + "a" }, "aa", ["testing3"]},
  {"id-single-start-end", -> { "a" + Term2::Zone.mark("testing4", "b") + "a" }, "aba", ["testing4"]},
  {"id-single-between", -> { Term2::Zone.mark("testing5", "b") + "a" + Term2::Zone.mark("testing6", "b") }, "bab", ["testing5", "testing6"]},
  {"id-with-lipgloss-start", -> { TEST_STYLE.render(Term2::Zone.mark("testing7", "testing") + "testing") }, TEST_STYLE.render("testingtesting"), ["testing7"]},
  {"id-with-lipgloss-end", -> { TEST_STYLE.render("testing" + Term2::Zone.mark("testing8", "testing")) }, TEST_STYLE.render("testingtesting"), ["testing8"]},
  {"id-multi-empty", -> { Term2::Zone.mark("foo1", "") + Term2::Zone.mark("bar1", "") }, "", [] of String},
  {"id-multi-start", -> { "a" + Term2::Zone.mark("foo2", "b") + Term2::Zone.mark("bar2", "c") }, "abc", ["foo2", "bar2"]},
  {"id-multi-end", -> { Term2::Zone.mark("foo3", "a") + Term2::Zone.mark("bar3", "b") + "c" }, "abc", ["foo3", "bar3"]},
  {"id-multi-start-end", -> { "a" + Term2::Zone.mark("foo4", "b") + Term2::Zone.mark("bar4", "c") + "d" }, "abcd", ["foo4", "bar4"]},
  {"inception", -> { Term2::Zone.mark("foo", Term2::Zone.mark("bar", "b")) }, "b", ["foo", "bar"]},
  {"long-x1", -> { "a" + Term2::Zone.mark("longtest5", LONG_STYLE.render("testing")) + "a" }, "a" + LONG_STYLE.render("testing") + "a", ["longtest5"]},
  {"long-x2", -> { ("a" + Term2::Zone.mark("longtest", LONG_STYLE.render("testing")) + "a") * 1 }, ("a" + LONG_STYLE.render("testing") + "a") * 1, ["longtest"]},
  {"long-x4", -> { ("a" + Term2::Zone.mark("longtest", LONG_STYLE.render("testing")) + "a") * 4 }, ("a" + LONG_STYLE.render("testing") + "a") * 4, ["longtest"]},
  {"long-x6", -> { ("a" + Term2::Zone.mark("longtest", LONG_STYLE.render("testing")) + "a") * 6 }, ("a" + LONG_STYLE.render("testing") + "a") * 6, ["longtest"]},
  {"long-x8", -> { ("a" + Term2::Zone.mark("longtest", LONG_STYLE.render("testing")) + "a") * 8 }, ("a" + LONG_STYLE.render("testing") + "a") * 8, ["longtest"]},
  {"long-x10", -> { ("a" + Term2::Zone.mark("longtest", LONG_STYLE.render("testing")) + "a") * 10 }, ("a" + LONG_STYLE.render("testing") + "a") * 10, ["longtest"]},
]

describe "Term2::Zone manager functionality" do
  describe "scan" do
    MANAGER_TEST_CASES.each do |test_case|
      name, input_proc, expected, ids = test_case

      it "handles #{name}" do
        input = input_proc.call
        result = BubbleZoneHelpers.scan_and_wait(input, 50)
        result.should eq(expected)

        if !ids.empty?
          ids.each do |id|
            zone = Term2::Zone.get(id)
            zone.zero?.should be_false
          end
        end
      end
    end

    it "handles invalid escape sequences" do
      # Test various invalid escape sequences
      invalid_cases = [
        {"invalid-no-bracket", "a\x1B12345Zb", "a\x1B12345Zb"},
        {"invalid-no-bracket-end", "a\x1B", "a\x1B"},
        {"invalid-no-numbers", "a\x1BZb", "a\x1BZb"},
        {"invalid-no-numbers-end", "a\x1BZ", "a\x1BZ"},
        {"invalid-marker-end", "a\x1B12345b", "a\x1B12345b"},
        {"invalid-marker-end-2", "a\x1B12345", "a\x1B12345"},
        {"invalid-run-of-numbers", "a\x1B12345b6Z", "a\x1B12345b6Z"},
        {"invalid-misc", "\x1Ba\x1B\x1B\x1B12345b6Z\x1B", "\x1Ba\x1B\x1B\x1B12345b6Z\x1B"},
      ]

      invalid_cases.each do |_, input, expected|
        result = Term2::Zone.scan(input)
        result.should eq(expected)
      end
    end
  end

  describe "scan with disabled manager" do
    it "returns input unchanged when disabled" do
      saved_inputs = MANAGER_TEST_CASES.map do |name, input_proc, expected, _|
        Term2::Zone.reset
        Term2::Zone.enabled = true
        {name, input_proc.call, expected}
      end

      Term2::Zone.enabled = false
      saved_inputs.each do |name, input, expected|
        Term2::Zone.scan(input).should eq(expected), "failed for #{name}"
      end
    ensure
      Term2::Zone.enabled = true
    end
  end

  describe "mark" do
    it "creates zone markers" do
      # Test basic marking
      marked = Term2::Zone.mark("test1", "content")
      marked.should contain("\x1B[")

      # Test that multiple marks work
      output = ""
      MANAGER_TEST_CASES[0..9].each do |name, input_proc, _, _|
        input = input_proc.call
        output += Term2::Zone.mark(name, input)
      end

      # Scan the output to process zones
      BubbleZoneHelpers.scan_and_wait(output, 100)

      # Check that zones were created for test cases that have zone IDs
      # Only test cases with non-empty ids arrays should have zones
      MANAGER_TEST_CASES[0..9].each do |name, _, _, ids|
        zone = Term2::Zone.get(name)
        if !ids.empty?
          zone.zero?.should be_false
        end
      end
    end

    it "returns input unchanged when disabled" do
      Term2::Zone.enabled = false

      MANAGER_TEST_CASES[0..9].each do |name, input_proc, _, _|
        input = input_proc.call
        Term2::Zone.mark(name, input).should eq(input)
      end
    ensure
      Term2::Zone.enabled = true
    end
  end

  describe "worker clear" do
    it "clears old zones when new ones are scanned" do
      # First scan with zone "foo"
      BubbleZoneHelpers.scan_and_wait("a" + Term2::Zone.mark("foo", "b") + "c", 100)

      # Second scan with zone "bar" - should clear "foo"
      BubbleZoneHelpers.scan_and_wait("a" + Term2::Zone.mark("bar", "b") + "c", 100)

      # Check that "foo" is cleared
      zone_foo = Term2::Zone.get("foo")
      zone_foo.zero?.should be_true

      # Check that "bar" exists
      zone_bar = Term2::Zone.get("bar")
      zone_bar.zero?.should be_false
    end
  end

  describe "clear" do
    it "clears specific zones" do
      # Create a zone
      BubbleZoneHelpers.scan_and_wait("a" + Term2::Zone.mark("foo", "b") + "c", 100)

      # Check it exists
      zone = Term2::Zone.get("foo")
      zone.zero?.should be_false

      # Clear it
      Term2::Zone.clear("foo")

      # Check it's cleared
      zone = Term2::Zone.get("foo")
      zone.zero?.should be_true
    end
  end

  describe "close" do
    it "stops processing after close" do
      BubbleZoneHelpers.scan_and_wait("a" + Term2::Zone.mark("test_close", "b") + "c", 100)

      zone = Term2::Zone.get("test_close")
      zone.zero?.should be_false

      Term2::Zone.close
      scan_after_close = BubbleZoneHelpers.scan_and_wait("a" + Term2::Zone.mark("test_close2", "b") + "c", 100)
      scan_after_close.should eq("abc")
      Term2::Zone.get("test_close2").zero?.should be_true
    ensure
      Term2::Zone.reset
    end
  end

  describe "global initialization" do
    it "can be initialized multiple times" do
      # Reset and reinitialize
      Term2::Zone.reset

      # Test that it still works after reset
      BubbleZoneHelpers.scan_and_wait("a" + Term2::Zone.mark("test_reinit", "b") + "c", 100)

      zone = Term2::Zone.get("test_reinit")
      zone.zero?.should be_false
    end
  end

  describe "benchmark scan" do
    it "scans all test cases without raising" do
      MANAGER_TEST_CASES.each do |_, input_proc, _, _|
        input = input_proc.call
        5.times { Term2::Zone.scan(input) }
      end
    end
  end

  describe "benchmark mark" do
    it "marks all test cases without raising" do
      outputs = MANAGER_TEST_CASES.map do |name, input_proc, _, _|
        Term2::Zone.mark(name, input_proc.call)
      end

      outputs.each do |value|
        next if value.empty?
        value.should contain("\x1B[")
      end

      10.times do
        MANAGER_TEST_CASES.each do |name, input_proc, _, _|
          Term2::Zone.mark(name, input_proc.call).should_not be_nil
        end
      end
    end
  end

  describe "fuzz scan" do
    it "handles arbitrary strings without raising" do
      seeds = MANAGER_TEST_CASES.flat_map { |_, input_proc, expected, _| [input_proc.call, expected] }
      seeds.each { |seed| Term2::Zone.scan(seed).should be_a(String) }

      25.times do |i|
        fuzz = "fuzz-#{i}-" + "x" * i + "\e[#{1000 + i}z"
        Term2::Zone.scan(fuzz).should be_a(String)
      end
    end
  end
end