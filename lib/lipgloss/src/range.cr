require "textseg"
require "uniwidth"
require "set"
require "./style"

module Lipgloss
  # Style range applied over display columns (start...finish).
  class Range
    getter start : Int32
    getter finish : Int32
    getter style : Style

    def initialize(@start : Int32, @finish : Int32, @style : Style)
    end

    def includes?(col : Int32) : Bool
      col >= @start && col < @finish
    end
  end

  def self.style_ranges(str : String, ranges : Array(Range)) : String
    return str if ranges.empty?
    # NOTE: Ranges are in display-cell offsets on the ANSI-stripped string.
    sorted = ranges.sort_by(&.start)
    stripped = Lipgloss::Text.strip_ansi(str)

    last_idx = 0
    String.build do |io|
      sorted.each do |rng|
        if rng.start > last_idx
          io << ansi_cut(str, last_idx, rng.start)
        end

        io << rng.style.render(plain_cut(stripped, rng.start, rng.finish))
        last_idx = rng.finish
      end

      io << ansi_truncate_left(str, last_idx)
    end
  end

  private def self.plain_cut(str : String, start_col : Int32, end_col : Int32) : String
    return "" if end_col <= start_col

    col = 0
    String.build do |io|
      str.each_grapheme do |g|
        gs = g.to_s
        w = UnicodeCharWidth.width(gs)
        break if col >= end_col
        if col + w > start_col && col < end_col
          io << gs
        end
        col += w
      end
    end
  end

  private def self.ansi_cut(str : String, start_col : Int32, end_col : Int32) : String
    return "" if end_col <= start_col

    bytes = str.to_slice
    idx = 0
    col = 0
    started = false
    reached_end = false

    String.build do |io|
      while idx < bytes.size
        started = true if !started && col >= start_col

        # Handle CSI sequences (treated as zero-width).
        if bytes[idx] == 0x1b_u8
          seq, next_idx = read_csi(bytes, idx)
          if started && (!reached_end || col == end_col)
            io << seq
          end
          idx = next_idx
          next
        end

        # Read next grapheme (no ANSI within).
        slice = bytes[idx..]
        g = next_grapheme(slice)
        break if g.nil?
        grapheme, grapheme_bytes = g
        w = UnicodeCharWidth.width(grapheme)

        if !started && col >= start_col
          started = true
        end

        if started
          if col >= start_col && col + w <= end_col
            io << grapheme
          else
            reached_end = true if col >= end_col || col + w >= end_col
          end
        end

        idx += grapheme_bytes
        col += w

        reached_end = true if started && col >= end_col

        # Once we've reached the end, include any following CSI sequences at
        # this boundary (zero width) and then stop.
        if reached_end
          while idx < bytes.size && bytes[idx] == 0x1b_u8
            seq, next_idx = read_csi(bytes, idx)
            io << seq
            idx = next_idx
          end
          break
        end
      end
    end
  end

  private def self.ansi_truncate_left(str : String, start_col : Int32) : String
    return str if start_col <= 0

    bytes = str.to_slice
    idx = 0
    col = 0
    prefix = String::Builder.new

    while idx < bytes.size && col < start_col
      if bytes[idx] == 0x1b_u8
        seq, next_idx = read_csi(bytes, idx)
        prefix << seq
        idx = next_idx
        next
      end

      g = next_grapheme(bytes[idx..])
      break if g.nil?
      grapheme, grapheme_bytes = g
      w = UnicodeCharWidth.width(grapheme)
      idx += grapheme_bytes
      col += w
    end

    prefix.to_s + ansi_cut(str, start_col, Int32::MAX)
  end

  private def self.read_csi(bytes : Bytes, start_idx : Int32) : {String, Int32}
    idx = start_idx
    return {String.new(bytes[idx, 1]), idx + 1} unless idx < bytes.size

    idx += 1
    return {String.new(bytes[start_idx, 1]), idx} unless idx < bytes.size && bytes[idx] == '['.ord.to_u8
    idx += 1

    while idx < bytes.size
      b = bytes[idx]
      idx += 1
      # Final byte (we only really care about SGR 'm', but treat any CSI as 0-width).
      break if ('A'.ord..'Z'.ord).includes?(b) || ('a'.ord..'z'.ord).includes?(b)
    end

    {String.new(bytes[start_idx, idx - start_idx]), idx}
  end

  private def self.next_grapheme(bytes : Bytes) : {String, Int32}?
    # Decode a grapheme from the byte slice.
    s = String.new(bytes)
    first = nil
    s.each_grapheme do |g|
      first = g.to_s
      break
    end
    return unless first
    {first, first.bytesize}
  end

  # Apply styles to specific rune (grapheme) indices.
  def self.style_runes(str : String, indices : Array(Int32), matched : Style, unmatched : Style) : String
    targets = indices.to_set
    out = String::Builder.new

    group = String::Builder.new
    current_matches : Bool? = nil

    str.each_char_with_index do |ch, i|
      matches = targets.includes?(i)
      if current_matches.nil?
        current_matches = matches
      end

      if matches != current_matches
        out << (current_matches ? matched : unmatched).render(group.to_s)
        group = String::Builder.new
        current_matches = matches
      end

      group << ch
    end

    unless current_matches.nil?
      out << (current_matches ? matched : unmatched).render(group.to_s)
    end

    out.to_s
  end
end
