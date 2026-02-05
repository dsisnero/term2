require "./utils"
require "./myers"
require "./replace"
require "../deadline_support"
require "../types"

module Similar::Algorithms
  # Patience diff algorithm.
  #
  # * time: `O(N log N + M log M + (N+M)D)`
  # * space: `O(N+M)`
  #
  # Tends to give more human-readable outputs. See [Bram Cohen's blog
  # post](https://bramcohen.livejournal.com/73318.html) describing it.
  #
  # This is based on the patience implementation of [pijul](https://pijul.org/)
  # by Pierre-Étienne Meunier.
  module Patience
    # Patience diff algorithm.
    #
    # Diff `old`, between indices `old_range` and `new` between indices `new_range`.
    def self.diff(old, old_range : Range(Int32, Int32), new, new_range : Range(Int32, Int32),
                  d : DiffHook) : Nil
      diff_deadline(old, old_range, new, new_range, d, nil)
    end

    # Patience diff algorithm with deadline.
    #
    # Diff `old`, between indices `old_range` and `new` between indices `new_range`.
    #
    # This diff is done with an optional deadline that defines the maximal
    # execution time permitted before it bails and falls back to an approximation.
    def self.diff_deadline(old, old_range : Range(Int32, Int32), new, new_range : Range(Int32, Int32),
                           d : DiffHook, deadline : Similar::DeadlineSupport::Instant? = nil) : Nil
      old_indexes = Similar::Algorithms.unique(old, old_range)
      new_indexes = Similar::Algorithms.unique(new, new_range)

      hook = PatienceHook.new(d, old, old_range.begin, old_range.end, old_indexes,
        new, new_range.begin, new_range.end, new_indexes, deadline)
      d2 = Replace.new(hook)
      Myers.diff_deadline(old_indexes, 0...old_indexes.size, new_indexes, 0...new_indexes.size, d2, deadline)
    end

    # Internal hook that maps unique item indices back to original indices.
    private class PatienceHook(D, Old, New) < DiffHook
      @d : D
      @old : Old
      @old_current : Int32
      @old_end : Int32
      @old_indexes : Array(Similar::Algorithms::UniqueItem(Old))
      @new : New
      @new_current : Int32
      @new_end : Int32
      @new_indexes : Array(Similar::Algorithms::UniqueItem(New))
      @deadline : Similar::DeadlineSupport::Instant?

      def initialize(@d : D, @old : Old, old_current : Int32, old_end : Int32,
                     @old_indexes : Array(Similar::Algorithms::UniqueItem(Old)),
                     @new : New, new_current : Int32, new_end : Int32,
                     @new_indexes : Array(Similar::Algorithms::UniqueItem(New)), @deadline : Similar::DeadlineSupport::Instant?)
        @old_current = old_current
        @old_end = old_end
        @new_current = new_current
        @new_end = new_end
      end

      def equal(old_idx : Int32, new_idx : Int32, len : Int32) : Nil
        (0...len).each do |i|
          old = old_idx + i
          new = new_idx + i
          a0 = @old_current
          b0 = @new_current
          while @old_current < @old_indexes[old].original_index &&
                @new_current < @new_indexes[new].original_index &&
                @new[@new_current] == @old[@old_current]
            @old_current += 1
            @new_current += 1
          end
          if @old_current > a0
            @d.equal(a0, b0, @old_current - a0)
          end
          no_finish_d = NoFinishHook.new(@d)
          Myers.diff_deadline(@old, @old_current...@old_indexes[old].original_index,
            @new, @new_current...@new_indexes[new].original_index, no_finish_d, @deadline)
          @old_current = @old_indexes[old].original_index
          @new_current = @new_indexes[new].original_index
        end
      end

      def finish : Nil
        Myers.diff_deadline(@old, @old_current...@old_end,
          @new, @new_current...@new_end, @d, @deadline)
      end
    end
  end
end
