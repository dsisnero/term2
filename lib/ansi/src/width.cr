require "uniwidth"

module Ansi
  def self.strip(s : String) : String
    bytes = s.to_slice
    buf = String::Builder.new
    ri = 0
    rw = 0
    pstate = ParserTransition::GroundState
    i = 0

    while i < bytes.size
      b = bytes[i]
      if pstate == ParserTransition::Utf8State
        buf.write_byte(b)
        ri += 1
        if ri < rw
          i += 1
          next
        end
        pstate = ParserTransition::GroundState
        ri = 0
        rw = 0
        i += 1
        next
      end

      state, action = ParserTransition::Table.transition(pstate, b)
      case action
      when ParserTransition::CollectAction
        if state == ParserTransition::Utf8State
          rw = utf8_byte_len(b)
          buf.write_byte(b)
          ri = 1
        end
      when ParserTransition::PrintAction, ParserTransition::ExecuteAction
        buf.write_byte(b)
      end

      pstate = state if pstate != ParserTransition::Utf8State
      i += 1
    end

    buf.to_s
  end

  def self.string_width(s : String) : Int32
    string_width(Method::GraphemeWidth, s)
  end

  def self.string_width_wc(s : String) : Int32
    string_width(Method::WcWidth, s)
  end

  def self.string_width(m : Method, s : String) : Int32
    return 0 if s.empty?

    bytes = s.to_slice
    pstate = ParserTransition::GroundState
    width = 0
    i = 0

    while i < bytes.size
      state, action = ParserTransition::Table.transition(pstate, bytes[i])
      if state == ParserTransition::Utf8State
        cluster_bytes, w = first_grapheme_cluster(bytes[i, bytes.size - i], m)
        width += w
        advance = cluster_bytes.size
        advance = 1 if advance == 0
        i += advance
        pstate = ParserTransition::GroundState
        next
      end

      width += 1 if action == ParserTransition::PrintAction
      pstate = state
      i += 1
    end

    width
  end

  private def self.utf8_byte_len(b : UInt8) : Int32
    if b <= 0x7f
      1
    elsif b >= 0xc0 && b <= 0xdf
      2
    elsif b >= 0xe0 && b <= 0xef
      3
    elsif b >= 0xf0 && b <= 0xf7
      4
    else
      -1
    end
  end

  private def self.bytes_to_string(bytes : Bytes) : String
    String.new(bytes, "UTF-8", :skip)
  end

  private def self.first_char_from_bytes(bytes : Bytes) : Char?
    str = bytes_to_string(bytes)
    str.each_char do |char|
      return char
    end
    nil
  end

  private def self.first_grapheme_cluster(s : String, m : Method) : {String, Int32}
    return {"", 0} if s.empty?

    cluster = TextSegment.graphemes(s).first?
    return {"", 0} unless cluster

    from, to = cluster.positions
    cluster_str = s.byte_slice(from, to - from)
    {cluster_str, cluster_width(cluster, m)}
  end

  private def self.first_grapheme_cluster(bytes : Bytes, m : Method) : {Bytes, Int32}
    str = bytes_to_string(bytes)
    return {Bytes.empty, 0} if str.empty?

    cluster = TextSegment.graphemes(str).first?
    return {Bytes.empty, 0} unless cluster

    _from, to = cluster.positions
    {bytes[0, to], cluster_width(cluster, m)}
  end

  private def self.cluster_width(cluster : TextSegment::Grapheme::Cluster, m : Method) : Int32
    case m
    when Method::WcWidth
      width = UnicodeCharWidth.width(cluster.str).to_i
      return width if width != 1
      cps = cluster.codepoints
      return 1 if regional_indicator_sequence?(cps)
      return 2 if emoji_sequence?(cps)
      width
    else
      grapheme_cluster_width(cluster)
    end
  end

  private def self.grapheme_cluster_width(cluster : TextSegment::Grapheme::Cluster) : Int32
    cps = cluster.codepoints
    return 2 if regional_indicator_sequence?(cps)
    return 2 if emoji_sequence?(cps)
    UnicodeCharWidth.width(cluster.str).to_i
  end

  private def self.regional_indicator_sequence?(cps : Array(Int32)) : Bool
    cps.size > 1 && cps.all? { |codepoint| codepoint >= 0x1f1e6 && codepoint <= 0x1f1ff }
  end

  private def self.emoji_sequence?(cps : Array(Int32)) : Bool
    cps.any? { |codepoint| emoji_codepoint?(codepoint) }
  end

  private def self.emoji_codepoint?(codepoint : Int32) : Bool
    table = UnicodeCharWidth.emoji_table
    return false if table.empty?
    return false if codepoint < table[0].first

    bot = 0
    top = table.size - 1
    while top >= bot
      mid = (bot + top) >> 1
      range = table[mid]
      if range[1] < codepoint
        bot = mid + 1
      elsif range[0] > codepoint
        top = mid - 1
      else
        return true
      end
    end
    false
  end

  private def self.bytes_contains_any(bytes : Bytes, breakpoints : String) : Bool
    return false if breakpoints.empty?
    str = bytes_to_string(bytes)
    str.each_char do |char|
      return true if breakpoints.includes?(char)
    end
    false
  end

  private def self.rune_contains_any(r : Char, s : String) : Bool
    s.each_char do |char|
      return true if char == r
    end
    false
  end
end

module UnicodeCharWidth
  def self.emoji_table
    emoji
  end
end
