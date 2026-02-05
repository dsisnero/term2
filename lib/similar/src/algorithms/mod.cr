# Various diff (longest common subsequence) algorithms.
#
# The implementations of the algorithms in this module are relatively low
# level and expose the most generic bounds possible for the algorithm.  To
# use them you would typically use the higher level API if possible but
# direct access to these algorithms can be useful in some cases.
#
# All these algorithms provide a `diff` function which takes two indexable
# objects (for instance slices) and a `DiffHook`.  As the
# diff is generated the diff hook is invoked.  Note that the diff hook does
# not get access to the actual values but only the indexes.  This is why the
# diff hook is not used outside of the raw algorithm implementations as for
# most situations access to the values is useful of required.
#
# The algorithms module really is the most low-level module in similar and
# generally not the place to start.
#
# # Example
#
# This is a simple example that shows how you can calculate the difference
# between two sequences and capture the ops into a vector.
#
# ```
# require "similar"
#
# a = [1, 2, 3, 4, 5]
# b = [1, 2, 3, 4, 7]
# d = Similar::Algorithms::Replace.new(Similar::Algorithms::Capture.new)
# Similar::Algorithms::diff_slices(Similar::Algorithm::Myers, d, a, b)
# ops = d.inner.ops
# ```
#
# The above example is equivalent to using `Similar.capture_diff_slices`.

# First, define the core DiffHook types
module Similar::Algorithms
  # A trait for reacting to an edit script from the "old" version to
  # the "new" version.
  abstract class DiffHook
    # Called when lines with indices `old_index` (in the old version) and
    # `new_index` (in the new version) start an section equal in both
    # versions, of length `len`.
    def equal(old_index : Int32, new_index : Int32, len : Int32) : Nil
    end

    # Called when a section of length `old_len`, starting at `old_index`,
    # needs to be deleted from the old version.
    def delete(old_index : Int32, old_len : Int32, new_index : Int32) : Nil
    end

    # Called when a section of the new version, of length `new_len`
    # and starting at `new_index`, needs to be inserted at position `old_index`.
    def insert(old_index : Int32, new_index : Int32, new_len : Int32) : Nil
    end

    # Called when a section of the old version, starting at index
    # `old_index` and of length `old_len`, needs to be replaced with a
    # section of length `new_len`, starting at `new_index`, of the new
    # version.
    #
    # The default implementations invokes `delete` and `insert`.
    #
    # You can use the `Replace` hook to automatically generate these.
    def replace(old_index : Int32, old_len : Int32, new_index : Int32, new_len : Int32) : Nil
      delete(old_index, old_len, new_index)
      insert(old_index, new_index, new_len)
    end

    # Always called at the end of the algorithm.
    def finish : Nil
    end
  end

  # Wrapper `DiffHook` that prevents calls to `DiffHook.finish`.
  #
  # This hook is useful in situations where diff hooks are composed but you
  # want to prevent that the finish hook method is called.
  class NoFinishHook(D) < DiffHook
    @hook : D

    # Wraps another hook.
    def initialize(@hook : D)
    end

    # Extracts the inner hook.
    def inner : D
      @hook
    end

    def equal(old_index : Int32, new_index : Int32, len : Int32) : Nil
      @hook.equal(old_index, new_index, len)
    end

    def delete(old_index : Int32, old_len : Int32, new_index : Int32) : Nil
      @hook.delete(old_index, old_len, new_index)
    end

    def insert(old_index : Int32, new_index : Int32, new_len : Int32) : Nil
      @hook.insert(old_index, new_index, new_len)
    end

    def replace(old_index : Int32, old_len : Int32, new_index : Int32, new_len : Int32) : Nil
      @hook.replace(old_index, old_len, new_index, new_len)
    end

    def finish : Nil
      # No-op, prevents calling finish on inner hook
    end
  end
end

# Now load the concrete hook implementations and algorithms
require "./capture"
require "./replace"
require "./compact"
require "./utils"
require "./myers"
require "./patience"
require "./lcs"

# Reopen module to add the high-level API methods
module Similar::Algorithms
  # Creates a diff between old and new with the given algorithm.
  #
  # Diffs `old`, between indices `old_range` and `new` between indices `new_range`.
  def self.diff(alg : Similar::Algorithm, d : DiffHook, old, old_range : Range(Int32, Int32), new, new_range : Range(Int32, Int32)) : Nil
    diff_deadline(alg, d, old, old_range, new, new_range, nil)
  end

  # Creates a diff between old and new with the given algorithm with deadline.
  #
  # Diffs `old`, between indices `old_range` and `new` between indices `new_range`.
  #
  # This diff is done with an optional deadline that defines the maximal
  # execution time permitted before it bails and falls back to an approximation.
  # Note that not all algorithms behave well if they reach the deadline (LCS
  # for instance produces a very simplistic diff when the deadline is reached
  # in all cases).
  def self.diff_deadline(alg : Similar::Algorithm, d : DiffHook, old, old_range : Range(Int32, Int32), new, new_range : Range(Int32, Int32), deadline = nil) : Nil
    case alg
    when Similar::Algorithm::Myers
      Myers.diff_deadline(old, old_range, new, new_range, d, deadline)
    when Similar::Algorithm::Patience
      Patience.diff_deadline(old, old_range, new, new_range, d, deadline)
    when Similar::Algorithm::Lcs
      Lcs.diff_deadline(old, old_range, new, new_range, d, deadline)
    else
      raise "Unknown algorithm"
    end
  end

  # Shortcut for diffing slices with a specific algorithm.
  def self.diff_slices(alg : Similar::Algorithm, d : DiffHook, old : Array, new : Array) : Nil
    diff(alg, d, old, 0...old.size, new, 0...new.size)
  end

  # Shortcut for diffing slices with a specific algorithm.
  def self.diff_slices_deadline(alg : Similar::Algorithm, d : DiffHook, old : Array, new : Array, deadline = nil) : Nil
    diff_deadline(alg, d, old, 0...old.size, new, 0...new.size, deadline)
  end
end
