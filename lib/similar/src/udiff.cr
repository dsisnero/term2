# Unified diff functionality.
#
# This module provides unified diff formatting for text diffs.
require "json"
require "./text/utils"

module Similar
  # Helper to display missing newline hint.
  struct MissingNewlineHint
    include JSON::Serializable

    def initialize(@show : Bool)
    end

    def to_s(io : IO) : Nil
      if @show
        io << "\n\\ No newline at end of file"
      end
    end
  end

  # Represents a range in a unified diff hunk.
  struct UnifiedDiffHunkRange
    include JSON::Serializable
    getter start : Int32
    getter end : Int32

    def initialize(@start : Int32, @end : Int32)
    end

    def to_s(io : IO) : Nil
      beginning = @start + 1
      len = Math.max(0, @end - @start)
      if len == 1
        io << beginning
      else
        if len == 0
          # empty ranges begin at line just before the range
          beginning -= 1
        end
        io << beginning << ',' << len
      end
    end
  end

  # Unified diff hunk header.
  struct UnifiedHunkHeader
    include JSON::Serializable
    getter old_range : UnifiedDiffHunkRange
    getter new_range : UnifiedDiffHunkRange

    # Creates a hunk header from a (non empty) slice of diff ops.
    def self.new(ops : Array(DiffOp)) : UnifiedHunkHeader
      first = ops[0]
      last = ops[-1]
      old_start = first.old_range.begin
      new_start = first.new_range.begin
      old_end = last.old_range.end
      new_end = last.new_range.end
      UnifiedHunkHeader.new(
        UnifiedDiffHunkRange.new(old_start, old_end),
        UnifiedDiffHunkRange.new(new_start, new_end)
      )
    end

    def initialize(@old_range : UnifiedDiffHunkRange, @new_range : UnifiedDiffHunkRange)
    end

    def to_s(io : IO) : Nil
      io << "@@ -" << @old_range << " +" << @new_range << " @@"
    end
  end

  # Unified diff formatter.
  #
  # Example:
  #
  # ```
  # old_text = "Hello\nWorld"
  # new_text = "Hello\nCrystal"
  # diff = TextDiff.from_lines(old_text, new_text)
  # puts diff.unified_diff.header("old.txt", "new.txt")
  # ```
  class UnifiedDiff(T)
    @diff : TextDiff(T)
    @context_radius : Int32
    @missing_newline_hint : Bool
    @header : Tuple(String, String)?

    # Creates a formatter from a text diff object.
    def initialize(@diff : TextDiff(T))
      @context_radius = 3
      @missing_newline_hint = true
      @header = nil
    end

    # Changes the context radius.
    #
    # The context radius is the number of lines between changes that should
    # be emitted.  This defaults to `3`.
    def context_radius(n : Int32) : self
      @context_radius = n
      self
    end

    # Sets a header to the diff.
    #
    # `a` and `b` are the file names that are added to the top of the unified
    # file format.  The names are accepted verbatim which lets you encode
    # a timestamp into it when separated by a tab (`\t`).
    def header(a : String, b : String) : self
      @header = {a, b}
      self
    end

    # Controls the missing newline hint.
    #
    # By default a special `\ No newline at end of file` marker is added to
    # the output when a file is not terminated with a final newline.  This can
    # be disabled with this flag.
    def missing_newline_hint(yes : Bool) : self
      @missing_newline_hint = yes
      self
    end

    # Internal method to set header optionally.
    def header_opt(header : Tuple(String, String)?) : self
      if header = header
        self.header(header[0], header[1])
      end
      self
    end

    # Iterates over all hunks as configured.
    def iter_hunks : Array(UnifiedDiffHunk(T))
      @diff.grouped_ops(@context_radius).map do |ops|
        UnifiedDiffHunk(T).new(ops, @diff, @missing_newline_hint)
      end
    end

    # Write the unified diff as bytes to the output stream.
    def to_writer(io : IO) : Nil
      header = @header
      iter_hunks.each do |hunk|
        if header
          io << "--- " << header[0] << '\n'
          io << "+++ " << header[1] << '\n'
          header = nil
        end
        hunk.to_writer(io)
      end
    end

    # Returns the unified diff as a string.
    def to_s(io : IO) : Nil
      to_writer(io)
    end
  end

  # Unified diff hunk formatter.
  class UnifiedDiffHunk(T)
    @diff : TextDiff(T)
    @ops : Array(DiffOp)
    @missing_newline_hint : Bool

    # Creates a new hunk for some operations.
    def initialize(@ops : Array(DiffOp), @diff : TextDiff(T), @missing_newline_hint : Bool)
    end

    # Returns the header for the hunk.
    def header : UnifiedHunkHeader
      UnifiedHunkHeader.new(@ops)
    end

    # Returns all operations in the hunk.
    def ops : Array(DiffOp)
      @ops
    end

    # Returns the value of the `missing_newline_hint` flag.
    def missing_newline_hint : Bool
      @missing_newline_hint
    end

    # Iterates over all changes in a hunk.
    def iter_changes : AllChangesIter(Array(T), Array(T), T)
      AllChangesIter(Array(T), Array(T), T).new(
        @diff.old_tokens, @diff.new_tokens, @ops
      )
    end

    # Write the hunk as bytes to the output stream.
    def to_writer(io : IO) : Nil
      iter_changes.each_with_index do |change, idx|
        if idx == 0
          io << header << '\n'
        end
        tag = change.tag.to_char
        value = change.value.to_s
        io << tag << value
        if !@diff.newline_terminated
          io << '\n'
        end
        if @missing_newline_hint && @diff.newline_terminated && missing_newline?(value)
          io << MissingNewlineHint.new(true) << '\n'
        end
      end
    end

    # Returns the hunk as a string.
    def to_s(io : IO) : Nil
      to_writer(io)
    end

    private def missing_newline?(value : String) : Bool
      @diff.newline_terminated && !Text.ends_with_newline(value)
    end
  end
end
