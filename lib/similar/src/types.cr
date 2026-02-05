require "json"

module Similar
  # An enum representing a diffing algorithm.
  enum Algorithm
    # Picks the myers algorithm from `Similar::Algorithms::Myers`
    Myers
    # Picks the patience algorithm from `Similar::Algorithms::Patience`
    Patience
    # Picks the LCS algorithm from `Similar::Algorithms::LCS`
    Lcs
  end

  # The tag of a change.
  enum ChangeTag
    # The change indicates equality (not a change)
    Equal
    # The change indicates deleted text.
    Delete
    # The change indicates inserted text.
    Insert

    # Returns the unified diff character for this tag.
    def to_char : Char
      case self
      when Equal  then ' '
      when Delete then '-'
      when Insert then '+'
      else
        raise "Unexpected ChangeTag value"
      end
    end
  end

  # The tag of a diff operation.
  enum DiffTag
    # The diff op encodes an equal segment.
    Equal
    # The diff op encodes a deleted segment.
    Delete
    # The diff op encodes an inserted segment.
    Insert
    # The diff op encodes a replaced segment.
    Replace
  end

  # Alias for diff hook from algorithms module
  alias DiffHook = Algorithms::DiffHook

  # Abstract base class for diff operations.
  abstract class DiffOp
    # Returns the tag of the operation.
    abstract def tag : DiffTag

    # Returns the old range.
    abstract def old_range : Range(Int32, Int32)

    # Returns the new range.
    abstract def new_range : Range(Int32, Int32)

    # Transform the op into a tuple of diff tag and ranges.
    #
    # This is useful when operating on slices. The returned format is
    # `(tag, i1..i2, j1..j2)`:
    #
    # * `Replace`: `a[i1..i2]` should be replaced by `b[j1..j2]`
    # * `Delete`: `a[i1..i2]` should be deleted (`j1 == j2` in this case).
    # * `Insert`: `b[j1..j2]` should be inserted at `a[i1..i2]` (`i1 == i2` in this case).
    # * `Equal`: `a[i1..i2]` is equal to `b[j1..j2]`.
    def as_tag_tuple : Tuple(DiffTag, Range(Int32, Int32), Range(Int32, Int32))
      {tag, old_range, new_range}
    end

    # Returns an iterator over the changes this operation expands to.
    #
    # This method is a convenient way to automatically resolve the different
    # ways in which a change could be encoded (insert/delete vs replace), look
    # up the value from the appropriate slice and also handle correct index
    # handling.
    def iter_changes(old, new)
      ChangesIter(typeof(old), typeof(new), typeof(old[0])).new(old, new, self)
    end

    # Apply this operation to a diff hook.
    abstract def apply_to_hook(d : DiffHook) : Nil

    # Returns true if the operation is empty (both ranges empty).
    def empty? : Bool
      old_range.begin == old_range.end && new_range.begin == new_range.end
    end

    # Shifts the operation left by adjusting indices.
    abstract def shift_left(adjust : Int32) : Nil

    # Shifts the operation right by adjusting indices.
    abstract def shift_right(adjust : Int32) : Nil

    # Grows the operation on the left.
    abstract def grow_left(adjust : Int32) : Nil

    # Grows the operation on the right.
    abstract def grow_right(adjust : Int32) : Nil

    # Shrinks the operation on the left.
    abstract def shrink_left(adjust : Int32) : Nil

    # Shrinks the operation on the right.
    abstract def shrink_right(adjust : Int32) : Nil
  end

  # A segment is equal.
  class DiffOp::Equal < DiffOp
    include JSON::Serializable
    getter old_index : Int32
    getter new_index : Int32
    getter len : Int32

    def initialize(@old_index, @new_index, @len)
    end

    def tag : DiffTag
      DiffTag::Equal
    end

    def old_range : Range(Int32, Int32)
      @old_index...(@old_index + @len)
    end

    def new_range : Range(Int32, Int32)
      @new_index...(@new_index + @len)
    end

    def apply_to_hook(d : DiffHook) : Nil
      d.equal(@old_index, @new_index, @len)
    end

    def shift_left(adjust : Int32) : Nil
      apply_adjust(adjust, true, 0, false)
    end

    def shift_right(adjust : Int32) : Nil
      apply_adjust(adjust, false, 0, false)
    end

    def grow_left(adjust : Int32) : Nil
      apply_adjust(adjust, true, adjust, false)
    end

    def grow_right(adjust : Int32) : Nil
      apply_adjust(0, false, adjust, false)
    end

    def shrink_left(adjust : Int32) : Nil
      apply_adjust(0, false, adjust, true)
    end

    def shrink_right(adjust : Int32) : Nil
      apply_adjust(adjust, false, adjust, true)
    end

    private def apply_adjust(offset_delta : Int32, offset_subtract : Bool,
                             len_delta : Int32, len_subtract : Bool) : Nil
      if offset_subtract
        @old_index -= offset_delta
        @new_index -= offset_delta
      else
        @old_index += offset_delta
        @new_index += offset_delta
      end

      if len_subtract
        @len -= len_delta
      else
        @len += len_delta
      end
    end

    def_equals_and_hash @old_index, @new_index, @len
  end

  # A segment was deleted.
  class DiffOp::Delete < DiffOp
    include JSON::Serializable
    getter old_index : Int32
    getter old_len : Int32
    getter new_index : Int32

    def initialize(@old_index, @old_len, @new_index)
    end

    def tag : DiffTag
      DiffTag::Delete
    end

    def old_range : Range(Int32, Int32)
      @old_index...(@old_index + @old_len)
    end

    def new_range : Range(Int32, Int32)
      @new_index...@new_index
    end

    def apply_to_hook(d : DiffHook) : Nil
      d.delete(@old_index, @old_len, @new_index)
    end

    def shift_left(adjust : Int32) : Nil
      apply_adjust(adjust, true, 0, false)
    end

    def shift_right(adjust : Int32) : Nil
      apply_adjust(adjust, false, 0, false)
    end

    def grow_left(adjust : Int32) : Nil
      apply_adjust(adjust, true, adjust, false)
    end

    def grow_right(adjust : Int32) : Nil
      apply_adjust(0, false, adjust, false)
    end

    def shrink_left(adjust : Int32) : Nil
      apply_adjust(0, false, adjust, true)
    end

    def shrink_right(adjust : Int32) : Nil
      apply_adjust(adjust, false, adjust, true)
    end

    private def apply_adjust(offset_delta : Int32, offset_subtract : Bool,
                             len_delta : Int32, len_subtract : Bool) : Nil
      if offset_subtract
        @old_index -= offset_delta
        @new_index -= offset_delta
      else
        @old_index += offset_delta
        @new_index += offset_delta
      end

      if len_subtract
        @old_len -= len_delta
      else
        @old_len += len_delta
      end
    end

    def_equals_and_hash @old_index, @old_len, @new_index
  end

  # A segment was inserted.
  class DiffOp::Insert < DiffOp
    include JSON::Serializable
    getter old_index : Int32
    getter new_index : Int32
    getter new_len : Int32

    def initialize(@old_index, @new_index, @new_len)
    end

    def tag : DiffTag
      DiffTag::Insert
    end

    def old_range : Range(Int32, Int32)
      @old_index...@old_index
    end

    def new_range : Range(Int32, Int32)
      @new_index...(@new_index + @new_len)
    end

    def apply_to_hook(d : DiffHook) : Nil
      d.insert(@old_index, @new_index, @new_len)
    end

    def shift_left(adjust : Int32) : Nil
      apply_adjust(adjust, true, 0, false)
    end

    def shift_right(adjust : Int32) : Nil
      apply_adjust(adjust, false, 0, false)
    end

    def grow_left(adjust : Int32) : Nil
      apply_adjust(adjust, true, adjust, false)
    end

    def grow_right(adjust : Int32) : Nil
      apply_adjust(0, false, adjust, false)
    end

    def shrink_left(adjust : Int32) : Nil
      apply_adjust(0, false, adjust, true)
    end

    def shrink_right(adjust : Int32) : Nil
      apply_adjust(adjust, false, adjust, true)
    end

    private def apply_adjust(offset_delta : Int32, offset_subtract : Bool,
                             len_delta : Int32, len_subtract : Bool) : Nil
      if offset_subtract
        @old_index -= offset_delta
        @new_index -= offset_delta
      else
        @old_index += offset_delta
        @new_index += offset_delta
      end

      if len_subtract
        @new_len -= len_delta
      else
        @new_len += len_delta
      end
    end

    def_equals_and_hash @old_index, @new_index, @new_len
  end

  # A segment was replaced.
  class DiffOp::Replace < DiffOp
    include JSON::Serializable
    getter old_index : Int32
    getter old_len : Int32
    getter new_index : Int32
    getter new_len : Int32

    def initialize(@old_index, @old_len, @new_index, @new_len)
    end

    def tag : DiffTag
      DiffTag::Replace
    end

    def old_range : Range(Int32, Int32)
      @old_index...(@old_index + @old_len)
    end

    def new_range : Range(Int32, Int32)
      @new_index...(@new_index + @new_len)
    end

    def apply_to_hook(d : DiffHook) : Nil
      d.replace(@old_index, @old_len, @new_index, @new_len)
    end

    def shift_left(adjust : Int32) : Nil
      apply_adjust(adjust, true, 0, false)
    end

    def shift_right(adjust : Int32) : Nil
      apply_adjust(adjust, false, 0, false)
    end

    def grow_left(adjust : Int32) : Nil
      apply_adjust(adjust, true, adjust, false)
    end

    def grow_right(adjust : Int32) : Nil
      apply_adjust(0, false, adjust, false)
    end

    def shrink_left(adjust : Int32) : Nil
      apply_adjust(0, false, adjust, true)
    end

    def shrink_right(adjust : Int32) : Nil
      apply_adjust(adjust, false, adjust, true)
    end

    private def apply_adjust(offset_delta : Int32, offset_subtract : Bool,
                             len_delta : Int32, len_subtract : Bool) : Nil
      if offset_subtract
        @old_index -= offset_delta
        @new_index -= offset_delta
      else
        @old_index += offset_delta
        @new_index += offset_delta
      end

      if len_subtract
        @old_len -= len_delta
        @new_len -= len_delta
      else
        @old_len += len_delta
        @new_len += len_delta
      end
    end

    def_equals_and_hash @old_index, @old_len, @new_index, @new_len
  end

  # Represents the expanded `DiffOp` change.
  #
  # This type exists so that it's more convenient to work with textual differences as
  # the underlying `DiffOp` encodes a group of changes.
  class Change(T)
    include JSON::Serializable
    getter tag : ChangeTag
    getter old_index : Int32?
    getter new_index : Int32?
    getter value : T

    def initialize(@tag, @old_index, @new_index, @value)
    end

    # Returns the underlying changed value as reference.
    def value_ref : T
      @value
    end

    # Returns the underlying changed value as mutable reference.
    def value_mut : T
      @value
    end

    def_equals_and_hash @tag, @old_index, @new_index, @value
  end
end
