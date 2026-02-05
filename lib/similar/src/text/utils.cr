module Similar::Text
  private def self.each_char_with_byte_offset(str : String, &)
    offset = 0
    str.each_char do |char|
      yield char, offset
      offset += char.bytesize
    end
  end

  private def self.byte_whitespace?(byte : UInt8) : Bool
    byte == 0x20_u8 || byte == 0x09_u8 || byte == 0x0A_u8 ||
      byte == 0x0B_u8 || byte == 0x0C_u8 || byte == 0x0D_u8
  end

  # Splits a string into lines with newlines attached.
  def self.tokenize_lines(str : String) : Array(String)
    result = [] of String
    start_offset = 0
    last_char = nil
    last_offset = 0

    each_char_with_byte_offset(str) do |char, offset|
      if (lc = last_char) && lc == '\r' && char == '\n'
        # CRLF - already handled by previous iteration
        last_char = char
        last_offset = offset
        next
      end

      if (lc = last_char) && (lc == '\r' || lc == '\n')
        # End of line (CR or LF)
        result << str.byte_slice(start_offset, last_offset - start_offset + lc.bytesize)
        start_offset = offset
      end

      last_char = char
      last_offset = offset
    end

    # Handle trailing newline or last line
    if (lc = last_char) && (lc == '\r' || lc == '\n')
      result << str.byte_slice(start_offset, last_offset - start_offset + lc.bytesize)
      start_offset = str.bytesize
    end

    if start_offset < str.bytesize
      result << str.byte_slice(start_offset)
    end

    result
  end

  # Splits bytes into lines with newlines attached.
  def self.tokenize_lines(bytes : Bytes) : Array(BytesWrapper)
    result = [] of BytesWrapper
    start_offset = 0
    last_byte = nil
    last_offset = 0
    i = 0

    while i < bytes.size
      byte = bytes[i]
      if (lb = last_byte) && lb == 0x0D_u8 && byte == 0x0A_u8
        # CRLF - already handled by previous iteration
        last_byte = byte
        last_offset = i
        i += 1
        next
      end

      if (lb = last_byte) && (lb == 0x0D_u8 || lb == 0x0A_u8)
        # End of line (CR or LF)
        result << BytesWrapper.new(bytes[start_offset, last_offset - start_offset + 1])
        start_offset = i
      end

      last_byte = byte
      last_offset = i
      i += 1
    end

    # Handle trailing newline or last line
    if (lb = last_byte) && (lb == 0x0D_u8 || lb == 0x0A_u8)
      result << BytesWrapper.new(bytes[start_offset, last_offset - start_offset + 1])
      start_offset = bytes.size
    end

    if start_offset < bytes.size
      result << BytesWrapper.new(bytes[start_offset, bytes.size - start_offset])
    end

    result
  end

  # Splits a string into words and whitespace.
  def self.tokenize_words(str : String) : Array(String)
    return [] of String if str.empty?

    result = [] of String
    start_offset = 0
    last_was_whitespace = nil

    each_char_with_byte_offset(str) do |char, offset|
      is_whitespace = char.whitespace?

      if last_was_whitespace.nil?
        # First character
        last_was_whitespace = is_whitespace
      elsif is_whitespace != last_was_whitespace
        # Category changed, emit slice
        result << str.byte_slice(start_offset, offset - start_offset)
        start_offset = offset
        last_was_whitespace = is_whitespace
      end
    end

    # Emit final slice
    if start_offset < str.bytesize
      result << str.byte_slice(start_offset)
    end

    result
  end

  # Splits bytes into words and whitespace (ASCII whitespace only).
  def self.tokenize_words(bytes : Bytes) : Array(BytesWrapper)
    return [] of BytesWrapper if bytes.empty?

    result = [] of BytesWrapper
    start_offset = 0
    last_was_whitespace = nil
    i = 0

    while i < bytes.size
      is_whitespace = byte_whitespace?(bytes[i])
      if last_was_whitespace.nil?
        last_was_whitespace = is_whitespace
      elsif is_whitespace != last_was_whitespace
        result << BytesWrapper.new(bytes[start_offset, i - start_offset])
        start_offset = i
        last_was_whitespace = is_whitespace
      end
      i += 1
    end

    if start_offset < bytes.size
      result << BytesWrapper.new(bytes[start_offset, bytes.size - start_offset])
    end

    result
  end

  # Splits a string into characters (UTF-8 aware).
  def self.tokenize_chars(str : String) : Array(String)
    result = [] of String
    str.each_char do |char|
      result << char.to_s
    end
    result
  end

  # Splits bytes into single-byte slices.
  def self.tokenize_chars(bytes : Bytes) : Array(BytesWrapper)
    result = [] of BytesWrapper
    i = 0
    while i < bytes.size
      result << BytesWrapper.new(bytes[i, 1])
      i += 1
    end
    result
  end

  # Basic Unicode word tokenization using character categories.
  def self.tokenize_unicode_words(str : String) : Array(String)
    return [] of String if str.empty?

    result = [] of String
    start_offset = 0
    last_category = nil

    each_char_with_byte_offset(str) do |char, offset|
      category = char_category(char)

      if last_category.nil?
        # First character
        last_category = category
      elsif category != last_category
        # Category changed, emit slice
        result << str.byte_slice(start_offset, offset - start_offset)
        start_offset = offset
        last_category = category
      end
    end

    # Emit final slice
    if start_offset < str.bytesize
      result << str.byte_slice(start_offset)
    end

    result
  end

  # Basic grapheme tokenization (handles combining characters).
  def self.tokenize_graphemes(str : String) : Array(String)
    return [] of String if str.empty?

    result = [] of String
    start_offset = 0
    last_char = nil

    each_char_with_byte_offset(str) do |char, offset|
      if last_char.nil?
        # First character starts a cluster
        last_char = char
      elsif combining?(char)
        # Combining character continues current cluster
        # Continue without emitting
      else
        # Non-combining character, emit previous cluster
        result << str.byte_slice(start_offset, offset - start_offset)
        start_offset = offset
        last_char = char
      end
    end

    # Emit final cluster
    if start_offset < str.bytesize
      result << str.byte_slice(start_offset)
    end

    result
  end

  # Checks if a string ends with a newline.
  def self.ends_with_newline(str : String) : Bool
    str.ends_with?('\n') || str.ends_with?('\r')
  end

  # Checks if bytes end with a newline.
  def self.ends_with_newline(bytes : Bytes) : Bool
    return false if bytes.empty?
    last = bytes[-1]
    last == 0x0A_u8 || last == 0x0D_u8
  end

  private def self.combining?(char : Char) : Bool
    codepoint = char.ord
    # Combining Diacritical Marks (U+0300–U+036F)
    return true if 0x0300 <= codepoint <= 0x036F
    # Combining Diacritical Marks Extended (U+1AB0–U+1AFF)
    return true if 0x1AB0 <= codepoint <= 0x1AFF
    # Combining Diacritical Marks Supplement (U+1DC0–U+1DFF)
    return true if 0x1DC0 <= codepoint <= 0x1DFF
    # Combining Diacritical Marks for Symbols (U+20D0–U+20FF)
    return true if 0x20D0 <= codepoint <= 0x20FF
    # Variation Selectors (U+FE00–U+FE0F)
    return true if 0xFE00 <= codepoint <= 0xFE0F
    # Hebrew points, Arabic diacritics, etc.
    false
  end

  private def self.char_category(char : Char) : Symbol
    if char.letter? || char.number?
      :alphanumeric
    elsif char.whitespace?
      :whitespace
    else
      :other
    end
  end

  # Quick and dirty way to get an upper sequence ratio.
  def self.upper_seq_ratio(seq1 : Array(T), seq2 : Array(T)) : Float32 forall T
    n = seq1.size + seq2.size
    if n == 0
      1.0_f32
    else
      2.0_f32 * Math.min(seq1.size, seq2.size) / n.to_f32
    end
  end

  # Internal utility to calculate an upper bound for a ratio for
  # `get_close_matches`. This is based on Python's difflib approach
  # of considering the two sets to be multisets.
  #
  # It counts the number of matches without regard to order, which is an
  # obvious upper bound.
  class QuickSeqRatio(T)
    @counts : Hash(T, Int32)

    def initialize(seq : Array(T))
      counts = Hash(T, Int32).new(0)
      seq.each do |item|
        counts[item] += 1
      end
      @counts = counts
    end

    def calc(seq : Array(T)) : Float32
      n = @counts.size + seq.size
      return 1.0_f32 if n == 0

      available = Hash(T, Int32).new(0)
      matches = 0
      seq.each do |item|
        x = available.fetch(item, @counts[item])
        available[item] = x - 1
        matches += 1 if x > 0
      end

      2.0_f32 * matches / n.to_f32
    end
  end
end
