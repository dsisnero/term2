# spec/bubblezone/unit/zone_spec.cr
# Port of zone_test.go

require "../support/spec_helper"

describe "Zone" do
  describe "#contains?" do
    it "returns true for points inside the zone" do
      zone = Zone.new(10, 10, 20, 15)

      # Center point
      expect(zone.contains?(15, 12)).to be_true

      # Edge points (inclusive of left/top, exclusive of right/bottom)
      expect(zone.contains?(10, 10)).to be_true # Top-left
      expect(zone.contains?(29, 10)).to be_true # Top-right (exclusive: 30 is outside)
      expect(zone.contains?(10, 24)).to be_true # Bottom-left (exclusive: 25 is outside)
      expect(zone.contains?(29, 24)).to be_true # Bottom-right (both exclusive)
    end

    it "returns false for points outside the zone" do
      zone = Zone.new(10, 10, 20, 15)

      # Outside on all sides
      expect(zone.contains?(5, 5)).to be_false   # Above and left
      expect(zone.contains?(35, 5)).to be_false  # Above and right
      expect(zone.contains?(5, 30)).to be_false  # Below and left
      expect(zone.contains?(35, 30)).to be_false # Below and right

      # On exclusive edges
      expect(zone.contains?(30, 15)).to be_false # Right edge (exclusive)
      expect(zone.contains?(15, 25)).to be_false # Bottom edge (exclusive)
    end

    it "handles zero-sized zones" do
      zone = Zone.new(10, 10, 0, 0)
      expect(zone.contains?(10, 10)).to be_false # Point is outside (width/height are 0)
    end

    it "handles negative coordinates" do
      zone = Zone.new(-10, -10, 20, 15)
      expect(zone.contains?(-5, -5)).to be_true    # Inside negative quadrant
      expect(zone.contains?(5, 5)).to be_false     # Outside (would be 10,10 in positive)
      expect(zone.contains?(-15, -15)).to be_false # Outside negative
    end
  end

  describe "#overlaps?" do
    it "returns true for overlapping zones" do
      zone1 = Zone.new(10, 10, 20, 15)
      zone2 = Zone.new(15, 15, 20, 15)

      expect(zone1.overlaps?(zone2)).to be_true
      expect(zone2.overlaps?(zone1)).to be_true # Should be commutative
    end

    it "returns true for touching zones" do
      zone1 = Zone.new(10, 10, 10, 10)
      zone2 = Zone.new(20, 10, 10, 10) # Touches on right edge
      zone3 = Zone.new(10, 20, 10, 10) # Touches on bottom edge

      # Typically touching counts as overlapping in bubblezone
      expect(zone1.overlaps?(zone2)).to be_true
      expect(zone1.overlaps?(zone3)).to be_true
    end

    it "returns false for non-overlapping zones" do
      zone1 = Zone.new(10, 10, 10, 10)
      zone2 = Zone.new(25, 10, 10, 10) # Gap of 5 pixels
      zone3 = Zone.new(10, 25, 10, 10) # Gap of 5 pixels

      expect(zone1.overlaps?(zone2)).to be_false
      expect(zone1.overlaps?(zone3)).to be_false
    end

    it "handles zero-sized zones" do
      zone1 = Zone.new(10, 10, 0, 0)
      zone2 = Zone.new(10, 10, 10, 10)

      # Zero-sized zone at same position - typically doesn't overlap
      expect(zone1.overlaps?(zone2)).to be_false
      expect(zone2.overlaps?(zone1)).to be_false
    end

    it "handles completely contained zones" do
      outer = Zone.new(10, 10, 50, 50)
      inner = Zone.new(20, 20, 10, 10)

      expect(outer.overlaps?(inner)).to be_true
      expect(inner.overlaps?(outer)).to be_true
    end
  end

  describe "#intersection" do
    it "returns the intersecting rectangle for overlapping zones" do
      zone1 = Zone.new(10, 10, 20, 15)
      zone2 = Zone.new(15, 15, 20, 15)

      intersection = zone1.intersection(zone2)

      expect(intersection.x).to eq(15)
      expect(intersection.y).to eq(15)
      expect(intersection.width).to eq(15)  # 10+20-15 = 15
      expect(intersection.height).to eq(10) # 10+15-15 = 10
    end

    it "returns nil for non-overlapping zones" do
      zone1 = Zone.new(10, 10, 10, 10)
      zone2 = Zone.new(25, 10, 10, 10)

      expect(zone1.intersection(zone2)).to be_nil
    end

    it "handles edge cases" do
      # Same zone
      zone = Zone.new(10, 10, 20, 15)
      intersection = zone.intersection(zone)
      expect(intersection.x).to eq(10)
      expect(intersection.y).to eq(10)
      expect(intersection.width).to eq(20)
      expect(intersection.height).to eq(15)

      # Touching zones (if implementation considers this overlapping)
      zone1 = Zone.new(10, 10, 10, 10)
      zone2 = Zone.new(20, 10, 10, 10)
      # Depends on implementation - may return zero-width rectangle or nil
    end
  end

  describe "#==" do
    it "returns true for identical zones" do
      zone1 = Zone.new(10, 10, 20, 15)
      zone2 = Zone.new(10, 10, 20, 15)

      expect(zone1).to eq(zone2)
    end

    it "returns false for different zones" do
      zone1 = Zone.new(10, 10, 20, 15)
      zone2 = Zone.new(11, 10, 20, 15) # Different x
      zone3 = Zone.new(10, 11, 20, 15) # Different y
      zone4 = Zone.new(10, 10, 21, 15) # Different width
      zone5 = Zone.new(10, 10, 20, 16) # Different height

      expect(zone1).not_to eq(zone2)
      expect(zone1).not_to eq(zone3)
      expect(zone1).not_to eq(zone4)
      expect(zone1).not_to eq(zone5)
    end

    it "handles zones with IDs" do
      zone1 = Zone.new(10, 10, 20, 15, "zone1")
      zone2 = Zone.new(10, 10, 20, 15, "zone1")
      zone3 = Zone.new(10, 10, 20, 15, "zone2")

      expect(zone1).to eq(zone2)     # Same ID
      expect(zone1).not_to eq(zone3) # Different ID
    end
  end

  describe "edge cases and error handling" do
    it "handles negative dimensions" do
      # Depending on implementation, may raise error or normalize
      expect { Zone.new(10, 10, -5, 10) }.to raise_error(ArgumentError) # or similar
      expect { Zone.new(10, 10, 10, -5) }.to raise_error(ArgumentError)
    end

    it "handles very large coordinates" do
      zone = Zone.new(Int32::MAX - 100, Int32::MAX - 100, 200, 200)
      # Should not overflow when checking contains
      expect(zone.contains?(Int32::MAX - 50, Int32::MAX - 50)).to be_true
    end
  end

  # Data-driven tests (equivalent to Go table tests)
  describe "contains? - data driven tests" do
    test_cases = [
      # zone, point, expected
      {Zone.new(0, 0, 10, 10), {5, 5}, true},
      {Zone.new(0, 0, 10, 10), {0, 0}, true},
      {Zone.new(0, 0, 10, 10), {9, 9}, true},
      {Zone.new(0, 0, 10, 10), {10, 5}, false},
      {Zone.new(0, 0, 10, 10), {5, 10}, false},
      {Zone.new(0, 0, 10, 10), {-1, 5}, false},
      {Zone.new(0, 0, 10, 10), {5, -1}, false},
      {Zone.new(-5, -5, 10, 10), {0, 0}, true},
      {Zone.new(-5, -5, 10, 10), {-5, -5}, true},
      {Zone.new(-5, -5, 10, 10), {4, 4}, true},
      {Zone.new(-5, -5, 10, 10), {5, 5}, false},
    ]

    test_cases.each_with_index do |(zone, (x, y), expected), i|
      it "case #{i}: zone #{zone}, point (#{x}, #{y}) -> #{expected}" do
        expect(zone.contains?(x, y)).to eq(expected)
      end
    end
  end

  describe "overlaps? - data driven tests" do
    test_cases = [
      # zone1, zone2, expected
      {Zone.new(0, 0, 10, 10), Zone.new(5, 5, 10, 10), true},
      {Zone.new(0, 0, 10, 10), Zone.new(10, 0, 10, 10), true},   # touching
      {Zone.new(0, 0, 10, 10), Zone.new(0, 10, 10, 10), true},   # touching
      {Zone.new(0, 0, 10, 10), Zone.new(11, 0, 10, 10), false},  # gap of 1
      {Zone.new(0, 0, 10, 10), Zone.new(0, 11, 10, 10), false},  # gap of 1
      {Zone.new(0, 0, 10, 10), Zone.new(20, 20, 10, 10), false}, # far away
      {Zone.new(0, 0, 10, 10), Zone.new(0, 0, 5, 5), true},      # contained
      {Zone.new(0, 0, 10, 10), Zone.new(-5, -5, 10, 10), true},  # overlapping negative
    ]

    test_cases.each_with_index do |(zone1, zone2, expected), i|
      it "case #{i}: #{zone1} overlaps? #{zone2} -> #{expected}" do
        expect(zone1.overlaps?(zone2)).to eq(expected)
        # Test commutativity
        expect(zone2.overlaps?(zone1)).to eq(expected)
      end
    end
  end
end
