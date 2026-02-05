require "./abstraction"
require "./utils"
require "./inline"
require "../udiff"

module Similar
  # Configuration for text diffs.
  class TextDiffConfig
    @algorithm : Algorithm = Algorithm::Myers
    @newline_terminated : Bool? = nil

    # TODO: deadline support

    # Changes the algorithm.
    #
    # The default algorithm is `Algorithm::Myers`.
    def algorithm(alg : Algorithm) : self
      @algorithm = alg
      self
    end

    # Changes the newline termination flag.
    #
    # The default is automatic based on input.  This flag controls the
    # behavior of `TextDiff#iter_changes` and unified diff generation
    # with regards to newlines.  When the flag is set to `false` (which
    # is the default) then newlines are added.  Otherwise the newlines
    # from the source sequences are reused.
    def newline_terminated(yes : Bool) : self
      @newline_terminated = yes
      self
    end

    # Creates a diff of lines.
    #
    # This splits the text `old` and `new` into lines preserving newlines
    # in the input.
    def diff_lines(old : String, new : String) : TextDiff(String)
      old_tokens = Text.tokenize_lines(old)
      new_tokens = Text.tokenize_lines(new)
      TextDiff.new(old_tokens, new_tokens, @algorithm, true)
    end

    # Creates a diff of lines for bytes.
    def diff_lines(old : Bytes, new : Bytes) : TextDiff(BytesWrapper)
      old_tokens = Text.tokenize_lines(old)
      new_tokens = Text.tokenize_lines(new)
      TextDiff(BytesWrapper).new(old_tokens, new_tokens, @algorithm, true)
    end

    # Creates a diff of words.
    #
    # This splits the text into words and whitespace.
    def diff_words(old : String, new : String) : TextDiff(String)
      old_tokens = Text.tokenize_words(old)
      new_tokens = Text.tokenize_words(new)
      TextDiff.new(old_tokens, new_tokens, @algorithm, false)
    end

    # Creates a diff of words for bytes.
    def diff_words(old : Bytes, new : Bytes) : TextDiff(BytesWrapper)
      old_tokens = Text.tokenize_words(old)
      new_tokens = Text.tokenize_words(new)
      TextDiff(BytesWrapper).new(old_tokens, new_tokens, @algorithm, false)
    end

    # Creates a diff of characters.
    def diff_chars(old : String, new : String) : TextDiff(String)
      old_tokens = Text.tokenize_chars(old)
      new_tokens = Text.tokenize_chars(new)
      TextDiff.new(old_tokens, new_tokens, @algorithm, false)
    end

    # Creates a diff of bytes.
    def diff_chars(old : Bytes, new : Bytes) : TextDiff(BytesWrapper)
      old_tokens = Text.tokenize_chars(old)
      new_tokens = Text.tokenize_chars(new)
      TextDiff(BytesWrapper).new(old_tokens, new_tokens, @algorithm, false)
    end

    # Creates a diff of unicode words.
    #
    # This splits the text into words according to unicode rules.
    def diff_unicode_words(old : String, new : String) : TextDiff(String)
      old_tokens = Text.tokenize_unicode_words(old)
      new_tokens = Text.tokenize_unicode_words(new)
      TextDiff.new(old_tokens, new_tokens, @algorithm, false)
    end

    # Creates a diff of graphemes.
    #
    # This splits the text into grapheme clusters.
    def diff_graphemes(old : String, new : String) : TextDiff(String)
      old_tokens = Text.tokenize_graphemes(old)
      new_tokens = Text.tokenize_graphemes(new)
      TextDiff.new(old_tokens, new_tokens, @algorithm, false)
    end

    # Creates a diff of arbitrary slices.
    def diff_slices(old : Array(T), new : Array(T)) : TextDiff(T) forall T
      TextDiff(T).new(old, new, @algorithm, false)
    end
  end

  # Captures diff op codes for textual diffs.
  class TextDiff(T)
    @old_tokens : Array(T)
    @new_tokens : Array(T)
    @ops : Array(DiffOp)
    @newline_terminated : Bool
    @algorithm : Algorithm

    # Creates a new text diff from already tokenized slices.
    def initialize(old_tokens : Array(T), new_tokens : Array(T),
                   algorithm : Algorithm = Algorithm::Myers,
                   newline_terminated : Bool = false)
      @old_tokens = old_tokens
      @new_tokens = new_tokens
      @algorithm = algorithm
      @newline_terminated = newline_terminated
      @ops = Similar.capture_diff_slices(algorithm, old_tokens, new_tokens)
    end

    # Configures a text differ before diffing.
    def self.configure : TextDiffConfig
      TextDiffConfig.new
    end

    # Creates a diff of lines.
    def self.from_lines(old : String, new : String) : TextDiff(String)
      configure.diff_lines(old, new)
    end

    # Creates a diff of lines for bytes.
    def self.from_lines(old : Bytes, new : Bytes) : TextDiff(BytesWrapper)
      configure.diff_lines(old, new)
    end

    # Creates a diff of words.
    def self.from_words(old : String, new : String) : TextDiff(String)
      configure.diff_words(old, new)
    end

    # Creates a diff of words for bytes.
    def self.from_words(old : Bytes, new : Bytes) : TextDiff(BytesWrapper)
      configure.diff_words(old, new)
    end

    # Creates a diff of chars.
    def self.from_chars(old : String, new : String) : TextDiff(String)
      configure.diff_chars(old, new)
    end

    # Creates a diff of bytes.
    def self.from_chars(old : Bytes, new : Bytes) : TextDiff(BytesWrapper)
      configure.diff_chars(old, new)
    end

    # Creates a diff of unicode words.
    def self.from_unicode_words(old : String, new : String) : TextDiff(String)
      configure.diff_unicode_words(old, new)
    end

    # Creates a diff of graphemes.
    def self.from_graphemes(old : String, new : String) : TextDiff(String)
      configure.diff_graphemes(old, new)
    end

    # Creates a diff of arbitrary slices.
    def self.from_slices(old : Array(U), new : Array(U)) : TextDiff(U) forall U
      configure.diff_slices(old, new)
    end

    # The name of the algorithm that created the diff.
    def algorithm : Algorithm
      @algorithm
    end

    # Returns `true` if items in the slice are newline terminated.
    def newline_terminated : Bool
      @newline_terminated
    end

    # Returns all old tokens.
    def old_tokens : Array(T)
      @old_tokens
    end

    # Returns all new tokens.
    def new_tokens : Array(T)
      @new_tokens
    end

    # Return a measure of the sequences' similarity in the range `0..=1`.
    def ratio : Float32
      Similar.get_diff_ratio(@ops, @old_tokens.size, @new_tokens.size)
    end

    # Iterates over the changes the op expands to.
    def iter_changes(op : DiffOp) : ChangesIter(Array(T), Array(T), T)
      op.iter_changes(@old_tokens, @new_tokens)
    end

    # Returns the captured diff ops.
    def ops : Array(DiffOp)
      @ops
    end

    # Isolate change clusters by eliminating ranges with no changes.
    def grouped_ops(n : Int32) : Array(Array(DiffOp))
      Similar.group_diff_ops(@ops, n)
    end

    # Flattens out the diff into all changes.
    def iter_all_changes : AllChangesIter(Array(T), Array(T), T)
      AllChangesIter(Array(T), Array(T), T).new(@old_tokens, @new_tokens, @ops)
    end

    # Returns a unified diff formatter.
    def unified_diff : UnifiedDiff(T)
      UnifiedDiff(T).new(self)
    end

    # Iterates over inline changes for a diff operation.
    #
    # This is like `iter_changes` but with inline highlight info for
    # replace operations.
    def iter_inline_changes(op : DiffOp) : Array(InlineChange)
      Similar.iter_inline_changes(self, op)
    end
  end

  # Return a list of the best "good enough" matches.
  #
  # *word* is a sequence for which close matches are desired (typically a
  # string). *possibilities* is a list of sequences against which to match
  # *word* (typically a list of strings). *n* (default 3) is the maximum
  # number of close matches to return; *n* must be greater than 0. *cutoff*
  # (default 0.6) is a float in the range [0, 1]. Possibilities that don't
  # score at least that similar to *word* are ignored.
  #
  # ```
  # require "similar"
  #
  # matches = Similar.get_close_matches("appel", ["ape", "apple", "peach", "puppy"], 3, 0.6)
  # matches.should eq(["apple", "ape"])
  # ```
  #
  # Requires the `text` feature.
  def self.get_close_matches(word : String, possibilities : Array(String), n : Int32, cutoff : Float32) : Array(String)
    return [] of String if n <= 0 || possibilities.empty?

    matches = [] of {Float32, String}
    seq1 = Text.tokenize_chars(word)
    quick_ratio = Text::QuickSeqRatio.new(seq1)

    possibilities.each do |possibility|
      seq2 = Text.tokenize_chars(possibility)

      # Quick rejection using upper bound
      if Text.upper_seq_ratio(seq1, seq2) < cutoff || quick_ratio.calc(seq2) < cutoff
        next
      end

      diff = TextDiff.from_slices(seq1, seq2)
      ratio = diff.ratio
      if ratio >= cutoff
        matches.push({ratio, possibility})
      end
    end

    # Sort by ratio descending, then by word ascending for equal ratios
    matches.sort! do |a, b|
      ratio_a, word_a = a
      ratio_b, word_b = b
      if ratio_a != ratio_b
        ratio_b <=> ratio_a # descending
      else
        word_a <=> word_b # ascending
      end
    end

    # Take first n matches
    matches.first(n).map(&.[1])
  end
end
