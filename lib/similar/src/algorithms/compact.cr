require "./mod"
require "../types"

module Similar::Algorithms
  # A `DiffHook` that reduces the size of diff by simplifying complex
  # change patterns.
  #
  # This hook attempts to reduce the number of diff operations by merging
  # adjacent operations and simplifying complex change patterns.  It's
  # primarily used internally to clean up diff results.
  class Compact(D, Old, New) < DiffHook
    @d : D
    @ops : Array(DiffOp)
    @old : Old
    @new : New

    # Creates a new compact hook wrapping another hook.
    def initialize(@d : D, @old : Old, @new : New)
      @ops = [] of DiffOp
    end

    # Extracts the inner hook.
    def inner : D
      @d
    end

    def equal(old_index : Int32, new_index : Int32, len : Int32) : Nil
      @ops << DiffOp::Equal.new(old_index, new_index, len)
    end

    def delete(old_index : Int32, old_len : Int32, new_index : Int32) : Nil
      @ops << DiffOp::Delete.new(old_index, old_len, new_index)
    end

    def insert(old_index : Int32, new_index : Int32, new_len : Int32) : Nil
      @ops << DiffOp::Insert.new(old_index, new_index, new_len)
    end

    def replace(old_index : Int32, old_len : Int32, new_index : Int32, new_len : Int32) : Nil
      @ops << DiffOp::Replace.new(old_index, old_len, new_index, new_len)
    end

    def finish : Nil
      cleanup_diff_ops(@old, @new, @ops)
      @ops.each do |op|
        op.apply_to_hook(@d)
      end
      @d.finish
    end

    private def cleanup_diff_ops(old, new, ops : Array(DiffOp)) : Nil
      # First attempt to compact all deletions.
      pointer = 0
      while pointer < ops.size
        if ops[pointer].tag == DiffTag::Delete
          pointer = shift_diff_ops_up(ops, old, new, pointer)
          pointer = shift_diff_ops_down(ops, old, new, pointer)
        end
        pointer += 1
      end

      # Then attempt to compact all insertions.
      pointer = 0
      while pointer < ops.size
        if ops[pointer].tag == DiffTag::Insert
          pointer = shift_diff_ops_up(ops, old, new, pointer)
          pointer = shift_diff_ops_down(ops, old, new, pointer)
        end
        pointer += 1
      end
    end

    private def range_len(range : Range(Int32, Int32)) : Int32
      range.end - range.begin
    end

    private def shift_diff_ops_up(ops : Array(DiffOp), old, new, pointer : Int32) : Int32
      while pointer > 0
        prev_op = ops[pointer - 1]
        this_op = ops[pointer]
        case {this_op.tag, prev_op.tag}
        when {DiffTag::Insert, DiffTag::Equal}
          suffix_len = Similar::Algorithms.common_suffix_len(old, prev_op.old_range, new, this_op.new_range)
          if suffix_len > 0
            if pointer + 1 < ops.size && ops[pointer + 1].tag == DiffTag::Equal
              ops[pointer + 1].grow_left(suffix_len)
            else
              ops.insert(
                pointer + 1,
                DiffOp::Equal.new(
                  prev_op.old_range.end - suffix_len,
                  this_op.new_range.end - suffix_len,
                  suffix_len
                )
              )
            end
            ops[pointer].shift_left(suffix_len)
            ops[pointer - 1].shrink_left(suffix_len)

            if ops[pointer - 1].empty?
              ops.delete_at(pointer - 1)
              pointer -= 1
            end
          elsif ops[pointer - 1].empty?
            ops.delete_at(pointer - 1)
            pointer -= 1
          else
            break
          end
        when {DiffTag::Delete, DiffTag::Equal}
          suffix_len = Similar::Algorithms.common_suffix_len(old, prev_op.old_range, new, this_op.new_range)
          if suffix_len != 0
            if pointer + 1 < ops.size && ops[pointer + 1].tag == DiffTag::Equal
              ops[pointer + 1].grow_left(suffix_len)
            else
              old_range = prev_op.old_range
              ops.insert(
                pointer + 1,
                DiffOp::Equal.new(
                  old_range.end - suffix_len,
                  this_op.new_range.end - suffix_len,
                  range_len(old_range) - suffix_len
                )
              )
            end
            ops[pointer].shift_left(suffix_len)
            ops[pointer - 1].shrink_left(suffix_len)

            if ops[pointer - 1].empty?
              ops.delete_at(pointer - 1)
              pointer -= 1
            end
          elsif ops[pointer - 1].empty?
            ops.delete_at(pointer - 1)
            pointer -= 1
          else
            break
          end
        when {DiffTag::Insert, DiffTag::Delete}, {DiffTag::Delete, DiffTag::Insert}
          ops[pointer - 1], ops[pointer] = ops[pointer], ops[pointer - 1]
          pointer -= 1
        when {DiffTag::Insert, DiffTag::Insert}
          ops[pointer - 1].grow_right(range_len(this_op.new_range))
          ops.delete_at(pointer)
          pointer -= 1
        when {DiffTag::Delete, DiffTag::Delete}
          ops[pointer - 1].grow_right(range_len(this_op.old_range))
          ops.delete_at(pointer)
          pointer -= 1
        else
          break
        end
      end
      pointer
    end

    private def shift_diff_ops_down(ops : Array(DiffOp), old, new, pointer : Int32) : Int32
      while pointer + 1 < ops.size
        next_op = ops[pointer + 1]
        this_op = ops[pointer]
        case {this_op.tag, next_op.tag}
        when {DiffTag::Insert, DiffTag::Equal}
          prefix_len = Similar::Algorithms.common_prefix_len(old, next_op.old_range, new, this_op.new_range)
          if prefix_len > 0
            if pointer > 0 && ops[pointer - 1].tag == DiffTag::Equal
              ops[pointer - 1].grow_right(prefix_len)
            else
              ops.insert(
                pointer,
                DiffOp::Equal.new(
                  next_op.old_range.begin,
                  this_op.new_range.begin,
                  prefix_len
                )
              )
              pointer += 1
            end
            ops[pointer].shift_right(prefix_len)
            ops[pointer + 1].shrink_right(prefix_len)

            if ops[pointer + 1].empty?
              ops.delete_at(pointer + 1)
            end
          elsif ops[pointer + 1].empty?
            ops.delete_at(pointer + 1)
          else
            break
          end
        when {DiffTag::Delete, DiffTag::Equal}
          prefix_len = Similar::Algorithms.common_prefix_len(old, next_op.old_range, new, this_op.new_range)
          if prefix_len > 0
            if pointer > 0 && ops[pointer - 1].tag == DiffTag::Equal
              ops[pointer - 1].grow_right(prefix_len)
            else
              ops.insert(
                pointer,
                DiffOp::Equal.new(
                  next_op.old_range.begin,
                  this_op.new_range.begin,
                  prefix_len
                )
              )
              pointer += 1
            end
            ops[pointer].shift_right(prefix_len)
            ops[pointer + 1].shrink_right(prefix_len)

            if ops[pointer + 1].empty?
              ops.delete_at(pointer + 1)
            end
          elsif ops[pointer + 1].empty?
            ops.delete_at(pointer + 1)
          else
            break
          end
        when {DiffTag::Insert, DiffTag::Delete}, {DiffTag::Delete, DiffTag::Insert}
          ops[pointer], ops[pointer + 1] = ops[pointer + 1], ops[pointer]
          pointer += 1
        when {DiffTag::Insert, DiffTag::Insert}
          ops[pointer].grow_right(range_len(next_op.new_range))
          ops.delete_at(pointer + 1)
        when {DiffTag::Delete, DiffTag::Delete}
          ops[pointer].grow_right(range_len(next_op.old_range))
          ops.delete_at(pointer + 1)
        else
          break
        end
      end
      pointer
    end

    # Extracts the inner hook.
    def into_inner : D
      @d
    end
  end
end
