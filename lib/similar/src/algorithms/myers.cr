require "./utils"
require "../deadline_support"
require "../types"

module Similar::Algorithms
  # Myers' diff algorithm.
  #
  # * time: `O((N+M)D)`
  # * space `O(N+M)`
  #
  # See [the original article by Eugene W. Myers](http://www.xmailserver.org/diff2.pdf)
  # describing it.
  #
  # The implementation of this algorithm is based on the implementation by
  # Brandon Williams.
  #
  # # Heuristics
  #
  # At present this implementation of Myers' does not implement any more advanced
  # heuristics that would solve some pathological cases.  For instance passing two
  # large and completely distinct sequences to the algorithm will make it spin
  # without making reasonable progress.  Currently the only protection in the
  # library against this is to pass a deadline to the diffing algorithm.
  #
  # For potential improvements here see [similar#15](https://github.com/mitsuhiko/similar/issues/15).
  module Myers
    # `V` contains the endpoints of the furthest reaching `D-paths`. For each
    # recorded endpoint `(x,y)` in diagonal `k`, we only need to retain `x` because
    # `y` can be computed from `x - k`. In other words, `V` is an array of integers
    # where `V[k]` contains the row index of the endpoint of the furthest reaching
    # path in diagonal `k`.
    #
    # We can't use a traditional Vec to represent `V` since we use `k` as an index
    # and it can take on negative values. So instead `V` is represented as a
    # light-weight wrapper around a Vec plus an `offset` which is the maximum value
    # `k` can take on in order to map negative `k`'s back to a value >= 0.
    class V
      @offset : Int32
      @v : Array(Int32)

      def initialize(max_d : Int32)
        @offset = max_d
        @v = Array.new(2 * max_d, 0)
      end

      def size : Int32
        @v.size
      end

      def [](k : Int32) : Int32
        @v[k + @offset]
      end

      def []=(k : Int32, value : Int32) : Nil
        @v[k + @offset] = value
      end
    end

    def self.max_d(len1 : Int32, len2 : Int32) : Int32
      # XXX look into reducing the need to have the additional '+ 1'
      (len1 + len2 + 1) // 2 + 1
    end

    def self.split_at(range : Range(Int32, Int32), at : Int32) : Tuple(Range(Int32, Int32), Range(Int32, Int32))
      {range.begin...at, at...range.end}
    end

    # A `Snake` is a sequence of diagonal edges in the edit graph.  Normally
    # a snake has a start end end point (and it is possible for a snake to have
    # a length of zero, meaning the start and end points are the same) however
    # we do not need the end point which is why it's not implemented here.
    #
    # The divide part of a divide-and-conquer strategy. A D-path has D+1 snakes
    # some of which may be empty. The divide step requires finding the ceil(D/2) +
    # 1 or middle snake of an optimal D-path. The idea for doing so is to
    # simultaneously run the basic algorithm in both the forward and reverse
    # directions until furthest reaching forward and reverse paths starting at
    # opposing corners 'overlap'.
    def self.find_middle_snake(old, old_range : Range(Int32, Int32), new, new_range : Range(Int32, Int32),
                               vf : V, vb : V, deadline : Similar::DeadlineSupport::Instant? = nil)
      n = old_range.size
      m = new_range.size

      # By Lemma 1 in the paper, the optimal edit script length is odd or even as
      # `delta` is odd or even.
      delta = n - m
      odd = delta & 1 == 1

      # The initial point at (0, -1)
      vf[1] = 0
      # The initial point at (N, M+1)
      vb[1] = 0

      # We only need to explore ceil(D/2) + 1
      d_max = max_d(n, m)
      # TODO: check vf.size >= d_max, vb.size >= d_max

      (0...d_max).each do |d|
        # are we running for too long?
        if Similar::DeadlineSupport.deadline_exceeded(deadline)
          break
        end

        # Forward path
        k = d
        while k >= -d
          step = 2
          k = -d if k < -d # shouldn't happen
          if k == -d || (k != d && vf[k - 1] < vf[k + 1])
            x = vf[k + 1]
          else
            x = vf[k - 1] + 1
          end
          y = x - k

          # The coordinate of the start of a snake
          x0, y0 = x, y
          # While these sequences are identical, keep moving through the
          # graph with no cost
          if x < n && y < m
            advance = Similar::Algorithms.common_prefix_len(
              old,
              old_range.begin + x...old_range.end,
              new,
              new_range.begin + y...new_range.end
            )
            x += advance
          end

          # This is the new best x value
          vf[k] = x

          # Only check for connections from the forward search when N - M is
          # odd and when there is a reciprocal k line coming from the other
          # direction.
          if odd && (k - delta).abs <= (d - 1)
            if vf[k] + vb[-(k - delta)] >= n
              # Return the snake
              return {x0 + old_range.begin, y0 + new_range.begin}
            end
          end

          k -= step
        end

        # Backward path
        k = d
        while k >= -d
          step = 2
          k = -d if k < -d
          if k == -d || (k != d && vb[k - 1] < vb[k + 1])
            x = vb[k + 1]
          else
            x = vb[k - 1] + 1
          end
          y = x - k

          # The coordinate of the start of a snake
          if x < n && y < m
            advance = Similar::Algorithms.common_suffix_len(
              old,
              old_range.begin...old_range.begin + n - x,
              new,
              new_range.begin...new_range.begin + m - y
            )
            x += advance
            y += advance
          end

          # This is the new best x value
          vb[k] = x

          if !odd && (k - delta).abs <= d
            if vb[k] + vf[-(k - delta)] >= n
              # Return the snake
              return {n - x + old_range.begin, m - y + new_range.begin}
            end
          end

          k -= step
        end

        # TODO: Maybe there's an opportunity to optimize and bail early?
      end

      # deadline reached
      nil
    end

    # The conquer part of a divide-and-conquer strategy.
    def self.conquer(d, old, old_range : Range(Int32, Int32), new, new_range : Range(Int32, Int32),
                     vf : V, vb : V, deadline : Similar::DeadlineSupport::Instant? = nil)
      # Check for common prefix
      common_prefix_len = Similar::Algorithms.common_prefix_len(old, old_range, new, new_range)
      if common_prefix_len > 0
        d.equal(old_range.begin, new_range.begin, common_prefix_len)
      end
      old_start = old_range.begin + common_prefix_len
      new_start = new_range.begin + common_prefix_len

      # Check for common suffix
      common_suffix_len = Similar::Algorithms.common_suffix_len(old, old_start...old_range.end, new, new_start...new_range.end)
      common_suffix = {
        old_range.end - common_suffix_len,
        new_range.end - common_suffix_len,
      }
      old_end = old_range.end - common_suffix_len
      new_end = new_range.end - common_suffix_len

      old_range = old_start...old_end
      new_range = new_start...new_end

      if Similar::Algorithms.is_empty_range(old_range) && Similar::Algorithms.is_empty_range(new_range)
        # Do nothing
      elsif Similar::Algorithms.is_empty_range(new_range)
        d.delete(old_range.begin, old_range.size, new_range.begin)
      elsif Similar::Algorithms.is_empty_range(old_range)
        d.insert(old_range.begin, new_range.begin, new_range.size)
      else
        if snake = find_middle_snake(old, old_range, new, new_range, vf, vb, deadline)
          x_start, y_start = snake
          old_a, old_b = split_at(old_range, x_start)
          new_a, new_b = split_at(new_range, y_start)
          conquer(d, old, old_a, new, new_a, vf, vb, deadline)
          conquer(d, old, old_b, new, new_b, vf, vb, deadline)
        else
          # deadline reached, fallback to delete + insert
          d.delete(old_range.begin, old_range.end - old_range.begin, new_range.begin)
          d.insert(old_range.begin, new_range.begin, new_range.end - new_range.begin)
        end
      end

      if common_suffix_len > 0
        d.equal(common_suffix[0], common_suffix[1], common_suffix_len)
      end
    end

    # Myers' diff algorithm.
    #
    # Diff `old`, between indices `old_range` and `new` between indices `new_range`.
    def self.diff(old, old_range : Range(Int32, Int32), new, new_range : Range(Int32, Int32),
                  d : DiffHook) : Nil
      diff_deadline(old, old_range, new, new_range, d, nil)
    end

    # Myers' diff algorithm with deadline.
    #
    # Diff `old`, between indices `old_range` and `new` between indices `new_range`.
    #
    # This diff is done with an optional deadline that defines the maximal
    # execution time permitted before it bails and falls back to an approximation.
    def self.diff_deadline(old, old_range : Range(Int32, Int32), new, new_range : Range(Int32, Int32),
                           d : DiffHook, deadline : Similar::DeadlineSupport::Instant? = nil) : Nil
      max_d = max_d(old_range.size, new_range.size)
      vf = V.new(max_d)
      vb = V.new(max_d)
      conquer(d, old, old_range, new, new_range, vf, vb, deadline)
      d.finish
    end
  end
end
