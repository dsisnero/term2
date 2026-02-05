require "./utils"
require "../deadline_support"
require "../types"

module Similar::Algorithms
  # LCS diff algorithm.
  #
  # * time: `O(NM)`
  # * space `O(NM)`
  #
  # This is an implementation of the standard longest common subsequence
  # algorithm using dynamic programming.  It's primarily here for completeness
  # and will perform worse than both Myers and Patience in pretty much all cases.
  module Lcs
    # LCS diff algorithm.
    #
    # Diff `old`, between indices `old_range` and `new` between indices `new_range`.
    def self.diff(old, old_range : Range(Int32, Int32), new, new_range : Range(Int32, Int32),
                  d : DiffHook) : Nil
      diff_deadline(old, old_range, new, new_range, d, nil)
    end

    # LCS diff algorithm with deadline.
    #
    # Diff `old`, between indices `old_range` and `new` between indices `new_range`.
    #
    # This diff is done with an optional deadline that defines the maximal
    # execution time permitted before it bails and falls back to an approximation.
    def self.diff_deadline(old, old_range : Range(Int32, Int32), new, new_range : Range(Int32, Int32),
                           d : DiffHook, deadline : Similar::DeadlineSupport::Instant? = nil) : Nil
      if Similar::Algorithms.is_empty_range(new_range)
        d.delete(old_range.begin, old_range.size, new_range.begin)
        d.finish
        return
      elsif Similar::Algorithms.is_empty_range(old_range)
        d.insert(old_range.begin, new_range.begin, new_range.size)
        d.finish
        return
      end

      common_prefix_len = Similar::Algorithms.common_prefix_len(old, old_range, new, new_range)
      common_suffix_len = Similar::Algorithms.common_suffix_len(
        old,
        old_range.begin + common_prefix_len...old_range.end,
        new,
        new_range.begin + common_prefix_len...new_range.end
      )

      # If the sequences are not different then we're done
      if common_prefix_len == old_range.size && old_range.size == new_range.size
        d.equal(old_range.begin, new_range.begin, old_range.size)
        d.finish
        return
      end

      old_start = old_range.begin + common_prefix_len
      old_end = old_range.end - common_suffix_len
      new_start = new_range.begin + common_prefix_len
      new_end = new_range.end - common_suffix_len

      old_len = old_end - old_start
      new_len = new_end - new_start

      maybe_table = make_table(
        old,
        old_start...old_end,
        new,
        new_start...new_end,
        deadline
      )

      old_idx = 0
      new_idx = 0

      if common_prefix_len > 0
        d.equal(old_range.begin, new_range.begin, common_prefix_len)
      end

      if table = maybe_table
        while new_idx < new_len && old_idx < old_len
          old_orig_idx = old_start + old_idx
          new_orig_idx = new_start + new_idx

          if new[new_orig_idx] == old[old_orig_idx]
            d.equal(old_orig_idx, new_orig_idx, 1)
            old_idx += 1
            new_idx += 1
          elsif table.fetch({new_idx, old_idx + 1}, 0) >= table.fetch({new_idx + 1, old_idx}, 0)
            d.delete(old_orig_idx, 1, new_orig_idx)
            old_idx += 1
          else
            d.insert(old_orig_idx, new_orig_idx, 1)
            new_idx += 1
          end
        end
      else
        old_orig_idx = old_start
        new_orig_idx = new_start
        d.delete(old_orig_idx, old_len, new_orig_idx)
        d.insert(old_orig_idx, new_orig_idx, new_len)
        old_idx = old_len
        new_idx = new_len
      end

      if old_idx < old_len
        d.delete(
          old_start + old_idx,
          old_len - old_idx,
          new_start + new_idx
        )
        old_idx = old_len
      end

      if new_idx < new_len
        d.insert(
          old_start + old_idx,
          new_start + new_idx,
          new_len - new_idx
        )
      end

      if common_suffix_len > 0
        d.equal(
          old_start + old_len,
          new_start + new_len,
          common_suffix_len
        )
      end

      d.finish
    end

    private def self.make_table(old, old_range : Range(Int32, Int32), new, new_range : Range(Int32, Int32),
                                deadline : Similar::DeadlineSupport::Instant?)
      old_len = old_range.size
      new_len = new_range.size
      table = Hash({Int32, Int32}, Int32).new

      (0...new_len).reverse_each do |i|
        # are we running for too long? give up on the table
        if deadline_exceeded(deadline)
          return
        end

        (0...old_len).reverse_each do |j|
          val = if new[new_range.begin + i] == old[old_range.begin + j]
                  table.fetch({i + 1, j + 1}, 0) + 1
                else
                  Math.max(table.fetch({i + 1, j}, 0), table.fetch({i, j + 1}, 0))
                end
          if val > 0
            table[{i, j}] = val
          end
        end
      end

      table
    end

    private def self.deadline_exceeded(deadline : Similar::DeadlineSupport::Instant?)
      Similar::DeadlineSupport.deadline_exceeded(deadline)
    end
  end
end
