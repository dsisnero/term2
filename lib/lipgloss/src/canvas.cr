require "uniwidth"
require "./geometry"
require "./range"
require "./style"

module Lipgloss
  class Cell
    @content : String
    @on_change : Proc(String, Nil)?

    def initialize(@content : String = " ", @on_change : Proc(String, Nil)? = nil)
    end

    def content : String
      @content
    end

    def content=(value : String) : String
      @content = value
      @on_change.try &.call(value)
      value
    end
  end

  # Canvas is a cell buffer for composing drawables like layers.
  class Canvas
    @width : Int32
    @height : Int32
    @lines : Array(String)

    def initialize(width : Int32, height : Int32)
      @width = width
      @height = height
      @lines = Array.new(@height) { " " * @width }
    end

    def width : Int32
      @width
    end

    def height : Int32
      @height
    end

    def bounds : Rectangle
      Rectangle.from_xywh(0, 0, @width, @height)
    end

    def resize(width : Int32, height : Int32) : Nil
      @width = width
      @height = height
      @lines = Array.new(@height) { " " * @width }
    end

    def clear : Nil
      @lines = Array.new(@height) { " " * @width }
    end

    def cell_at(x : Int32, y : Int32) : Cell
      return Cell.new if x < 0 || y < 0 || y >= @height || x >= @width
      line = @lines[y]
      Cell.new(ansi_cut(line, x, x + 1), ->(content : String) { set_cell(x, y, Cell.new(content)) })
    end

    def set_cell(x : Int32, y : Int32, cell : Cell) : Nil
      return if x < 0 || y < 0 || y >= @height || x >= @width
      draw_line(cell.content, x, y)
    end

    def compose(drawable) : Canvas
      drawable.draw(self, bounds)
      self
    end

    def draw(scr : Canvas, area : Rectangle) : Nil
      area_height = area.dy
      return if area_height <= 0

      (0...area_height).each do |row|
        src_y = row
        next if src_y < 0 || src_y >= @height
        scr.draw_string(@lines[src_y], area.min.x, area.min.y + row)
      end
    end

    def render : String
      @lines.map(&.rstrip(' ')).join("\n")
    end

    def draw_string(str : String, x : Int32, y : Int32) : Nil
      return if @width <= 0 || @height <= 0
      lines = str.split("\n", remove_empty: false)
      lines.each_with_index do |line, idx|
        draw_line(line, x, y + idx)
      end
    end

    private def draw_line(line : String, x : Int32, y : Int32) : Nil
      return if y < 0 || y >= @height

      start_col = x
      content = line
      if start_col < 0
        content = ansi_cut(content, -start_col, Int32::MAX)
        start_col = 0
      end

      return if start_col >= @width

      max_width = @width - start_col
      content = ansi_cut(content, 0, max_width)
      return if content.empty?

      base = ensure_width(@lines[y], @width)
      prefix = ansi_cut(base, 0, start_col)
      suffix = ansi_truncate_left(base, start_col + Lipgloss.width(content))
      @lines[y] = prefix + content + suffix
    end

    private def ensure_width(line : String, width : Int32) : String
      w = Lipgloss.width(line)
      return line if w >= width
      line + (" " * (width - w))
    end

    # ANSI helpers adapted from range slicing for safe composition.
    private def ansi_cut(str : String, start_col : Int32, end_col : Int32) : String
      return "" if end_col <= start_col

      bytes = str.to_slice
      idx = 0
      col = 0
      started = false
      reached_end = false

      String.build do |io|
        while idx < bytes.size
          started = true if !started && col >= start_col

          if bytes[idx] == 0x1b_u8
            seq, next_idx = read_csi(bytes, idx)
            io << seq if started && (!reached_end || col == end_col)
            idx = next_idx
            next
          end

          slice = bytes[idx..]
          grapheme = next_grapheme(slice)
          break if grapheme.nil?
          grapheme, grapheme_bytes = grapheme
          w = UnicodeCharWidth.width(grapheme)

          started = true if !started && col >= start_col

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

    private def ansi_truncate_left(str : String, start_col : Int32) : String
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

        grapheme = next_grapheme(bytes[idx..])
        break if grapheme.nil?
        grapheme, grapheme_bytes = grapheme
        w = UnicodeCharWidth.width(grapheme)
        idx += grapheme_bytes
        col += w
      end

      prefix.to_s + ansi_cut(str, start_col, Int32::MAX)
    end

    private def read_csi(bytes : Bytes, start_idx : Int32) : {String, Int32}
      idx = start_idx
      return {String.new(bytes[idx, 1]), idx + 1} unless idx < bytes.size

      idx += 1
      return {String.new(bytes[start_idx, 1]), idx} unless idx < bytes.size && bytes[idx] == '['.ord.to_u8
      idx += 1

      while idx < bytes.size
        b = bytes[idx]
        idx += 1
        break if ('A'.ord..'Z'.ord).includes?(b) || ('a'.ord..'z'.ord).includes?(b)
      end

      {String.new(bytes[start_idx, idx - start_idx]), idx}
    end

    private def next_grapheme(bytes : Bytes) : {String, Int32}?
      s = String.new(bytes)
      first = nil
      s.each_grapheme do |grapheme|
        first = grapheme.to_s
        break
      end
      return unless first
      {first, first.bytesize}
    end
  end

  def self.new_canvas(width : Int32, height : Int32) : Canvas
    Canvas.new(width, height)
  end
end
