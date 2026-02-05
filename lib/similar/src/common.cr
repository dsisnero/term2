require "./types"
require "./algorithms/mod"

module Similar
  # Creates a diff between old and new with the given algorithm capturing the ops.
  #
  # This is like `diff` but instead of using an
  # arbitrary hook this will always use `Compact` + `Replace` + `Capture`
  # and return the captured `DiffOp`s.
  def self.capture_diff(alg : Algorithm,
                        old, old_range : Range(Int32, Int32),
                        new, new_range : Range(Int32, Int32)) : Array(DiffOp)
    capture_diff_deadline(alg, old, old_range, new, new_range, nil)
  end

  # Creates a diff between old and new with the given algorithm capturing the ops.
  #
  # Works like `capture_diff` but with an optional deadline.
  def self.capture_diff_deadline(alg : Algorithm,
                                 old, old_range : Range(Int32, Int32),
                                 new, new_range : Range(Int32, Int32),
                                 deadline = nil) : Array(DiffOp)
    d = Algorithms::Compact.new(Algorithms::Replace.new(Algorithms::Capture.new), old, new)
    Algorithms.diff_deadline(alg, d, old, old_range, new, new_range, deadline)
    d.into_inner.inner.ops
  end

  # Creates a diff between old and new with the given algorithm capturing the ops.
  def self.capture_diff_slices(alg : Algorithm, old, new) : Array(DiffOp)
    capture_diff_slices_deadline(alg, old, new, nil)
  end

  # Creates a diff between old and new with the given algorithm capturing the ops.
  #
  # Works like `capture_diff_slices` but with an optional deadline.
  def self.capture_diff_slices_deadline(alg : Algorithm, old, new, deadline = nil) : Array(DiffOp)
    capture_diff_deadline(alg, old, 0...old.size, new, 0...new.size, deadline)
  end

  # Return a measure of similarity in the range `0..=1`.
  #
  # A ratio of `1.0` means the two sequences are a complete match, a
  # ratio of `0.0` would indicate completely distinct sequences.  The input
  # is the sequence of diff operations and the length of the old and new
  # sequence.
  def self.get_diff_ratio(ops : Array(DiffOp), old_len : Int32, new_len : Int32) : Float32
    matches = ops.sum do |op|
      if op.is_a?(DiffOp::Equal)
        op.len
      else
        0
      end
    end
    len = old_len + new_len
    if len == 0
      1.0_f32
    else
      2.0_f32 * matches / len
    end
  end

  # Isolate change clusters by eliminating ranges with no changes.
  #
  # This will leave holes behind in long periods of equal ranges so that
  # you can build things like unified diffs.
  def self.group_diff_ops(ops : Array(DiffOp), n : Int32) : Array(Array(DiffOp))
    return [] of Array(DiffOp) if ops.empty?

    # Create a mutable copy of ops
    ops = ops.dup
    pending_group = [] of DiffOp
    rv = [] of Array(DiffOp)

    # Adjust first equal op
    if first = ops.first
      if first.is_a?(DiffOp::Equal)
        offset = Math.max(0, first.len - n)
        if offset > 0
          ops[0] = DiffOp::Equal.new(first.old_index + offset, first.new_index + offset, first.len - offset)
        end
      end
    end

    # Adjust last equal op
    if last = ops.last
      if last.is_a?(DiffOp::Equal)
        trim = Math.max(0, last.len - n)
        if trim > 0
          ops[-1] = DiffOp::Equal.new(last.old_index, last.new_index, last.len - trim)
        end
      end
    end

    ops.each do |op|
      if op.is_a?(DiffOp::Equal)
        old_index = op.old_index
        new_index = op.new_index
        len = op.len
        # End the current group and start a new one whenever
        # there is a large range with no changes.
        if len > n * 2
          pending_group << DiffOp::Equal.new(old_index, new_index, n)
          rv << pending_group
          offset = Math.max(0, len - n)
          pending_group = [] of DiffOp
          pending_group << DiffOp::Equal.new(old_index + offset, new_index + offset, len - offset)
          next
        end
      end
      pending_group << op
    end

    if pending_group.empty?
      # nothing
    elsif pending_group.size == 1 && pending_group[0].is_a?(DiffOp::Equal)
      # nothing
    else
      rv << pending_group
    end

    rv
  end
end
