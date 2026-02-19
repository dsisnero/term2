module Ansi
  def self.cut(s : String, left : Int32, right : Int32) : String
    cut(Method::GraphemeWidth, s, left, right)
  end

  def self.cut_wc(s : String, left : Int32, right : Int32) : String
    cut(Method::WcWidth, s, left, right)
  end

  def self.cut(m : Method, s : String, left : Int32, right : Int32) : String
    return "" if right <= left

    truncate_fn = ->(input : String, length : Int32, tail : String) { truncate(Method::GraphemeWidth, input, length, tail) }
    truncate_left_fn = ->(input : String, length : Int32, prefix : String) { truncate_left(Method::GraphemeWidth, input, length, prefix) }

    if m == Method::WcWidth
      truncate_fn = ->(input : String, length : Int32, tail : String) { truncate(Method::WcWidth, input, length, tail) }
      truncate_left_fn = ->(input : String, length : Int32, prefix : String) { truncate(Method::WcWidth, input, length, prefix) }
    end

    if left == 0
      return truncate_fn.call(s, right, "")
    end
    truncate_left_fn.call(truncate_fn.call(s, right, ""), left, "")
  end

  def self.truncate(s : String, length : Int32, tail : String) : String
    truncate(Method::GraphemeWidth, s, length, tail)
  end

  def self.truncate_wc(s : String, length : Int32, tail : String) : String
    truncate(Method::WcWidth, s, length, tail)
  end

  # ameba:disable Metrics/CyclomaticComplexity
  def self.truncate(m : Method, s : String, length : Int32, tail : String) : String
    return s if string_width(s) <= length

    tw = string_width(tail)
    length -= tw
    return "" if length < 0

    bytes = s.to_slice
    buf = String::Builder.new
    cur_width = 0
    ignoring = false
    pstate = ParserTransition::GroundState
    i = 0

    while i < bytes.size
      state, action = ParserTransition::Table.transition(pstate, bytes[i])
      if state == ParserTransition::Utf8State
        cluster_bytes, width = first_grapheme_cluster(bytes[i, bytes.size - i], m)
        i += cluster_bytes.size
        cur_width += width

        if ignoring
          next
        end

        if cur_width > length && !ignoring
          ignoring = true
          buf << tail
        end

        if cur_width > length
          next
        end

        buf.write(cluster_bytes)
        pstate = ParserTransition::GroundState
        next
      end

      case action
      when ParserTransition::PrintAction
        if cur_width >= length && !ignoring
          ignoring = true
          buf << tail
        end

        if ignoring
          i += 1
          next
        end

        cur_width += 1
        buf.write_byte(bytes[i])
        i += 1
      when ParserTransition::ExecuteAction
        if ignoring
          i += 1
          next
        end
        buf.write_byte(bytes[i])
        i += 1
      else
        buf.write_byte(bytes[i])
        i += 1
      end

      pstate = state

      if cur_width > length && !ignoring
        ignoring = true
        buf << tail
      end
    end

    buf.to_s
  end

  def self.truncate_left(s : String, n : Int32, prefix : String) : String
    truncate_left(Method::GraphemeWidth, s, n, prefix)
  end

  def self.truncate_left_wc(s : String, n : Int32, prefix : String) : String
    truncate_left(Method::WcWidth, s, n, prefix)
  end

  # ameba:disable Metrics/CyclomaticComplexity
  def self.truncate_left(m : Method, s : String, n : Int32, prefix : String) : String
    return s if n <= 0

    bytes = s.to_slice
    buf = String::Builder.new
    cur_width = 0
    ignoring = true
    pstate = ParserTransition::GroundState
    i = 0

    while i < bytes.size
      unless ignoring
        buf.write(bytes[i, bytes.size - i])
        break
      end

      state, action = ParserTransition::Table.transition(pstate, bytes[i])
      if state == ParserTransition::Utf8State
        cluster_bytes, width = first_grapheme_cluster(bytes[i, bytes.size - i], m)
        i += cluster_bytes.size
        cur_width += width

        if cur_width > n && ignoring
          ignoring = false
          buf << prefix
        end

        if cur_width > n
          buf.write(cluster_bytes)
        end

        if ignoring
          next
        end

        pstate = ParserTransition::GroundState
        next
      end

      case action
      when ParserTransition::PrintAction
        cur_width += 1

        if cur_width > n && ignoring
          ignoring = false
          buf << prefix
        end

        if ignoring
          i += 1
          next
        end

        buf.write_byte(bytes[i])
        i += 1
      when ParserTransition::ExecuteAction
        if ignoring
          i += 1
          next
        end
        buf.write_byte(bytes[i])
        i += 1
      else
        buf.write_byte(bytes[i])
        i += 1
      end

      pstate = state
      if cur_width > n && ignoring
        ignoring = false
        buf << prefix
      end
    end

    buf.to_s
  end

  def self.byte_to_grapheme_range(str : String, byte_start : Int32, byte_stop : Int32) : {Int32, Int32}
    byte_pos = 0
    char_pos = 0
    iter = TextSegment.each_grapheme(str)

    while byte_start > byte_pos
      cluster = iter.next
      break if cluster.is_a?(Iterator::Stop)
      from, to = cluster.positions
      byte_pos += (to - from)
      width = grapheme_cluster_width(cluster)
      char_pos += Math.max(1, width)
    end
    char_start = char_pos

    while byte_stop > byte_pos
      cluster = iter.next
      break if cluster.is_a?(Iterator::Stop)
      from, to = cluster.positions
      byte_pos += (to - from)
      width = grapheme_cluster_width(cluster)
      char_pos += Math.max(1, width)
    end

    {char_start, char_pos}
  end
end
