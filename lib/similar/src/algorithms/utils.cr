module Similar::Algorithms
  # Utility function to check if a range is empty.
  def self.is_empty_range(range : Range(Int32, Int32)) : Bool
    range.begin >= range.end
  end

  # Given two lookups and ranges calculates the length of the common prefix.
  def self.common_prefix_len(old, old_range : Range(Int32, Int32), new, new_range : Range(Int32, Int32)) : Int32
    return 0 if is_empty_range(old_range) || is_empty_range(new_range)

    count = 0
    old_idx = old_range.begin
    new_idx = new_range.begin

    while old_idx < old_range.end && new_idx < new_range.end
      break unless old[old_idx] == new[new_idx]
      count += 1
      old_idx += 1
      new_idx += 1
    end

    count
  end

  # Given two lookups and ranges calculates the length of common suffix.
  def self.common_suffix_len(old, old_range : Range(Int32, Int32), new, new_range : Range(Int32, Int32)) : Int32
    return 0 if is_empty_range(old_range) || is_empty_range(new_range)

    count = 0
    old_idx = old_range.end - 1
    new_idx = new_range.end - 1

    while old_idx >= old_range.begin && new_idx >= new_range.begin
      break unless old[old_idx] == new[new_idx]
      count += 1
      old_idx -= 1
      new_idx -= 1
    end

    count
  end

  # Represents an item in the vector returned by `unique`.
  #
  # It compares like the underlying item does it was created from but
  # carries the index it was originally created from.
  class UniqueItem(T)
    getter lookup : T
    getter index : Int32

    def initialize(@lookup : T, @index : Int32)
    end

    # Returns the value.
    def value
      @lookup[@index]
    end

    # Returns the original index.
    def original_index : Int32
      @index
    end

    def ==(other : UniqueItem) : Bool
      value == other.value
    end

    def_equals_and_hash @lookup, @index
  end

  # Returns only unique items in the sequence as vector.
  #
  # Each item is wrapped in a `UniqueItem` so that both the value and the
  # index can be extracted.
  def self.unique(lookup, range : Range(Int32, Int32))
    # Return empty array if range is empty
    return [] of UniqueItem(typeof(lookup)) if is_empty_range(range)

    # Create a hash map to track seen items
    seen = Hash(typeof(lookup[range.begin]), Int32?).new
    result = [] of UniqueItem(typeof(lookup))

    range.each do |index|
      item = lookup[index]
      case seen[item]?
      when nil
        # First time seeing this item
        seen[item] = index
      when Int32
        # Second time seeing this item, mark as non-unique
        seen[item] = nil
      else # nil
        # Already marked as non-unique, do nothing
      end
    end

    # Collect unique items and sort by original index
    seen.each do |_, index|
      if index
        result << UniqueItem.new(lookup, index)
      end
    end

    result.sort_by!(&.original_index)
    result
  end

  # Internal helper struct for offset indexing
  private class OffsetLookup(Int)
    getter offset : Int32
    getter vec : Array(Int)

    def initialize(@offset : Int32, @vec : Array(Int))
    end

    def [](index : Int32) : Int
      @vec[index - @offset]
    end
  end

  # A utility struct to convert distinct items to unique integers.
  #
  # This can be helpful on larger inputs to speed up the comparisons
  # performed by doing a first pass where the data set gets reduced
  # to (small) integers.
  #
  # The idea is that instead of passing two sequences to a diffling algorithm
  # you first pass it via `IdentifyDistinct`:
  #
  # ```
  # old = ["foo", "bar", "baz"]
  # new = ["foo", "blah", "baz"]
  # h = IdentifyDistinct(Int32).new(old, 0...old.size, new, 0...new.size)
  # ops = Similar.capture_diff(
  #   Algorithm::Myers,
  #   h.old_lookup,
  #   h.old_range,
  #   h.new_lookup,
  #   h.new_range
  # )
  # ```
  #
  # The indexes are the same as with the passed source ranges.
  class IdentifyDistinct(Int)
    @old : OffsetLookup(Int)
    @new : OffsetLookup(Int)

    # Creates an int hasher for two sequences.
    def self.new(old, old_range : Range(Int32, Int32), new, new_range : Range(Int32, Int32)) : self
      new(old, old_range, new, new_range)
    end

    def initialize(old, old_range : Range(Int32, Int32), new, new_range : Range(Int32, Int32))
      # Ensure ranges are exclusive
      old_range = old_range.begin...old_range.end
      new_range = new_range.begin...new_range.end

      # We assume old and new have the same element type
      map = Hash(typeof(old[old_range.begin]), Int).new
      old_seq = [] of Int
      new_seq = [] of Int
      next_id = Int.zero
      step = Int.new(1)

      old_range.each do |idx|
        item = old[idx]
        id = map.fetch(item) do
          new_id = next_id
          next_id += step
          map[item] = new_id
          new_id
        end
        old_seq << id
      end

      new_range.each do |idx|
        item = new[idx]
        id = map.fetch(item) do
          new_id = next_id
          next_id += step
          map[item] = new_id
          new_id
        end
        new_seq << id
      end

      @old = OffsetLookup(Int).new(old_range.begin, old_seq)
      @new = OffsetLookup(Int).new(new_range.begin, new_seq)
    end

    # Returns a lookup for the old side.
    def old_lookup : OffsetLookup(Int)
      @old
    end

    # Returns a lookup for the new side.
    def new_lookup : OffsetLookup(Int)
      @new
    end

    # Convenience method to get back the old range.
    def old_range : Range(Int32, Int32)
      @old.offset...(@old.offset + @old.vec.size)
    end

    # Convenience method to get back the new range.
    def new_range : Range(Int32, Int32)
      @new.offset...(@new.offset + @new.vec.size)
    end
  end
end
