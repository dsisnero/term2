require "./types"
require "./common"
require "./text/mod"

module Similar::Utils
  # Remaps token slice ranges back to the original source.
  struct SliceRemapper(T)
    @source : T
    @indexes : Array(Range(Int32, Int32))

    def initialize(@source : T, slices : Array(T))
      indexes = [] of Range(Int32, Int32)
      offset = 0
      slices.each do |item|
        start = offset
        offset += item.size
        indexes << (start...offset)
      end
      @indexes = indexes
    end

    def slice(range : Range(Int32, Int32)) : T?
      return if range.begin >= range.end
      start_range = @indexes[range.begin]?
      end_range = @indexes[range.end - 1]?
      return unless start_range && end_range
      @source.slice(start_range.begin...end_range.end)
    end
  end

  # Remaps diff ops to slices of the original source strings.
  class TextDiffRemapper(T)
    @old : SliceRemapper(T)
    @new : SliceRemapper(T)

    def initialize(old_slices : Array(T), new_slices : Array(T), old : T, new : T)
      @old = SliceRemapper(T).new(old, old_slices)
      @new = SliceRemapper(T).new(new, new_slices)
    end

    def self.from_text_diff(diff : Similar::TextDiff(T), old : T, new : T) : self
      new(diff.old_tokens, diff.new_tokens, old, new)
    end

    def slice_old(range : Range(Int32, Int32)) : T?
      @old.slice(range)
    end

    def slice_new(range : Range(Int32, Int32)) : T?
      @new.slice(range)
    end

    def iter_slices(op : DiffOp) : Array({ChangeTag, T})
      tag, old_range, new_range = op.as_tag_tuple
      case tag
      when DiffTag::Equal
        value = @old.slice(old_range)
        raise "slice out of bounds" unless value
        [{ChangeTag::Equal, value}]
      when DiffTag::Insert
        value = @new.slice(new_range)
        raise "slice out of bounds" unless value
        [{ChangeTag::Insert, value}]
      when DiffTag::Delete
        value = @old.slice(old_range)
        raise "slice out of bounds" unless value
        [{ChangeTag::Delete, value}]
      when DiffTag::Replace
        old_value = @old.slice(old_range)
        new_value = @new.slice(new_range)
        raise "slice out of bounds" unless old_value && new_value
        [{ChangeTag::Delete, old_value}, {ChangeTag::Insert, new_value}]
      else
        [] of {ChangeTag, T}
      end
    end
  end

  # Shortcut for diffing two slices.
  def self.diff_slices(alg : Algorithm, old : Array(T), new : Array(T)) : Array({ChangeTag, Array(T)}) forall T
    ops = Similar.capture_diff_slices(alg, old, new)
    changes = [] of {ChangeTag, Array(T)}
    ops.each do |op|
      tag, old_range, new_range = op.as_tag_tuple
      case tag
      when DiffTag::Equal
        changes << {ChangeTag::Equal, old[old_range]}
      when DiffTag::Insert
        changes << {ChangeTag::Insert, new[new_range]}
      when DiffTag::Delete
        changes << {ChangeTag::Delete, old[old_range]}
      when DiffTag::Replace
        changes << {ChangeTag::Delete, old[old_range]}
        changes << {ChangeTag::Insert, new[new_range]}
      end
    end
    changes
  end

  # Diff lines for strings.
  def self.diff_lines(alg : Algorithm, old : String, new : String) : Array({ChangeTag, String})
    diff = TextDiff.configure.algorithm(alg).diff_lines(old, new)
    diff.iter_all_changes.map { |change| {change.tag, change.value} }.to_a
  end

  # Diff lines for bytes.
  def self.diff_lines(alg : Algorithm, old : Bytes, new : Bytes) : Array({ChangeTag, BytesWrapper})
    diff = TextDiff.configure.algorithm(alg).diff_lines(old, new)
    diff.iter_all_changes.map { |change| {change.tag, change.value} }.to_a
  end

  # Diff words for strings.
  def self.diff_words(alg : Algorithm, old : String, new : String) : Array({ChangeTag, String})
    diff = TextDiff.configure.algorithm(alg).diff_words(old, new)
    diff.iter_all_changes.map { |change| {change.tag, change.value} }.to_a
  end

  # Diff words for bytes.
  def self.diff_words(alg : Algorithm, old : Bytes, new : Bytes) : Array({ChangeTag, BytesWrapper})
    diff = TextDiff.configure.algorithm(alg).diff_words(old, new)
    diff.iter_all_changes.map { |change| {change.tag, change.value} }.to_a
  end

  # Diff characters for strings.
  def self.diff_chars(alg : Algorithm, old : String, new : String) : Array({ChangeTag, String})
    diff = TextDiff.configure.algorithm(alg).diff_chars(old, new)
    diff.iter_all_changes.map { |change| {change.tag, change.value} }.to_a
  end

  # Diff bytes for bytes.
  def self.diff_chars(alg : Algorithm, old : Bytes, new : Bytes) : Array({ChangeTag, BytesWrapper})
    diff = TextDiff.configure.algorithm(alg).diff_chars(old, new)
    diff.iter_all_changes.map { |change| {change.tag, change.value} }.to_a
  end

  # Diff unicode words for strings.
  def self.diff_unicode_words(alg : Algorithm, old : String, new : String) : Array({ChangeTag, String})
    diff = TextDiff.configure.algorithm(alg).diff_unicode_words(old, new)
    diff.iter_all_changes.map { |change| {change.tag, change.value} }.to_a
  end

  # Diff graphemes for strings.
  def self.diff_graphemes(alg : Algorithm, old : String, new : String) : Array({ChangeTag, String})
    diff = TextDiff.configure.algorithm(alg).diff_graphemes(old, new)
    diff.iter_all_changes.map { |change| {change.tag, change.value} }.to_a
  end
end
