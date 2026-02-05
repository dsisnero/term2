require "json"
require "../types"
require "./utils"

module Similar
  # Represents the expanded textual change with inline highlights.
  #
  # This is like `Change` but with inline highlight info.
  class InlineChange
    include JSON::Serializable
    @tag : ChangeTag
    @old_index : Int32?
    @new_index : Int32?
    @values : Array({Bool, String})

    def initialize(@tag : ChangeTag, @old_index : Int32?, @new_index : Int32?, @values : Array({Bool, String}))
    end

    # Returns the change tag.
    def tag : ChangeTag
      @tag
    end

    # Returns the old index if available.
    def old_index : Int32?
      @old_index
    end

    # Returns the new index if available.
    def new_index : Int32?
      @new_index
    end

    # Returns the changed values.
    #
    # Each item is a tuple in the form `(emphasized, value)` where `emphasized`
    # is true if it should be highlighted as an inline diff.
    def values : Array({Bool, String})
      @values
    end

    # Returns `true` if this change does not end in a newline and must be
    # followed up by one if line based diffs are used.
    def missing_newline? : Bool
      return true if @values.empty?
      !Text.ends_with_newline(@values.last[1])
    end

    # Creates an InlineChange from a regular Change.
    def self.from_change(change : Change(T)) : InlineChange forall T
      values = [{false, change.value.to_s}]
      InlineChange.new(
        change.tag,
        change.old_index,
        change.new_index,
        values
      )
    end
  end

  # Internal helper for word-level diffing in inline changes.
  private class WordLookup
    @words : Array(String)
    @slice_index : Int32
    @offsets : Array(Int32)
    @slice : String

    def initialize(slice : String, slice_index : Int32)
      @slice = slice
      @slice_index = slice_index
      @words = Text.tokenize_words(slice)
      @offsets = compute_offsets(slice)
    end

    def size : Int32
      @words.size.to_i32
    end

    def [](index : Int32) : String
      @words[index]
    end

    getter words : Array(String)

    # Returns original slice substring for word range [start, start+len)
    def original_slice(start : Int32, len : Int32) : String
      return "" if len <= 0
      byte_start = @offsets[start]
      byte_end = if start + len < @offsets.size
                   @offsets[start + len]
                 else
                   # Last word goes to end of slice
                   @slice.bytesize
                 end
      @slice.byte_slice(byte_start, byte_end - byte_start)
    end

    private def compute_offsets(slice : String) : Array(Int32)
      offsets = [] of Int32
      offset = 0
      @words.each do |word|
        offsets << offset
        offset += word.bytesize
      end
      offsets
    end
  end

  # Iterates over inline changes for a diff operation.
  def self.iter_inline_changes(diff : TextDiff(T), op : DiffOp) : Array(InlineChange) forall T
    tag, old_range, new_range = op.as_tag_tuple

    # For simple operations, just wrap changes
    if tag == DiffTag::Equal || tag == DiffTag::Insert || tag == DiffTag::Delete
      return diff.iter_changes(op).map { |change| InlineChange.from_change(change) }.to_a
    end

    # For replace operations, do word-level diffing
    # Simplified: assume single old and new slice (true for line diffs)
    old_start = old_range.begin
    new_start = new_range.begin
    old_len = (old_range.end - old_range.begin).to_i32
    new_len = (new_range.end - new_range.begin).to_i32

    if old_len != 1 || new_len != 1
      # Fall back to simple changes for multi-slice replaces
      return diff.iter_changes(op).map { |change| InlineChange.from_change(change) }.to_a
    end

    old_slice = diff.old_tokens[old_start].to_s
    new_slice = diff.new_tokens[new_start].to_s

    # Create word lookups
    old_lookup = WordLookup.new(old_slice, old_start)
    new_lookup = WordLookup.new(new_slice, new_start)

    # Run diff on words
    word_ops = Similar.capture_diff_slices(Algorithm::Patience, old_lookup.words, new_lookup.words)

    delete_values = [] of {Bool, String}
    insert_values = [] of {Bool, String}

    word_ops.each do |word_op|
      case word_op.tag
      when DiffTag::Equal
        eq = word_op.as(DiffOp::Equal)
        slice = old_lookup.original_slice(eq.old_index, eq.len)
        delete_values << {false, slice}
        insert_values << {false, slice}
      when DiffTag::Delete
        del = word_op.as(DiffOp::Delete)
        slice = old_lookup.original_slice(del.old_index, del.old_len)
        delete_values << {true, slice}
      when DiffTag::Insert
        ins = word_op.as(DiffOp::Insert)
        slice = new_lookup.original_slice(ins.new_index, ins.new_len)
        insert_values << {true, slice}
      when DiffTag::Replace
        rep = word_op.as(DiffOp::Replace)
        old_slice = old_lookup.original_slice(rep.old_index, rep.old_len)
        new_slice = new_lookup.original_slice(rep.new_index, rep.new_len)
        delete_values << {true, old_slice}
        insert_values << {true, new_slice}
      end
    end

    result = [] of InlineChange
    if !delete_values.empty?
      result << InlineChange.new(
        ChangeTag::Delete,
        old_start,
        nil,
        delete_values
      )
    end

    if !insert_values.empty?
      result << InlineChange.new(
        ChangeTag::Insert,
        nil,
        new_start,
        insert_values
      )
    end

    result
  end
end
