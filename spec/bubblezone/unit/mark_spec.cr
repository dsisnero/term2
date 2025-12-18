# spec/bubblezone/unit/mark_spec.cr
# Mark functionality tests

require "../spec_helper"

describe "Term2::Zone mark functionality" do
  describe "basic mark operations" do
    it "creates valid zone markers" do
      marked = Term2::Zone.mark("test_id", "test content")

      # Should contain escape sequence
      marked.should contain("\x1B[")

      # Should contain the content
      marked.should contain("test content")

      # Should be different from original
      marked.should_not eq("test content")
    end

    it "handles empty content" do
      marked = Term2::Zone.mark("empty_id", "")

      # According to Go implementation, empty content returns empty string
      marked.should eq("")
      marked.size.should eq(0)

      # Scanning should produce empty string
      result = Term2::Zone.scan(marked)
      result.should eq("")
    end

    it "handles special characters in content" do
      test_cases = [
        {"newlines", "line1\nline2\nline3"},
        {"tabs", "col1\tcol2\tcol3"},
        {"escape chars", "\x1B[31mred\x1B[0m"},
        {"unicode", "café 🎉 test"},
        {"brackets", "text [with] brackets"},
        {"parentheses", "text (with) parens"},
      ]

      test_cases.each do |name, content|
        marked = Term2::Zone.mark("special_#{name}", content)

        # Should contain the content
        marked.should contain(content)

        # Should be scannable
        result = Term2::Zone.scan(marked)
        result.should eq(content)
      end
    end
  end

  describe "mark with different IDs" do
    it "creates unique markers for different IDs" do
      content = "same content"
      mark1 = Term2::Zone.mark("id1", content)
      mark2 = Term2::Zone.mark("id2", content)

      # Should be different markers
      mark1.should_not eq(mark2)

      # Both should contain the content
      mark1.should contain(content)
      mark2.should contain(content)

      # Both should be scannable
      result1 = Term2::Zone.scan(mark1)
      result2 = Term2::Zone.scan(mark2)

      result1.should eq(content)
      result2.should eq(content)
    end

    it "handles IDs with special characters" do
      id = "test-id_with.underscores_and-dashes"
      content = "test content"

      marked = Term2::Zone.mark(id, content)
      marked.should contain(content)

      # Should be scannable and create zone
      result = Term2::Zone.scan(marked)
      result.should eq(content)

      sleep 50.milliseconds
      zone = Term2::Zone.get(id)
      zone.zero?.should be_false
    end
  end

  describe "mark performance" do
    it "handles many marks efficiently" do
      # Create many marks
      marks = [] of String
      100.times do |i|
        marks << Term2::Zone.mark("perf_#{i}", "content #{i}")
      end

      # All should be valid
      marks.each do |mark|
        mark.should contain("\x1B[")
      end

      # Combine and scan
      combined = marks.join(" ")
      result = Term2::Zone.scan(combined)

      # Should have markers removed
      result.should_not contain("\x1B[")
    end

    it "handles large content" do
      # Create large content
      large_content = "x" * 10000

      marked = Term2::Zone.mark("large", large_content)

      # Should contain the content
      marked.should contain(large_content)

      # Should be scannable
      result = Term2::Zone.scan(marked)
      result.should eq(large_content)
    end
  end

  describe "mark and scan integration" do
    it "creates zones that can be retrieved" do
      content = "zone content"
      marked = Term2::Zone.mark("retrievable", content)

      # Scan to process
      result = Term2::Zone.scan(marked)
      result.should eq(content)

      # Wait for processing
      sleep 100.milliseconds

      # Zone should exist
      zone = Term2::Zone.get("retrievable")
      zone.zero?.should be_false
      zone.id.should eq("retrievable")
    end

    it "updates zones when re-marked" do
      # First mark
      mark1 = Term2::Zone.mark("update_test", "first")
      Term2::Zone.scan(mark1)
      sleep 50.milliseconds

      zone1 = Term2::Zone.get("update_test")
      zone1.zero?.should be_false

      # Second mark with different content
      mark2 = Term2::Zone.mark("update_test", "second longer content")
      Term2::Zone.scan(mark2)
      sleep 50.milliseconds

      zone2 = Term2::Zone.get("update_test")
      zone2.zero?.should be_false

      # Should be the same zone ID but potentially different bounds
      zone2.id.should eq(zone1.id)
    end
  end

  describe "edge cases" do
    it "handles nil/empty IDs" do
      # Note: In Crystal, empty string is valid but might not create a usable zone
      marked = Term2::Zone.mark("", "content")
      marked.should contain("content")

      result = Term2::Zone.scan(marked)
      result.should eq("content")
    end

    it "handles very long IDs" do
      long_id = "a" * 1000
      content = "test"

      marked = Term2::Zone.mark(long_id, content)
      marked.should contain(content)

      # Should be scannable
      result = Term2::Zone.scan(marked)
      result.should eq(content)
    end

    it "preserves exact content" do
      exact_content = "  leading and trailing spaces  "
      marked = Term2::Zone.mark("exact", exact_content)

      # Should preserve spaces
      marked.should contain(exact_content)

      result = Term2::Zone.scan(marked)
      result.should eq(exact_content)
    end
  end
end
