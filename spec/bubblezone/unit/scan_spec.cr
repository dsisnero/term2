# spec/bubblezone/unit/scan_spec.cr
# Comprehensive scan tests

require "../spec_helper"

# Test cases from Go tests
# Note: We can't define markers at compile time because they get cleared by reset()
# Instead, we'll define test cases as procs that generate markers at test time
TEST_CASES = [
  {"empty", -> { "" }, "", [] of String},
  {"single", -> { "a" }, "a", [] of String},
  {"double", -> { "aa" }, "aa", [] of String},
  {"triple", -> { "aaa" }, "aaa", [] of String},
  {"quad", -> { "aaaa" }, "aaaa", [] of String},
  {"id-empty", -> { Term2::Zone.mark("testing1", "") }, "", [] of String},
  {"id-single-start", -> { "a" + Term2::Zone.mark("testing2", "a") }, "aa", ["testing2"]},
  {"id-single-end", -> { Term2::Zone.mark("testing3", "a") + "a" }, "aa", ["testing3"]},
  {"id-single-start-end", -> { "a" + Term2::Zone.mark("testing4", "b") + "a" }, "aba", ["testing4"]},
  {"id-single-between", -> { Term2::Zone.mark("testing5", "b") + "a" + Term2::Zone.mark("testing6", "b") }, "bab", ["testing5", "testing6"]},
  {"id-multi-empty", -> { Term2::Zone.mark("foo1", "") + Term2::Zone.mark("bar1", "") }, "", [] of String},
  {"id-multi-start", -> { "a" + Term2::Zone.mark("foo2", "b") + Term2::Zone.mark("bar2", "c") }, "abc", ["foo2", "bar2"]},
  {"id-multi-end", -> { Term2::Zone.mark("foo3", "a") + Term2::Zone.mark("bar3", "b") + "c" }, "abc", ["foo3", "bar3"]},
  {"id-multi-start-end", -> { "a" + Term2::Zone.mark("foo4", "b") + Term2::Zone.mark("bar4", "c") + "d" }, "abcd", ["foo4", "bar4"]},
  {"inception", -> { Term2::Zone.mark("foo", Term2::Zone.mark("bar", "b")) }, "b", ["foo", "bar"]},
]

describe "Term2::Zone scan functionality" do
  describe "basic scan operations" do
    TEST_CASES.each do |test_case|
      name, input_proc, expected, ids = test_case

      it "handles #{name}" do
        input = input_proc.call
        result = Term2::Zone.scan(input)
        result.should eq(expected)

        if !ids.empty?
          sleep 50.milliseconds
          ids.each do |id|
            zone = Term2::Zone.get(id)
            zone.zero?.should be_false
          end
        end
      end
    end
  end

  describe "invalid escape sequences" do
    it "preserves invalid escape sequences unchanged" do
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

      invalid_cases.each do |name, input, expected|
        result = Term2::Zone.scan(input)
        result.should eq(expected), "Failed for #{name}: got #{result.inspect}, expected #{expected.inspect}"
      end
    end
  end

  describe "performance characteristics" do
    it "handles repeated patterns efficiently" do
      # Test with repeated markers
      content = ""
      10.times do |i|
        content += "prefix" + Term2::Zone.mark("repeat_#{i}", "content#{i}") + "suffix"
      end

      result = Term2::Zone.scan(content)

      # Result should have markers removed
      result.should_not contain("\x1B[")

      # All zones should be registered
      sleep 100.milliseconds
      10.times do |i|
        zone = Term2::Zone.get("repeat_#{i}")
        zone.zero?.should be_false
      end
    end

    it "handles long content with markers" do
      # Create a long string with markers
      long_content = "Start: "
      50.times do |i|
        long_content += Term2::Zone.mark("long_#{i}", "item#{i}") + " "
      end
      long_content += "End"

      result = Term2::Zone.scan(long_content)

      # Should process without errors
      result.size.should be > 0
      result.should_not contain("\x1B[")
    end
  end

  describe "edge cases" do
    it "handles newlines and special characters" do
      test_cases = [
        {"newlines", "line1\n" + Term2::Zone.mark("nl", "middle\npart") + "\nline3", "line1\nmiddle\npart\nline3", ["nl"]},
        {"tabs", "before\t" + Term2::Zone.mark("tab", "tabbed\tcontent") + "\tafter", "before\ttabbed\tcontent\tafter", ["tab"]},
        {"unicode", "before " + Term2::Zone.mark("uni", "café 🎉 test") + " after", "before café 🎉 test after", ["uni"]},
      ]

      test_cases.each do |name, input, expected, ids|
        result = Term2::Zone.scan(input)
        result.should eq(expected), "Failed for #{name}"

        if !ids.empty?
          sleep 50.milliseconds
          ids.each do |id|
            zone = Term2::Zone.get(id)
            zone.zero?.should be_false
          end
        end
      end
    end

    it "handles empty and nil-like inputs" do
      Term2::Zone.scan("").should eq("")
      Term2::Zone.scan("\n").should eq("\n")
      Term2::Zone.scan("   ").should eq("   ")
    end
  end

  describe "concurrent scans" do
    it "handles rapid successive scans" do
      # Perform multiple scans quickly
      5.times do |i|
        input = "Scan #{i}: " + Term2::Zone.mark("fast_#{i}", "content#{i}")
        result = Term2::Zone.scan(input)
        result.should eq("Scan #{i}: content#{i}")
      end

      # Wait for processing
      sleep 100.milliseconds

      # Check zones
      5.times do |i|
        zone = Term2::Zone.get("fast_#{i}")
        # Only the last one might exist due to clearing
        # This depends on the implementation
        zone.zero?.should be_true if i < 4
      end
    end
  end
end