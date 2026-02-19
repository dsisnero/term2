module Ansi
  NBSP = '\u{00A0}'

  def self.hardwrap(s : String, limit : Int32, preserve_space : Bool) : String
    hardwrap(Method::GraphemeWidth, s, limit, preserve_space)
  end

  def self.hardwrap_wc(s : String, limit : Int32, preserve_space : Bool) : String
    hardwrap(Method::WcWidth, s, limit, preserve_space)
  end

  # ameba:disable Metrics/CyclomaticComplexity
  def self.hardwrap(m : Method, s : String, limit : Int32, preserve_space : Bool) : String
    return s if limit < 1

    bytes = s.to_slice
    buf = String::Builder.new
    cur_width = 0
    force_newline = false
    pstate = ParserTransition::GroundState
    i = 0

    add_newline = -> {
      buf.write_byte('\n'.ord.to_u8)
      cur_width = 0
    }

    while i < bytes.size
      state, action = ParserTransition::Table.transition(pstate, bytes[i])
      if state == ParserTransition::Utf8State
        cluster_bytes, width = first_grapheme_cluster(bytes[i, bytes.size - i], m)
        i += cluster_bytes.size

        if cur_width + width > limit
          add_newline.call
        end
        if !preserve_space && cur_width == 0 && cluster_bytes.size <= 4
          if (r = first_char_from_bytes(cluster_bytes)) && r.whitespace?
            pstate = ParserTransition::GroundState
            next
          end
        end

        buf.write(cluster_bytes)
        cur_width += width
        pstate = ParserTransition::GroundState
        next
      end

      case action
      when ParserTransition::PrintAction, ParserTransition::ExecuteAction
        if bytes[i] == '\n'.ord.to_u8
          add_newline.call
          force_newline = false
          pstate = state
          i += 1
          next
        end

        if cur_width + 1 > limit
          add_newline.call
          force_newline = true
        end

        if cur_width == 0
          if !preserve_space && force_newline && bytes[i].unsafe_chr.whitespace?
            pstate = state
            i += 1
            next
          end
          force_newline = false
        end

        buf.write_byte(bytes[i])
        cur_width += 1 if action == ParserTransition::PrintAction
      else
        buf.write_byte(bytes[i])
      end

      pstate = state if pstate != ParserTransition::Utf8State
      i += 1
    end

    buf.to_s
  end

  def self.wordwrap(s : String, limit : Int32, breakpoints : String) : String
    wordwrap(Method::GraphemeWidth, s, limit, breakpoints)
  end

  def self.wordwrap_wc(s : String, limit : Int32, breakpoints : String) : String
    wordwrap(Method::WcWidth, s, limit, breakpoints)
  end

  # ameba:disable Metrics/CyclomaticComplexity
  def self.wordwrap(m : Method, s : String, limit : Int32, breakpoints : String) : String
    return s if limit < 1

    bytes = s.to_slice
    buf = String::Builder.new
    word = IO::Memory.new
    space = IO::Memory.new
    cur_width = 0
    word_len = 0
    pstate = ParserTransition::GroundState
    i = 0

    add_space = -> {
      cur_width += space.bytesize
      buf.write(space.to_slice)
      space.clear
    }

    add_word = -> {
      return if word.bytesize == 0
      add_space.call
      cur_width += word_len
      buf.write(word.to_slice)
      word.clear
      word_len = 0
    }

    add_newline = -> {
      buf.write_byte('\n'.ord.to_u8)
      cur_width = 0
      space.clear
    }

    while i < bytes.size
      state, action = ParserTransition::Table.transition(pstate, bytes[i])
      if state == ParserTransition::Utf8State
        cluster_bytes, width = first_grapheme_cluster(bytes[i, bytes.size - i], m)
        i += cluster_bytes.size

        r = first_char_from_bytes(cluster_bytes)
        if r && r.whitespace? && r != NBSP
          add_word.call
          space << r
        elsif bytes_contains_any(cluster_bytes, breakpoints)
          add_space.call
          add_word.call
          buf.write(cluster_bytes)
          cur_width += 1
        else
          word.write(cluster_bytes)
          word_len += width
          if cur_width + space.bytesize + word_len > limit && word_len < limit
            add_newline.call
          end
        end

        pstate = ParserTransition::GroundState
        next
      end

      case action
      when ParserTransition::PrintAction, ParserTransition::ExecuteAction
        r = bytes[i].unsafe_chr
        case
        when r == '\n'
          if word_len == 0
            if cur_width + space.bytesize > limit
              cur_width = 0
            else
              buf.write(space.to_slice)
            end
            space.clear
          end

          add_word.call
          add_newline.call
        when r.whitespace?
          add_word.call
          space.write_byte(bytes[i])
        when r == '-' || rune_contains_any(r, breakpoints)
          add_space.call
          add_word.call
          buf.write_byte(bytes[i])
          cur_width += 1
        else
          word.write_byte(bytes[i])
          word_len += 1
          if cur_width + space.bytesize + word_len > limit && word_len < limit
            add_newline.call
          end
        end
      else
        word.write_byte(bytes[i])
      end

      pstate = state if pstate != ParserTransition::Utf8State
      i += 1
    end

    add_word.call
    buf.to_s
  end

  def self.wrap(s : String, limit : Int32, breakpoints : String) : String
    wrap(Method::GraphemeWidth, s, limit, breakpoints)
  end

  def self.wrap_wc(s : String, limit : Int32, breakpoints : String) : String
    wrap(Method::WcWidth, s, limit, breakpoints)
  end

  # ameba:disable Metrics/CyclomaticComplexity
  def self.wrap(m : Method, s : String, limit : Int32, breakpoints : String) : String
    return s if limit < 1

    buf = String::Builder.new
    word = IO::Memory.new
    space = IO::Memory.new
    space_width = 0
    cur_width = 0
    word_len = 0
    pstate = ParserTransition::GroundState
    bytes = s.to_slice
    i = 0

    add_space = -> {
      return if space_width == 0 && space.bytesize == 0
      cur_width += space_width
      buf.write(space.to_slice)
      space.clear
      space_width = 0
    }

    add_word = -> {
      return if word.bytesize == 0
      add_space.call
      cur_width += word_len
      buf.write(word.to_slice)
      word.clear
      word_len = 0
    }

    add_newline = -> {
      buf.write_byte('\n'.ord.to_u8)
      cur_width = 0
      space.clear
      space_width = 0
    }

    while i < bytes.size
      state, action = ParserTransition::Table.transition(pstate, bytes[i])
      if state == ParserTransition::Utf8State
        cluster_bytes, width = first_grapheme_cluster(bytes[i, bytes.size - i], m)
        i += cluster_bytes.size

        cluster_str = bytes_to_string(cluster_bytes)
        r = cluster_str.each_char.first?
        if r && r.whitespace? && r != NBSP
          add_word.call
          space << r
          space_width += width
        elsif !cluster_str.empty? && cluster_str.each_char.any? { |char| breakpoints.includes?(char) }
          add_space.call
          if cur_width + word_len + width > limit
            word.write(cluster_bytes)
            word_len += width
          else
            add_word.call
            buf << cluster_str
            cur_width += width
          end
        else
          if word_len + width > limit
            add_word.call
          end

          word.write(cluster_bytes)
          word_len += width

          if cur_width + word_len + space_width > limit
            add_newline.call
          end

          if word_len == limit
            add_word.call
          end
        end

        pstate = ParserTransition::GroundState
        next
      end

      case action
      when ParserTransition::PrintAction, ParserTransition::ExecuteAction
        r = bytes[i].unsafe_chr
        case
        when r == '\n'
          if word_len == 0
            if cur_width + space_width > limit
              cur_width = 0
            else
              buf.write(space.to_slice)
            end
            space.clear
            space_width = 0
          end

          add_word.call
          add_newline.call
        when r.whitespace?
          add_word.call
          space << r
          space_width += 1
        when r == '-' || rune_contains_any(r, breakpoints)
          add_space.call
          if cur_width + word_len >= limit
            word << r
            word_len += 1
          else
            add_word.call
            buf << r
            cur_width += 1
          end
        else
          add_newline.call if cur_width == limit

          word << r
          word_len += 1

          add_word.call if word_len == limit

          if cur_width + word_len + space_width > limit
            add_newline.call
          end
        end
      else
        word.write_byte(bytes[i])
      end

      pstate = state if pstate != ParserTransition::Utf8State
      i += 1
    end

    if word_len == 0
      if cur_width + space_width > limit
        cur_width = 0
      else
        buf.write(space.to_slice)
      end
      space.clear
      space_width = 0
    end

    add_word.call
    buf.to_s
  end
end
