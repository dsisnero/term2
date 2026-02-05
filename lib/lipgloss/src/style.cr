# Lipgloss Style - A complete port of Lipgloss styling
# This is the core styling primitive for Lipgloss

require "./color_profile"
require "./view"
require "uniwidth"
require "cellwrap"

module Lipgloss
  # Global setting for adaptive colors
  class_property? has_dark_background : Bool = true

  # Tab width default
  TAB_WIDTH_DEFAULT = 4

  # NoTabConversion can be passed to TabWidth to disable tab replacement
  NO_TAB_CONVERSION = -1

  # Position for alignment
  enum Position
    Left   = 0
    Center = 1
    Right  = 2
    Top    = 3
    Bottom = 4
  end

  # Edges represents the four sides of a box (top, right, bottom, left)
  struct Edges
    property top : Int32 = 0
    property right : Int32 = 0
    property bottom : Int32 = 0
    property left : Int32 = 0

    def initialize(@top = 0, @right = 0, @bottom = 0, @left = 0)
    end

    def self.all(val : Int32)
      new(val, val, val, val)
    end

    def self.symmetric(vertical : Int32, horizontal : Int32)
      new(vertical, horizontal, vertical, horizontal)
    end

    def horizontal
      @left + @right
    end

    def vertical
      @top + @bottom
    end
  end

  # Border contains a series of values which comprise the various parts of a border
  struct Border
    property top : String = ""
    property bottom : String = ""
    property left : String = ""
    property right : String = ""
    property top_left : String = ""
    property top_right : String = ""
    property bottom_left : String = ""
    property bottom_right : String = ""
    property middle_left : String = ""
    property middle_right : String = ""
    property middle : String = ""
    property middle_top : String = ""
    property middle_bottom : String = ""

    def initialize(@top = "", @bottom = "", @left = "", @right = "",
                   @top_left = "", @top_right = "", @bottom_left = "", @bottom_right = "",
                   @middle_left = "", @middle_right = "", @middle = "",
                   @middle_top = "", @middle_bottom = "")
    end

    def self.normal
      new("─", "─", "│", "│", "┌", "┐", "└", "┘", "├", "┤", "┼", "┬", "┴")
    end

    def self.rounded
      new("─", "─", "│", "│", "╭", "╮", "╰", "╯", "├", "┤", "┼", "┬", "┴")
    end

    def self.thick
      new("━", "━", "┃", "┃", "┏", "┓", "┗", "┛", "┣", "┫", "╋", "┳", "┻")
    end

    def self.double
      new("═", "═", "║", "║", "╔", "╗", "╚", "╝", "╠", "╣", "╬", "╦", "╩")
    end

    def self.hidden
      new(" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ")
    end

    def self.block
      new("█", "█", "█", "█", "█", "█", "█", "█", "█", "█", "█", "█", "█")
    end

    def self.outer_half_block
      new("▀", "▄", "▌", "▐", "▛", "▜", "▙", "▟", "▌", "▐", "┼", "▀", "▄")
    end

    def self.inner_half_block
      new("▄", "▀", "▐", "▌", "▗", "▖", "▝", "▘", "▐", "▌", "┼", "▄", "▀")
    end

    @[Deprecated("Use `top_size` instead")]
    def get_top_size : Int32
      @top.empty? ? 0 : 1
    end

    def top_size : Int32
      @top.empty? ? 0 : 1
    end

    @[Deprecated("Use `bottom_size` instead")]
    def get_bottom_size : Int32
      @bottom.empty? ? 0 : 1
    end

    def bottom_size : Int32
      @bottom.empty? ? 0 : 1
    end

    @[Deprecated("Use `left_size` instead")]
    def get_left_size : Int32
      @left.empty? ? 0 : 1
    end

    def left_size : Int32
      @left.empty? ? 0 : 1
    end

    @[Deprecated("Use `right_size` instead")]
    def get_right_size : Int32
      @right.empty? ? 0 : 1
    end

    def right_size : Int32
      @right.empty? ? 0 : 1
    end
  end

  # Color represents terminal colors (ANSI, 256-color, or TrueColor)
  struct Color
    enum Type
      Named
      Indexed
      RGB
    end

    getter type : Type
    getter value : Int32 | Tuple(Int32, Int32, Int32)

    # Named colors (ANSI 16)
    BLACK   = new(Type::Named, 0)
    RED     = new(Type::Named, 1)
    GREEN   = new(Type::Named, 2)
    YELLOW  = new(Type::Named, 3)
    BLUE    = new(Type::Named, 4)
    MAGENTA = new(Type::Named, 5)
    CYAN    = new(Type::Named, 6)
    WHITE   = new(Type::Named, 7)

    # Bright named colors
    BRIGHT_BLACK   = new(Type::Named, 8)
    BRIGHT_RED     = new(Type::Named, 9)
    BRIGHT_GREEN   = new(Type::Named, 10)
    BRIGHT_YELLOW  = new(Type::Named, 11)
    BRIGHT_BLUE    = new(Type::Named, 12)
    BRIGHT_MAGENTA = new(Type::Named, 13)
    BRIGHT_CYAN    = new(Type::Named, 14)
    BRIGHT_WHITE   = new(Type::Named, 15)

    def initialize(@type : Type, @value : Int32 | Tuple(Int32, Int32, Int32))
    end

    # Create from hex string like "#FF5500", "FF5500", "#F50", or "F50"
    def self.from_hex(hex : String) : Color
      hex = hex.lstrip('#')

      # Handle short hex format (#RGB -> #RRGGBB)
      if hex.size == 3
        r = hex[0].to_s * 2
        g = hex[1].to_s * 2
        b = hex[2].to_s * 2
        hex = r + g + b
      end

      return BLACK if hex.size < 6

      begin
        r = hex[0, 2].to_i(16)
        g = hex[2, 2].to_i(16)
        b = hex[4, 2].to_i(16)
        rgb(r, g, b)
      rescue ArgumentError
        BLACK
      end
    end

    # Compatibility alias used by some example ports.
    def self.hex(hex : String) : Color
      from_hex(hex)
    end

    # Create an indexed color (0-255)
    def self.indexed(index : Int32) : Color
      new(Type::Indexed, index.clamp(0, 255))
    end

    # Create an RGB color
    def self.rgb(r : Int32, g : Int32, b : Int32) : Color
      new(Type::RGB, {r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255)})
    end

    # Get foreground escape codes
    def foreground_codes : Array(Int32)
      case @type
      when Type::Named
        val = @value.as(Int32)
        if val < 8
          [30 + val]
        else
          [90 + (val - 8)]
        end
      when Type::Indexed
        [38, 5, @value.as(Int32)]
      when Type::RGB
        r, g, b = @value.as(Tuple(Int32, Int32, Int32))
        [38, 2, r, g, b]
      else
        [] of Int32
      end
    end

    # Get background escape codes
    def background_codes : Array(Int32)
      case @type
      when Type::Named
        val = @value.as(Int32)
        if val < 8
          [40 + val]
        else
          [100 + (val - 8)]
        end
      when Type::Indexed
        [48, 5, @value.as(Int32)]
      when Type::RGB
        r, g, b = @value.as(Tuple(Int32, Int32, Int32))
        [48, 2, r, g, b]
      else
        [] of Int32
      end
    end

    # For equality comparison
    def ==(other : Color) : Bool
      @type == other.type && @value == other.value
    end

    ANSI16_PALETTE = [
      {0, 0, 0},       # 0 black
      {205, 0, 0},     # 1 red
      {0, 205, 0},     # 2 green
      {205, 205, 0},   # 3 yellow
      {0, 0, 238},     # 4 blue
      {205, 0, 205},   # 5 magenta
      {0, 205, 205},   # 6 cyan
      {229, 229, 229}, # 7 white
      {127, 127, 127}, # 8 bright black
      {255, 0, 0},     # 9 bright red
      {0, 255, 0},     # 10 bright green
      {255, 255, 0},   # 11 bright yellow
      {92, 92, 255},   # 12 bright blue
      {255, 0, 255},   # 13 bright magenta
      {0, 255, 255},   # 14 bright cyan
      {255, 255, 255}, # 15 bright white
    ]

    def to_rgb : Tuple(Int32, Int32, Int32)
      case @type
      when Type::RGB
        @value.as(Tuple(Int32, Int32, Int32))
      when Type::Named
        ANSI16_PALETTE[@value.as(Int32).clamp(0, 15)]
      when Type::Indexed
        Color.ansi256_index_to_rgb(@value.as(Int32))
      else
        {0, 0, 0}
      end
    end

    def self.rgb_to_ansi16_index(r : Int32, g : Int32, b : Int32) : Int32
      best_idx = 0
      best_dist = Int64::MAX

      ANSI16_PALETTE.each_with_index do |(pr, pg, pb), idx|
        dr = (r - pr).to_i64
        dg = (g - pg).to_i64
        db = (b - pb).to_i64
        dist = dr * dr + dg * dg + db * db
        if dist < best_dist
          best_dist = dist
          best_idx = idx
        end
      end

      best_idx
    end

    def self.ansi256_index_to_rgb(index : Int32) : Tuple(Int32, Int32, Int32)
      idx = index.clamp(0, 255)

      if idx < 16
        return ANSI16_PALETTE[idx]
      end

      # 6x6x6 color cube: 16-231
      if idx <= 231
        i = idx - 16
        r = i // 36
        g = (i % 36) // 6
        b = i % 6
        steps = [0, 95, 135, 175, 215, 255]
        return {steps[r], steps[g], steps[b]}
      end

      # Grayscale ramp: 232-255
      gray = 8 + (idx - 232) * 10
      {gray, gray, gray}
    end

    def self.rgb_to_ansi256_index(r : Int32, g : Int32, b : Int32) : Int32
      r = r.clamp(0, 255)
      g = g.clamp(0, 255)
      b = b.clamp(0, 255)

      if r == g && g == b
        if r < 8
          return 16
        end
        if r > 238
          return 231
        end
        return 232 + ((r - 8) / 10.0).round.to_i.clamp(0, 23)
      end

      steps = [0, 95, 135, 175, 215, 255]
      rc = steps.min_by { |s| (s - r).abs }
      gc = steps.min_by { |s| (s - g).abs }
      bc = steps.min_by { |s| (s - b).abs }
      ri = steps.index!(rc)
      gi = steps.index!(gc)
      bi = steps.index!(bc)

      16 + (36 * ri) + (6 * gi) + bi
    end
  end

  # Text utilities for measuring and manipulating styled text
  module Text
    # Strip ANSI escape codes from text.
    #
    # Handles common CSI/OSC sequences and Bubblezone markers (CSI ... z).
    def self.strip_ansi(text : String) : String
      bytes = text.to_slice
      String.build do |io|
        i = 0
        while i < bytes.size
          if bytes[i] == 0x1b_u8
            i = consume_escape_sequence(bytes, i)
            next
          end
          io.write_byte(bytes[i])
          i += 1
        end
      end
    end

    # Calculate the display width of text (ignoring ANSI codes)
    def self.width(text : String) : Int32
      bytes = text.to_slice
      return 0 if bytes.empty?

      max_width = 0
      cur_width = 0
      i = 0

      while i < bytes.size
        b = bytes[i]

        if b == 0x1b_u8
          i = consume_escape_sequence(bytes, i)
          next
        end

        if b == '\n'.ord.to_u8
          max_width = cur_width if cur_width > max_width
          cur_width = 0
          i += 1
          next
        end

        if b == '\r'.ord.to_u8
          cur_width = 0
          i += 1
          next
        end

        cp, len = decode_utf8(bytes, i)
        cur_width += cell_width_codepoint(cp)
        i += len
      end

      max_width = cur_width if cur_width > max_width
      max_width
    end

    # Calculate text height based on newline count.
    def self.height(text : String) : Int32
      bytes = text.to_slice
      return 0 if bytes.empty?

      visible = false
      lines = 1
      i = 0
      while i < bytes.size
        b = bytes[i]
        if b == 0x1b_u8
          i = consume_escape_sequence(bytes, i)
          next
        end
        visible = true
        lines += 1 if b == '\n'.ord.to_u8
        i += 1
      end

      visible ? lines : 0
    end

    # Get width of a single character (handles wide chars)
    def self.char_width(c : Char) : Int32
      UnicodeCharWidth.width(c)
    end

    # Truncate text to width, respecting ANSI codes.
    def self.truncate(text : String, width : Int32) : String
      return text if width <= 0

      visible_width = 0

      String.build do |io|
        bytes = text.to_slice
        i = 0
        while i < bytes.size
          b = bytes[i]

          if b == 0x1b_u8
            j = consume_escape_sequence(bytes, i)
            io.write(bytes[i, j - i])
            i = j
            next
          end

          cp, len = decode_utf8(bytes, i)
          cw = cell_width_codepoint(cp)
          break if visible_width + cw > width
          io.write(bytes[i, len])
          visible_width += cw
          i += len
        end
      end
    end

    private def self.consume_escape_sequence(bytes : Bytes, i : Int32) : Int32
      return i + 1 if i + 1 >= bytes.size

      second = bytes[i + 1]

      # CSI: ESC [ ... final-byte(@-~)
      if second == '['.ord.to_u8
        j = i + 2
        while j < bytes.size
          final = bytes[j]
          j += 1
          break if final >= 0x40_u8 && final <= 0x7E_u8
        end
        return j
      end

      # OSC: ESC ] ... BEL or ST(ESC \)
      if second == ']'.ord.to_u8
        j = i + 2
        while j < bytes.size
          b = bytes[j]
          j += 1
          break if b == 0x07_u8
          if b == 0x1b_u8 && j < bytes.size && bytes[j] == '\\'.ord.to_u8
            j += 1
            break
          end
        end
        return j
      end

      # Other single-char escape sequence
      i + 2
    end

    private def self.decode_utf8(bytes : Bytes, idx : Int32) : {Int32, Int32}
      b0 = bytes[idx]
      return {b0.to_i32, 1} if b0 < 0x80_u8

      len =
        if (b0 & 0xE0_u8) == 0xC0_u8
          2
        elsif (b0 & 0xF0_u8) == 0xE0_u8
          3
        elsif (b0 & 0xF8_u8) == 0xF0_u8
          4
        else
          1
        end
      len = 1 if idx + len > bytes.size

      cp = 0_i32
      case len
      when 2
        cp = ((b0 & 0x1F_u8).to_i32 << 6) | (bytes[idx + 1] & 0x3F_u8).to_i32
      when 3
        cp = ((b0 & 0x0F_u8).to_i32 << 12) |
             ((bytes[idx + 1] & 0x3F_u8).to_i32 << 6) |
             (bytes[idx + 2] & 0x3F_u8).to_i32
      when 4
        cp = ((b0 & 0x07_u8).to_i32 << 18) |
             ((bytes[idx + 1] & 0x3F_u8).to_i32 << 12) |
             ((bytes[idx + 2] & 0x3F_u8).to_i32 << 6) |
             (bytes[idx + 3] & 0x3F_u8).to_i32
      else
        cp = b0.to_i32
      end

      {cp, len}
    end

    private def self.cell_width_codepoint(cp : Int32) : Int32
      return 0 if cp == 0x200D
      return 0 if cp == 0xFE0E || cp == 0xFE0F
      return 0 if (0x1F3FB..0x1F3FF).includes?(cp)
      return 0 if combining_mark_codepoint?(cp)

      w = UnicodeCharWidth.width(cp)
      if w == 1 && (0x1F000..0x1FFFF).includes?(cp)
        2
      else
        w
      end
    end

    private def self.combining_mark_codepoint?(cp : Int32) : Bool
      return true if (0x0300..0x036F).includes?(cp)
      return true if (0x1AB0..0x1AFF).includes?(cp)
      return true if (0x1DC0..0x1DFF).includes?(cp)
      return true if (0x20D0..0x20FF).includes?(cp)
      return true if (0xFE20..0xFE2F).includes?(cp)

      return true if cp == 0x0E31
      return true if (0x0E34..0x0E3A).includes?(cp)
      return true if (0x0E47..0x0E4E).includes?(cp)
      false
    end
  end

  # AdaptiveColor provides different colors for light and dark backgrounds
  struct AdaptiveColor
    getter light : Color
    getter dark : Color

    def initialize(@light : Color, @dark : Color)
    end

    def resolve : Color
      Lipgloss.has_dark_background? ? @dark : @light
    end
  end

  # CompleteColor provides ANSI16, ANSI256, and TrueColor options
  struct CompleteColor
    getter ansi : Color?
    getter ansi256 : Color?
    getter true_color : Color?

    def initialize(@ansi : Color? = nil, @ansi256 : Color? = nil, @true_color : Color? = nil)
    end

    # Select best color for current terminal
    def resolve : Color?
      # For now, prefer true color > ansi256 > ansi
      @true_color || @ansi256 || @ansi
    end
  end

  # CompleteAdaptiveColor provides CompleteColor options for light/dark backgrounds.
  struct CompleteAdaptiveColor
    getter light : CompleteColor
    getter dark : CompleteColor

    def initialize(@light : CompleteColor, @dark : CompleteColor)
    end

    def resolve : CompleteColor
      Lipgloss.has_dark_background? ? @dark : @light
    end
  end

  # NoColor represents the explicit absence of color styling.
  struct NoColor
  end

  # Style is the core styling primitive - a complete Lipgloss port
  class Style
    WRAP_CACHE_MAX = 256

    @@wrap_cache = Hash(Tuple(String, Int32), String).new
    @@wrap_cache_order = Deque(Tuple(String, Int32)).new
    @@wrap_cache_lock = Mutex.new

    # Bitflags for which properties are set
    @[Flags]
    enum Props : UInt64
      Bold
      Italic
      Underline
      Strikethrough
      Reverse
      Blink
      Faint
      UnderlineSpaces
      StrikethroughSpaces
      ColorWhitespace
      Foreground
      Background
      Width
      Height
      AlignHorizontal
      AlignVertical
      PaddingTop
      PaddingRight
      PaddingBottom
      PaddingLeft
      MarginTop
      MarginRight
      MarginBottom
      MarginLeft
      MarginBackground
      BorderStyle
      BorderTop
      BorderRight
      BorderBottom
      BorderLeft
      BorderTopForeground
      BorderRightForeground
      BorderBottomForeground
      BorderLeftForeground
      BorderTopBackground
      BorderRightBackground
      BorderBottomBackground
      BorderLeftBackground
      Inline
      MaxWidth
      MaxHeight
      TabWidth
      Transform
    end

    @props : Props = Props::None

    # String value for SetString
    @value : String = ""

    # Boolean attributes stored as a bitfield for efficiency
    @attrs : UInt32 = 0

    # Color properties
    @fg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil = nil
    @bg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil = nil

    private COLORS = %w[black red green yellow blue magenta cyan bright_gray dark_gray bright_red bright_green bright_yellow bright_blue bright_magenta bright_cyan white]

    {% for name in COLORS %}
      def {{ name.id }}
         @fg_color = Color::{{ name.upcase.id }}
         self
      end

      def on_{{ name.id }}
        @bg_color = Color::{{ name.upcase.id }}
        self
      end

    {% end %}

    # Dimensions
    @width : Int32 = 0
    @height : Int32 = 0
    @max_width : Int32 = 0
    @max_height : Int32 = 0

    # Alignment
    @align_horizontal : Position = Position::Left
    @align_vertical : Position = Position::Top

    # Padding
    @padding_top : Int32 = 0
    @padding_right : Int32 = 0
    @padding_bottom : Int32 = 0
    @padding_left : Int32 = 0

    # Margin
    @margin_top : Int32 = 0
    @margin_right : Int32 = 0
    @margin_bottom : Int32 = 0
    @margin_left : Int32 = 0
    @margin_bg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil = nil

    # Border
    @border_style : Border = Border.new
    @border_top_fg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil = nil
    @border_right_fg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil = nil
    @border_bottom_fg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil = nil
    @border_left_fg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil = nil
    @border_top_bg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil = nil
    @border_right_bg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil = nil
    @border_bottom_bg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil = nil
    @border_left_bg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil = nil

    # Other
    @tab_width : Int32 = TAB_WIDTH_DEFAULT
    @transform : Proc(String, String)? = nil

    # StyleRenderer for lipgloss-like color/profile behavior
    @style_renderer : StyleRenderer = StyleRenderer.default

    def initialize
    end

    # Create a new style (factory method like Lipgloss)
    def self.new_style : Style
      new
    end

    def renderer(r : StyleRenderer) : Style
      @style_renderer = r
      Lipgloss.has_dark_background = r.has_dark_background
      self
    end

    # ========== SETTERS (Fluent API) ==========

    # Text formatting
    def bold(v : Bool = true) : Style
      set_bool(Props::Bold, v)
    end

    def italic(v : Bool = true) : Style
      set_bool(Props::Italic, v)
    end

    def underline(v : Bool = true) : Style
      set_bool(Props::Underline, v)
    end

    def strikethrough(v : Bool = true) : Style
      set_bool(Props::Strikethrough, v)
    end

    def reverse(v : Bool = true) : Style
      set_bool(Props::Reverse, v)
    end

    def blink(v : Bool = true) : Style
      set_bool(Props::Blink, v)
    end

    def faint(v : Bool = true) : Style
      set_bool(Props::Faint, v)
    end

    def underline_spaces(v : Bool = true) : Style
      set_bool(Props::UnderlineSpaces, v)
    end

    def strikethrough_spaces(v : Bool = true) : Style
      set_bool(Props::StrikethroughSpaces, v)
    end

    def color_whitespace(v : Bool = true) : Style
      set_bool(Props::ColorWhitespace, v)
    end

    # Colors
    def foreground(c : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor) : Style
      @fg_color = c
      @props |= Props::Foreground
      self
    end

    def foreground(hex : String) : Style
      foreground(Color.from_hex(hex))
    end

    # Compatibility helpers for older example code.
    def fg_indexed(idx : Int32) : Style
      foreground(Color.indexed(idx))
    end

    def fg_hex(hex : String) : Style
      foreground(hex)
    end

    def background(c : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor) : Style
      @bg_color = c
      @props |= Props::Background
      self
    end

    def background(hex : String) : Style
      background(Color.from_hex(hex))
    end

    # Compatibility helpers for older example code.
    def bg_indexed(idx : Int32) : Style
      background(Color.indexed(idx))
    end

    def bg_hex(hex : String) : Style
      background(hex)
    end

    # Dimensions
    def width(w : Int32) : Style
      @width = Math.max(0, w)
      @props |= Props::Width
      self
    end

    def height(h : Int32) : Style
      @height = Math.max(0, h)
      @props |= Props::Height
      self
    end

    def max_width(w : Int32) : Style
      @max_width = Math.max(0, w)
      @props |= Props::MaxWidth
      self
    end

    def max_height(h : Int32) : Style
      @max_height = Math.max(0, h)
      @props |= Props::MaxHeight
      self
    end

    # Alignment - single argument sets horizontal
    def align(p : Position) : Style
      @align_horizontal = p
      @props |= Props::AlignHorizontal
      self
    end

    # Alignment - two arguments set horizontal and vertical
    def align(h : Position, v : Position) : Style
      @align_horizontal = h
      @align_vertical = v
      @props |= Props::AlignHorizontal | Props::AlignVertical
      self
    end

    def align_horizontal(p : Position) : Style
      @align_horizontal = p
      @props |= Props::AlignHorizontal
      self
    end

    def align_vertical(p : Position) : Style
      @align_vertical = p
      @props |= Props::AlignVertical
      self
    end

    # Padding - CSS shorthand style
    def padding(all : Int32) : Style
      padding(all, all, all, all)
    end

    def padding(vertical : Int32, horizontal : Int32) : Style
      padding(vertical, horizontal, vertical, horizontal)
    end

    def padding(top : Int32, horizontal : Int32, bottom : Int32) : Style
      padding(top, horizontal, bottom, horizontal)
    end

    def padding(top : Int32, right : Int32, bottom : Int32, left : Int32) : Style
      @padding_top = Math.max(0, top)
      @padding_right = Math.max(0, right)
      @padding_bottom = Math.max(0, bottom)
      @padding_left = Math.max(0, left)
      @props |= Props::PaddingTop | Props::PaddingRight | Props::PaddingBottom | Props::PaddingLeft
      self
    end

    def padding_top(i : Int32) : Style
      @padding_top = Math.max(0, i)
      @props |= Props::PaddingTop
      self
    end

    def padding_right(i : Int32) : Style
      @padding_right = Math.max(0, i)
      @props |= Props::PaddingRight
      self
    end

    def padding_bottom(i : Int32) : Style
      @padding_bottom = Math.max(0, i)
      @props |= Props::PaddingBottom
      self
    end

    def padding_left(i : Int32) : Style
      @padding_left = Math.max(0, i)
      @props |= Props::PaddingLeft
      self
    end

    # Margin - CSS shorthand style
    def margin(all : Int32) : Style
      margin(all, all, all, all)
    end

    def margin(vertical : Int32, horizontal : Int32) : Style
      margin(vertical, horizontal, vertical, horizontal)
    end

    def margin(top : Int32, horizontal : Int32, bottom : Int32) : Style
      margin(top, horizontal, bottom, horizontal)
    end

    def margin(top : Int32, right : Int32, bottom : Int32, left : Int32) : Style
      @margin_top = Math.max(0, top)
      @margin_right = Math.max(0, right)
      @margin_bottom = Math.max(0, bottom)
      @margin_left = Math.max(0, left)
      @props |= Props::MarginTop | Props::MarginRight | Props::MarginBottom | Props::MarginLeft
      self
    end

    def margin_top(i : Int32) : Style
      @margin_top = Math.max(0, i)
      @props |= Props::MarginTop
      self
    end

    def margin_right(i : Int32) : Style
      @margin_right = Math.max(0, i)
      @props |= Props::MarginRight
      self
    end

    def margin_bottom(i : Int32) : Style
      @margin_bottom = Math.max(0, i)
      @props |= Props::MarginBottom
      self
    end

    def margin_left(i : Int32) : Style
      @margin_left = Math.max(0, i)
      @props |= Props::MarginLeft
      self
    end

    def margin_background(c : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor) : Style
      @margin_bg_color = c
      @props |= Props::MarginBackground
      self
    end

    # Border
    # [FIX] Explicit overload for single argument to satisfy compiler
    def border(b : Border) : Style
      border(b, true, true, true, true)
    end

    def border(b : Border, *sides : Bool) : Style
      @border_style = b
      @props |= Props::BorderStyle

      # Parse sides argument similar to CSS
      top, right, bottom, left = parse_sides_bool(sides.to_a)

      border_top(top)
      border_right(right)
      border_bottom(bottom)
      border_left(left)
      self
    end

    def border_style(b : Border) : Style
      @border_style = b
      @props |= Props::BorderStyle
      self
    end

    def border_top(v : Bool = true) : Style
      set_bool(Props::BorderTop, v)
    end

    def border_right(v : Bool = true) : Style
      set_bool(Props::BorderRight, v)
    end

    def border_bottom(v : Bool = true) : Style
      set_bool(Props::BorderBottom, v)
    end

    def border_left(v : Bool = true) : Style
      set_bool(Props::BorderLeft, v)
    end

    def border_foreground(c : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor) : Style
      @border_top_fg_color = c
      @border_right_fg_color = c
      @border_bottom_fg_color = c
      @border_left_fg_color = c
      @props |= Props::BorderTopForeground | Props::BorderRightForeground |
                Props::BorderBottomForeground | Props::BorderLeftForeground
      self
    end

    def border_top_foreground(c : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor) : Style
      @border_top_fg_color = c
      @props |= Props::BorderTopForeground
      self
    end

    def border_right_foreground(c : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor) : Style
      @border_right_fg_color = c
      @props |= Props::BorderRightForeground
      self
    end

    def border_bottom_foreground(c : Color | AdaptiveColor | CompleteAdaptiveColor | CompleteColor | NoColor) : Style
      @border_bottom_fg_color = c
      @props |= Props::BorderBottomForeground
      self
    end

    def border_left_foreground(c : Color | AdaptiveColor | CompleteAdaptiveColor | CompleteColor | NoColor) : Style
      @border_left_fg_color = c
      @props |= Props::BorderLeftForeground
      self
    end

    def border_background(c : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor) : Style
      @border_top_bg_color = c
      @border_right_bg_color = c
      @border_bottom_bg_color = c
      @border_left_bg_color = c
      @props |= Props::BorderTopBackground | Props::BorderRightBackground |
                Props::BorderBottomBackground | Props::BorderLeftBackground
      self
    end

    def border_top_background(c : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor) : Style
      @border_top_bg_color = c
      @props |= Props::BorderTopBackground
      self
    end

    def border_right_background(c : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor) : Style
      @border_right_bg_color = c
      @props |= Props::BorderRightBackground
      self
    end

    def border_bottom_background(c : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor) : Style
      @border_bottom_bg_color = c
      @props |= Props::BorderBottomBackground
      self
    end

    def border_left_background(c : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor) : Style
      @border_left_bg_color = c
      @props |= Props::BorderLeftBackground
      self
    end

    # Other
    def inline(v : Bool = true) : Style
      set_bool(Props::Inline, v)
    end

    def tab_width(n : Int32) : Style
      @tab_width = n < -1 ? -1 : n
      @props |= Props::TabWidth
      self
    end

    def transform(fn : Proc(String, String)) : Style
      @transform = fn
      @props |= Props::Transform
      self
    end

    # SetString sets the underlying string value for the style
    @[Deprecated("Use `string=` instead")]
    def set_string(*strs : String) : Style
      self.string = strs.join(" ")
    end

    def string=(str : String) : Style
      @value = str
      self
    end

    # ========== GETTERS ==========

    # Crystal-idiomatic boolean getters
    def bold? : Bool
      get_bool(Props::Bold)
    end

    def bold=(value : Bool) : Bool
      set_bool(Props::Bold, value)
      value
    end

    def italic? : Bool
      get_bool(Props::Italic)
    end

    def italic=(value : Bool) : Bool
      set_bool(Props::Italic, value)
      value
    end

    def underline? : Bool
      get_bool(Props::Underline)
    end

    def underline=(value : Bool) : Bool
      set_bool(Props::Underline, value)
      value
    end

    def strikethrough? : Bool
      get_bool(Props::Strikethrough)
    end

    def strikethrough=(value : Bool) : Bool
      set_bool(Props::Strikethrough, value)
      value
    end

    def reverse? : Bool
      get_bool(Props::Reverse)
    end

    def reverse=(value : Bool) : Bool
      set_bool(Props::Reverse, value)
      value
    end

    def blink? : Bool
      get_bool(Props::Blink)
    end

    def blink=(value : Bool) : Bool
      set_bool(Props::Blink, value)
      value
    end

    def faint? : Bool
      get_bool(Props::Faint)
    end

    def faint=(value : Bool) : Bool
      set_bool(Props::Faint, value)
      value
    end

    def underline_spaces? : Bool
      get_bool(Props::UnderlineSpaces)
    end

    def strikethrough_spaces? : Bool
      get_bool(Props::StrikethroughSpaces)
    end

    def color_whitespace? : Bool
      is_set?(Props::ColorWhitespace) ? get_bool(Props::ColorWhitespace) : true
    end

    def foreground_color : Color?
      case fg = @fg_color
      when Color
        fg
      when AdaptiveColor
        fg.resolve
      when CompleteColor
        fg.resolve
      when CompleteAdaptiveColor
        fg.resolve.resolve
      when NoColor
        nil
      else
        nil
      end
    end

    def background_color : Color?
      case bg = @bg_color
      when Color
        bg
      when AdaptiveColor
        bg.resolve
      when CompleteColor
        bg.resolve
      when CompleteAdaptiveColor
        bg.resolve.resolve
      when NoColor
        nil
      else
        nil
      end
    end

    # Aliases for backwards compatibility
    @[Deprecated("Use `bold?` instead")]
    def get_bold : Bool
      bold?
    end

    @[Deprecated("Use `italic?` instead")]
    def get_italic : Bool
      italic?
    end

    @[Deprecated("Use `underline?` instead")]
    def get_underline : Bool
      underline?
    end

    def get_strikethrough : Bool
      strikethrough?
    end

    def get_reverse : Bool
      reverse?
    end

    def get_blink : Bool
      blink?
    end

    def get_faint : Bool
      faint?
    end

    def get_underline_spaces : Bool
      underline_spaces?
    end

    @[Deprecated("Use `strikethrough_spaces?` instead")]
    def get_strikethrough_spaces : Bool
      strikethrough_spaces?
    end

    @[Deprecated("Use `color_whitespace?` instead")]
    def get_color_whitespace : Bool
      color_whitespace?
    end

    @[Deprecated("Use `foreground_color` instead")]
    def get_foreground : Color?
      foreground_color
    end

    @[Deprecated("Use `background_color` instead")]
    def get_background : Color?
      background_color
    end

    # Crystal-idiomatic property getters
    def width_value : Int32
      @width
    end

    def height_value : Int32
      @height
    end

    def max_width_value : Int32
      @max_width
    end

    def max_height_value : Int32
      @max_height
    end

    def align_value : Position
      @align_horizontal
    end

    def align_horizontal_value : Position
      @align_horizontal
    end

    def align_vertical_value : Position
      @align_vertical
    end

    def padding : Edges
      Edges.new(@padding_top, @padding_right, @padding_bottom, @padding_left)
    end

    def margin : Edges
      Edges.new(@margin_top, @margin_right, @margin_bottom, @margin_left)
    end

    # Backwards compatibility aliases
    def get_width : Int32
      width_value
    end

    def get_height : Int32
      height_value
    end

    def get_max_width : Int32
      max_width_value
    end

    def get_max_height : Int32
      max_height_value
    end

    def get_align : Position
      align_value
    end

    def get_align_horizontal : Position
      align_horizontal_value
    end

    def get_align_vertical : Position
      align_vertical_value
    end

    def get_padding : Tuple(Int32, Int32, Int32, Int32)
      {@padding_top, @padding_right, @padding_bottom, @padding_left}
    end

    def get_padding_top : Int32
      @padding_top
    end

    def get_padding_right : Int32
      @padding_right
    end

    def get_padding_bottom : Int32
      @padding_bottom
    end

    def get_padding_left : Int32
      @padding_left
    end

    def get_horizontal_padding : Int32
      @padding_left + @padding_right
    end

    def get_vertical_padding : Int32
      @padding_top + @padding_bottom
    end

    def get_margin : Tuple(Int32, Int32, Int32, Int32)
      {@margin_top, @margin_right, @margin_bottom, @margin_left}
    end

    def get_margin_top : Int32
      @margin_top
    end

    def get_margin_right : Int32
      @margin_right
    end

    def get_margin_bottom : Int32
      @margin_bottom
    end

    def get_margin_left : Int32
      @margin_left
    end

    def get_horizontal_margins : Int32
      @margin_left + @margin_right
    end

    def get_vertical_margins : Int32
      @margin_top + @margin_bottom
    end

    def get_border : Tuple(Border, Bool, Bool, Bool, Bool)
      {
        @border_style,
        is_set?(Props::BorderTop) ? get_bool(Props::BorderTop) : false,
        is_set?(Props::BorderRight) ? get_bool(Props::BorderRight) : false,
        is_set?(Props::BorderBottom) ? get_bool(Props::BorderBottom) : false,
        is_set?(Props::BorderLeft) ? get_bool(Props::BorderLeft) : false,
      }
    end

    def get_border_style : Border
      @border_style
    end

    def get_border_top : Bool
      is_set?(Props::BorderTop) ? get_bool(Props::BorderTop) : implicit_borders?
    end

    def get_border_right : Bool
      is_set?(Props::BorderRight) ? get_bool(Props::BorderRight) : implicit_borders?
    end

    def get_border_bottom : Bool
      is_set?(Props::BorderBottom) ? get_bool(Props::BorderBottom) : implicit_borders?
    end

    def get_border_left : Bool
      is_set?(Props::BorderLeft) ? get_bool(Props::BorderLeft) : implicit_borders?
    end

    def get_border_top_size : Int32
      get_border_top ? @border_style.top_size : 0
    end

    def get_border_right_size : Int32
      get_border_right ? @border_style.right_size : 0
    end

    def get_border_bottom_size : Int32
      get_border_bottom ? @border_style.bottom_size : 0
    end

    def get_border_left_size : Int32
      get_border_left ? @border_style.left_size : 0
    end

    def get_horizontal_border_size : Int32
      get_border_left_size + get_border_right_size
    end

    def get_vertical_border_size : Int32
      get_border_top_size + get_border_bottom_size
    end

    def get_inline : Bool
      get_bool(Props::Inline)
    end

    def get_tab_width : Int32
      @tab_width
    end

    def get_transform : Proc(String, String)?
      @transform
    end

    # Frame size calculations
    def get_horizontal_frame_size : Int32
      get_horizontal_margins + get_horizontal_padding + get_horizontal_border_size
    end

    def get_vertical_frame_size : Int32
      get_vertical_margins + get_vertical_padding + get_vertical_border_size
    end

    def get_frame_size : Tuple(Int32, Int32)
      {get_horizontal_frame_size, get_vertical_frame_size}
    end

    # Value returns the raw, unformatted string value
    def value : String
      @value
    end

    # ========== UNSET METHODS ==========

    def unset_bold : Style
      unset(Props::Bold)
    end

    def unset_italic : Style
      unset(Props::Italic)
    end

    def unset_underline : Style
      unset(Props::Underline)
    end

    def unset_strikethrough : Style
      unset(Props::Strikethrough)
    end

    def unset_reverse : Style
      unset(Props::Reverse)
    end

    def unset_blink : Style
      unset(Props::Blink)
    end

    def unset_faint : Style
      unset(Props::Faint)
    end

    def unset_underline_spaces : Style
      unset(Props::UnderlineSpaces)
    end

    def unset_strikethrough_spaces : Style
      unset(Props::StrikethroughSpaces)
    end

    def unset_color_whitespace : Style
      unset(Props::ColorWhitespace)
    end

    def unset_foreground : Style
      @fg_color = nil
      unset(Props::Foreground)
    end

    def unset_background : Style
      @bg_color = nil
      unset(Props::Background)
    end

    def unset_width : Style
      @width = 0
      unset(Props::Width)
    end

    def unset_height : Style
      @height = 0
      unset(Props::Height)
    end

    def unset_max_width : Style
      @max_width = 0
      unset(Props::MaxWidth)
    end

    def unset_max_height : Style
      @max_height = 0
      unset(Props::MaxHeight)
    end

    def unset_align : Style
      @align_horizontal = Position::Left
      @align_vertical = Position::Top
      unset(Props::AlignHorizontal)
      unset(Props::AlignVertical)
    end

    def unset_align_horizontal : Style
      @align_horizontal = Position::Left
      unset(Props::AlignHorizontal)
    end

    def unset_align_vertical : Style
      @align_vertical = Position::Top
      unset(Props::AlignVertical)
    end

    def unset_padding : Style
      @padding_top = 0
      @padding_right = 0
      @padding_bottom = 0
      @padding_left = 0
      unset(Props::PaddingTop)
      unset(Props::PaddingRight)
      unset(Props::PaddingBottom)
      unset(Props::PaddingLeft)
    end

    def unset_padding_top : Style
      @padding_top = 0
      unset(Props::PaddingTop)
    end

    def unset_padding_right : Style
      @padding_right = 0
      unset(Props::PaddingRight)
    end

    def unset_padding_bottom : Style
      @padding_bottom = 0
      unset(Props::PaddingBottom)
    end

    def unset_padding_left : Style
      @padding_left = 0
      unset(Props::PaddingLeft)
    end

    def unset_margins : Style
      @margin_top = 0
      @margin_right = 0
      @margin_bottom = 0
      @margin_left = 0
      unset(Props::MarginTop)
      unset(Props::MarginRight)
      unset(Props::MarginBottom)
      unset(Props::MarginLeft)
    end

    def unset_margin_top : Style
      @margin_top = 0
      unset(Props::MarginTop)
    end

    def unset_margin_right : Style
      @margin_right = 0
      unset(Props::MarginRight)
    end

    def unset_margin_bottom : Style
      @margin_bottom = 0
      unset(Props::MarginBottom)
    end

    def unset_margin_left : Style
      @margin_left = 0
      unset(Props::MarginLeft)
    end

    def unset_margin_background : Style
      @margin_bg_color = nil
      unset(Props::MarginBackground)
    end

    def unset_border_style : Style
      @border_style = Border.new
      unset(Props::BorderStyle)
    end

    def unset_border_top : Style
      unset(Props::BorderTop)
    end

    def unset_border_right : Style
      unset(Props::BorderRight)
    end

    def unset_border_bottom : Style
      unset(Props::BorderBottom)
    end

    def unset_border_left : Style
      unset(Props::BorderLeft)
    end

    def unset_border_foreground : Style
      @border_top_fg_color = nil
      @border_right_fg_color = nil
      @border_bottom_fg_color = nil
      @border_left_fg_color = nil
      unset(Props::BorderTopForeground)
      unset(Props::BorderRightForeground)
      unset(Props::BorderBottomForeground)
      unset(Props::BorderLeftForeground)
    end

    def unset_border_background : Style
      @border_top_bg_color = nil
      @border_right_bg_color = nil
      @border_bottom_bg_color = nil
      @border_left_bg_color = nil
      unset(Props::BorderTopBackground)
      unset(Props::BorderRightBackground)
      unset(Props::BorderBottomBackground)
      unset(Props::BorderLeftBackground)
    end

    def unset_inline : Style
      unset(Props::Inline)
    end

    def unset_tab_width : Style
      @tab_width = TAB_WIDTH_DEFAULT
      unset(Props::TabWidth)
    end

    def unset_transform : Style
      @transform = nil
      unset(Props::Transform)
    end

    def unset_string : Style
      @value = ""
      self
    end

    # ========== INHERIT ==========

    # Inherit overlays the style in the argument onto this style
    # Only unset rules on the receiver are inherited.
    # Margins, padding, and underlying string values are not inherited.
    def inherit(other : Style) : Style
      # Text attributes
      inherit_bool(Props::Bold, other) unless is_set?(Props::Bold)
      inherit_bool(Props::Italic, other) unless is_set?(Props::Italic)
      inherit_bool(Props::Underline, other) unless is_set?(Props::Underline)
      inherit_bool(Props::Strikethrough, other) unless is_set?(Props::Strikethrough)
      inherit_bool(Props::Reverse, other) unless is_set?(Props::Reverse)
      inherit_bool(Props::Blink, other) unless is_set?(Props::Blink)
      inherit_bool(Props::Faint, other) unless is_set?(Props::Faint)
      inherit_bool(Props::UnderlineSpaces, other) unless is_set?(Props::UnderlineSpaces)
      inherit_bool(Props::StrikethroughSpaces, other) unless is_set?(Props::StrikethroughSpaces)
      inherit_bool(Props::ColorWhitespace, other) unless is_set?(Props::ColorWhitespace)

      # Colors
      if !is_set?(Props::Foreground) && other.is_set?(Props::Foreground)
        @fg_color = other.@fg_color
        @props |= Props::Foreground
      end

      if !is_set?(Props::Background) && other.is_set?(Props::Background)
        @bg_color = other.@bg_color
        @props |= Props::Background
        # Background also sets margin background if not already set
        if !is_set?(Props::MarginBackground) && !other.is_set?(Props::MarginBackground)
          @margin_bg_color = other.@bg_color
          @props |= Props::MarginBackground
        end
      end

      # Dimensions (but not margins/padding)
      if !is_set?(Props::Width) && other.is_set?(Props::Width)
        @width = other.@width
        @props |= Props::Width
      end

      if !is_set?(Props::Height) && other.is_set?(Props::Height)
        @height = other.@height
        @props |= Props::Height
      end

      # Alignment
      if !is_set?(Props::AlignHorizontal) && other.is_set?(Props::AlignHorizontal)
        @align_horizontal = other.@align_horizontal
        @props |= Props::AlignHorizontal
      end

      if !is_set?(Props::AlignVertical) && other.is_set?(Props::AlignVertical)
        @align_vertical = other.@align_vertical
        @props |= Props::AlignVertical
      end

      # Border style (but not border visibility)
      if !is_set?(Props::BorderStyle) && other.is_set?(Props::BorderStyle)
        @border_style = other.@border_style
        @props |= Props::BorderStyle
      end

      # Border colors
      inherit_border_color(Props::BorderTopForeground, other, other.@border_top_fg_color) { |c| @border_top_fg_color = c }
      inherit_border_color(Props::BorderRightForeground, other, other.@border_right_fg_color) { |c| @border_right_fg_color = c }
      inherit_border_color(Props::BorderBottomForeground, other, other.@border_bottom_fg_color) { |c| @border_bottom_fg_color = c }
      inherit_border_color(Props::BorderLeftForeground, other, other.@border_left_fg_color) { |c| @border_left_fg_color = c }
      inherit_border_color(Props::BorderTopBackground, other, other.@border_top_bg_color) { |c| @border_top_bg_color = c }
      inherit_border_color(Props::BorderRightBackground, other, other.@border_right_bg_color) { |c| @border_right_bg_color = c }
      inherit_border_color(Props::BorderBottomBackground, other, other.@border_bottom_bg_color) { |c| @border_bottom_bg_color = c }
      inherit_border_color(Props::BorderLeftBackground, other, other.@border_left_bg_color) { |c| @border_left_bg_color = c }

      # Other
      if !is_set?(Props::Inline) && other.is_set?(Props::Inline)
        inherit_bool(Props::Inline, other)
      end

      if !is_set?(Props::MaxWidth) && other.is_set?(Props::MaxWidth)
        @max_width = other.@max_width
        @props |= Props::MaxWidth
      end

      if !is_set?(Props::MaxHeight) && other.is_set?(Props::MaxHeight)
        @max_height = other.@max_height
        @props |= Props::MaxHeight
      end

      if !is_set?(Props::TabWidth) && other.is_set?(Props::TabWidth)
        @tab_width = other.@tab_width
        @props |= Props::TabWidth
      end

      if !is_set?(Props::Transform) && other.is_set?(Props::Transform)
        @transform = other.@transform
        @props |= Props::Transform
      end

      self
    end

    # ========== COPY ==========

    def copy : Style
      new_style = Style.new
      copy_to(new_style)
      new_style
    end

    # Merge another style into this one
    # Properties that are set in the other style will override this style's properties
    def merge(other : Style) : Style
      result = copy
      result.merge_from(other)
      result
    end

    # Merge another style's set properties into this style (mutates)
    protected def merge_from(other : Style) : Nil
      # Merge text attributes (bold, italic, etc.) - copy attr bits for set props
      attr_props = Props::Bold | Props::Faint | Props::Italic | Props::Underline |
                   Props::Blink | Props::Reverse | Props::Strikethrough
      other_attr_props = Props.new(other.@props.value & attr_props.value)

      # For each attribute prop that's set in other, copy both the prop flag and attr bit
      {% for prop in [:Bold, :Faint, :Italic, :Underline, :Blink, :Reverse, :Strikethrough] %}
        if other.@props.{{ prop.id.underscore }}?
          @props = Props.new(@props.value | Props::{{ prop.id }}.value)
          # Copy the attr bit from other
          bit_mask = 1u32 << Props::{{ prop.id }}.value.trailing_zeros_count
          if (other.@attrs & bit_mask) != 0
            @attrs |= bit_mask
          else
            @attrs &= ~bit_mask
          end
        end
      {% end %}

      # Colors
      if other.@props.foreground?
        @fg_color = other.@fg_color
        @props = Props.new(@props.value | Props::Foreground.value)
      end
      if other.@props.background?
        @bg_color = other.@bg_color
        @props = Props.new(@props.value | Props::Background.value)
      end

      # Dimensions
      if other.@props.width?
        @width = other.@width
        @props = Props.new(@props.value | Props::Width.value)
      end
      if other.@props.height?
        @height = other.@height
        @props = Props.new(@props.value | Props::Height.value)
      end
      if other.@props.max_width?
        @max_width = other.@max_width
        @props = Props.new(@props.value | Props::MaxWidth.value)
      end
      if other.@props.max_height?
        @max_height = other.@max_height
        @props = Props.new(@props.value | Props::MaxHeight.value)
      end

      # Alignment
      if other.@props.align_horizontal?
        @align_horizontal = other.@align_horizontal
        @props = Props.new(@props.value | Props::AlignHorizontal.value)
      end
      if other.@props.align_vertical?
        @align_vertical = other.@align_vertical
        @props = Props.new(@props.value | Props::AlignVertical.value)
      end

      # Padding
      if other.@props.padding_top?
        @padding_top = other.@padding_top
        @props = Props.new(@props.value | Props::PaddingTop.value)
      end
      if other.@props.padding_right?
        @padding_right = other.@padding_right
        @props = Props.new(@props.value | Props::PaddingRight.value)
      end
      if other.@props.padding_bottom?
        @padding_bottom = other.@padding_bottom
        @props = Props.new(@props.value | Props::PaddingBottom.value)
      end
      if other.@props.padding_left?
        @padding_left = other.@padding_left
        @props = Props.new(@props.value | Props::PaddingLeft.value)
      end

      # Margin
      if other.@props.margin_top?
        @margin_top = other.@margin_top
        @props = Props.new(@props.value | Props::MarginTop.value)
      end
      if other.@props.margin_right?
        @margin_right = other.@margin_right
        @props = Props.new(@props.value | Props::MarginRight.value)
      end
      if other.@props.margin_bottom?
        @margin_bottom = other.@margin_bottom
        @props = Props.new(@props.value | Props::MarginBottom.value)
      end
      if other.@props.margin_left?
        @margin_left = other.@margin_left
        @props = Props.new(@props.value | Props::MarginLeft.value)
      end
      if other.@props.margin_background?
        @margin_bg_color = other.@margin_bg_color
        @props = Props.new(@props.value | Props::MarginBackground.value)
      end

      # Border style
      if other.@props.border_style?
        @border_style = other.@border_style
        @props = Props.new(@props.value | Props::BorderStyle.value)
      end

      # Border foreground colors
      if other.@props.border_top_foreground?
        @border_top_fg_color = other.@border_top_fg_color
        @props = Props.new(@props.value | Props::BorderTopForeground.value)
      end
      if other.@props.border_right_foreground?
        @border_right_fg_color = other.@border_right_fg_color
        @props = Props.new(@props.value | Props::BorderRightForeground.value)
      end
      if other.@props.border_bottom_foreground?
        @border_bottom_fg_color = other.@border_bottom_fg_color
        @props = Props.new(@props.value | Props::BorderBottomForeground.value)
      end
      if other.@props.border_left_foreground?
        @border_left_fg_color = other.@border_left_fg_color
        @props = Props.new(@props.value | Props::BorderLeftForeground.value)
      end

      # Border background colors
      if other.@props.border_top_background?
        @border_top_bg_color = other.@border_top_bg_color
        @props = Props.new(@props.value | Props::BorderTopBackground.value)
      end
      if other.@props.border_right_background?
        @border_right_bg_color = other.@border_right_bg_color
        @props = Props.new(@props.value | Props::BorderRightBackground.value)
      end
      if other.@props.border_bottom_background?
        @border_bottom_bg_color = other.@border_bottom_bg_color
        @props = Props.new(@props.value | Props::BorderBottomBackground.value)
      end
      if other.@props.border_left_background?
        @border_left_bg_color = other.@border_left_bg_color
        @props = Props.new(@props.value | Props::BorderLeftBackground.value)
      end

      # Tab width and transform
      if other.@props.tab_width?
        @tab_width = other.@tab_width
        @props = Props.new(@props.value | Props::TabWidth.value)
      end
      if other.@props.transform?
        @transform = other.@transform
        @props = Props.new(@props.value | Props::Transform.value)
      end
    end

    # Internal method to copy all properties to another style
    protected def copy_to(other : Style) : Nil
      other.copy_from(
        @props, @value, @attrs, @fg_color, @bg_color,
        @width, @height, @max_width, @max_height,
        @align_horizontal, @align_vertical,
        @padding_top, @padding_right, @padding_bottom, @padding_left,
        @margin_top, @margin_right, @margin_bottom, @margin_left, @margin_bg_color,
        @border_style,
        @border_top_fg_color, @border_right_fg_color, @border_bottom_fg_color, @border_left_fg_color,
        @border_top_bg_color, @border_right_bg_color, @border_bottom_bg_color, @border_left_bg_color,
        @tab_width, @transform
      )
    end

    # Internal method to receive copied properties
    protected def copy_from(
      props : Props, value : String, attrs : UInt32,
      fg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil,
      bg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil,
      width : Int32, height : Int32, max_width : Int32, max_height : Int32,
      align_horizontal : Position, align_vertical : Position,
      padding_top : Int32, padding_right : Int32, padding_bottom : Int32, padding_left : Int32,
      margin_top : Int32, margin_right : Int32, margin_bottom : Int32, margin_left : Int32,
      margin_bg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil,
      border_style : Border,
      border_top_fg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil,
      border_right_fg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil,
      border_bottom_fg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil,
      border_left_fg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil,
      border_top_bg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil,
      border_right_bg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil,
      border_bottom_bg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil,
      border_left_bg_color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil,
      tab_width : Int32, transform : Proc(String, String)?,
    ) : Nil
      @props = props
      @value = value
      @attrs = attrs
      @fg_color = fg_color
      @bg_color = bg_color
      @width = width
      @height = height
      @max_width = max_width
      @max_height = max_height
      @align_horizontal = align_horizontal
      @align_vertical = align_vertical
      @padding_top = padding_top
      @padding_right = padding_right
      @padding_bottom = padding_bottom
      @padding_left = padding_left
      @margin_top = margin_top
      @margin_right = margin_right
      @margin_bottom = margin_bottom
      @margin_left = margin_left
      @margin_bg_color = margin_bg_color
      @border_style = border_style
      @border_top_fg_color = border_top_fg_color
      @border_right_fg_color = border_right_fg_color
      @border_bottom_fg_color = border_bottom_fg_color
      @border_left_fg_color = border_left_fg_color
      @border_top_bg_color = border_top_bg_color
      @border_right_bg_color = border_right_bg_color
      @border_bottom_bg_color = border_bottom_bg_color
      @border_left_bg_color = border_left_bg_color
      @tab_width = tab_width
      @transform = transform
    end

    # ========== STRING / RENDER ==========

    # String implements the Stringer interface
    def to_s : String
      render(@value)
    end

    # Render applies the style to the given string(s)
    def render(*strs : String) : String
      render(strs.to_a)
    end

    def render(strs : Array(String)) : String
      str =
        if strs.empty?
          @value
        else
          strs.join(" ")
        end
      render_string(str)
    end

    def render : String
      render([] of String)
    end

    private def render_string(str : String) : String
      # Apply transform
      if transform = @transform
        str = transform.call(str)
      end

      # If no props set, just handle tabs
      if @props.none?
        return maybe_convert_tabs(str)
      end

      bold = get_bool(Props::Bold)
      italic = get_bool(Props::Italic)
      underline_val = get_bool(Props::Underline)
      strikethrough_val = get_bool(Props::Strikethrough)
      reverse_val = get_bool(Props::Reverse)
      blink_val = get_bool(Props::Blink)
      faint_val = get_bool(Props::Faint)

      fg = resolve_color(@fg_color)
      bg = resolve_color(@bg_color)

      width_val = is_set?(Props::Width) ? @width : 0
      height_val = is_set?(Props::Height) ? @height : 0

      top_padding = @padding_top
      right_padding = @padding_right
      bottom_padding = @padding_bottom
      left_padding = @padding_left

      color_whitespace = color_whitespace?
      inline_val = get_bool(Props::Inline)
      max_width_val = @max_width
      max_height_val = @max_height

      underline_spaces = is_set?(Props::UnderlineSpaces) ? get_bool(Props::UnderlineSpaces) : underline_val
      strikethrough_spaces = is_set?(Props::StrikethroughSpaces) ? get_bool(Props::StrikethroughSpaces) : strikethrough_val

      # Convert tabs
      str = maybe_convert_tabs(str)

      # Strip carriage returns
      str = str.gsub("\r\n", "\n")

      # Strip newlines in inline mode
      if inline_val
        str = str.gsub("\n", "")
      end

      # Word wrap if width is set
      if !inline_val && width_val > 0
        wrap_at = width_val - left_padding - right_padding
        str = self.class.word_wrap_cached(str, wrap_at) if wrap_at > 0
      end

      # Build ANSI escape codes
      base_codes = [] of Int32
      base_codes << 1 if bold
      base_codes << 2 if faint_val
      base_codes << 3 if italic
      base_codes << 5 if blink_val
      base_codes << 7 if reverse_val

      if fg
        base_codes.concat(fg.foreground_codes)
      end
      if bg
        base_codes.concat(bg.background_codes)
      end

      # Lip Gloss applies underline/strikethrough on a per-rune basis when
      # space styling is enabled, which also affects escape sequences.
      use_space_styler =
        (underline_val && !underline_spaces) ||
          (strikethrough_val && !strikethrough_spaces) ||
          underline_spaces ||
          strikethrough_spaces

      if use_space_styler
        lines = str.split('\n')
        str = lines.map do |line|
          String.build do |io|
            line.each_char do |ch|
              codes = base_codes.dup

              if ch.whitespace?
                codes << 4 if underline_spaces
                codes << 9 if strikethrough_spaces
              else
                if underline_val
                  codes << 4
                  codes << 4
                end
                codes << 9 if strikethrough_val
              end

              if codes.empty?
                io << ch
              else
                io << "\e[#{codes.join(';')}m" << ch << "\e[0m"
              end
            end
          end
        end.join('\n')
      else
        codes = base_codes.dup
        codes << 4 if underline_val
        codes << 9 if strikethrough_val

        if codes.any?
          lines = str.split('\n')
          str = lines.map do |line|
            if line.empty?
              line
            else
              "\e[#{codes.join(';')}m#{line}\e[0m"
            end
          end.join('\n')
        end
      end

      # Apply padding
      if !inline_val
        if left_padding > 0 || right_padding > 0
          lines = str.split('\n')
          left_str = " " * left_padding
          right_str = " " * right_padding
          str = lines.map { |l| "#{left_str}#{l}#{right_str}" }.join('\n')
        end

        if top_padding > 0
          width_for_pad = str.split('\n').max_of? { |l| Text.width(l) } || 0
          empty_line = " " * width_for_pad
          str = (Array.new(top_padding, empty_line).join('\n')) + "\n" + str
        end

        if bottom_padding > 0
          width_for_pad = str.split('\n').max_of? { |l| Text.width(l) } || 0
          empty_line = " " * width_for_pad
          str = str + "\n" + (Array.new(bottom_padding, empty_line).join('\n'))
        end
      end

      # Apply height
      if height_val > 0
        str = align_text_vertical(str, @align_vertical, height_val)
      end

      # Apply width/alignment
      if width_val > 0 || str.includes?('\n')
        str = align_text_horizontal(str, @align_horizontal, width_val)
      end

      # Apply border
      if !inline_val
        str = apply_border(str)
      end

      # Apply margins
      if !inline_val
        str = apply_margins(str)
      end

      # Truncate to MaxWidth
      if max_width_val > 0
        lines = str.split('\n')
        str = lines.map { |l| truncate_ansi(l, max_width_val) }.join('\n')
      end

      # Truncate to MaxHeight
      if max_height_val > 0
        lines = str.split('\n')
        if lines.size > max_height_val
          str = lines[0, max_height_val].join('\n')
        end
      end

      str
    end

    # ========== PRIVATE HELPERS ==========

    private def set_bool(prop : Props, v : Bool) : Style
      @props |= prop
      if v
        @attrs |= (1u32 << prop.value.trailing_zeros_count)
      else
        @attrs &= ~(1u32 << prop.value.trailing_zeros_count)
      end
      self
    end

    def get_bool(prop : Props) : Bool
      (@attrs & (1u32 << prop.value.trailing_zeros_count)) != 0
    end

    def is_set?(prop : Props) : Bool
      (@props & prop) != Props::None
    end

    private def unset(prop : Props) : Style
      @props &= ~prop
      self
    end

    private def inherit_bool(prop : Props, other : Style)
      if other.is_set?(prop)
        set_bool(prop, other.get_bool(prop))
      end
    end

    private def inherit_border_color(prop : Props, other : Style, color : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil, &block : (Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil) ->)
      if !is_set?(prop) && other.is_set?(prop)
        block.call(color)
        @props |= prop
      end
    end

    private def implicit_borders? : Bool
      is_set?(Props::BorderStyle) &&
        !is_set?(Props::BorderTop) &&
        !is_set?(Props::BorderRight) &&
        !is_set?(Props::BorderBottom) &&
        !is_set?(Props::BorderLeft)
    end

    private def resolve_color(c : Color | AdaptiveColor | CompleteColor | CompleteAdaptiveColor | NoColor | Nil) : Color?
      case c
      when Color
        apply_color_profile(c)
      when AdaptiveColor
        apply_color_profile(c.resolve)
      when CompleteColor
        resolve_complete_color(c)
      when CompleteAdaptiveColor
        resolve_complete_color(c.resolve)
      when NoColor
        nil
      else
        nil
      end
    end

    private def resolve_complete_color(c : CompleteColor) : Color?
      case @style_renderer.color_profile
      when ColorProfile::ASCII
        nil
      when ColorProfile::ANSI
        if cc = c.ansi
          apply_color_profile(cc)
        elsif cc = c.ansi256
          apply_color_profile(cc)
        elsif cc = c.true_color
          apply_color_profile(cc)
        end
      when ColorProfile::ANSI256
        if cc = c.ansi256
          apply_color_profile(cc)
        elsif cc = c.true_color
          apply_color_profile(cc)
        elsif cc = c.ansi
          apply_color_profile(cc)
        end
      else # TrueColor
        c.true_color || c.ansi256 || c.ansi
      end
    end

    private def apply_color_profile(color : Color) : Color?
      case @style_renderer.color_profile
      when ColorProfile::ASCII
        nil
      when ColorProfile::ANSI
        r, g, b = color.to_rgb
        Color.new(Color::Type::Named, Color.rgb_to_ansi16_index(r, g, b))
      when ColorProfile::ANSI256
        case color.type
        when Color::Type::Indexed
          color
        when Color::Type::Named
          # Keep ANSI16 colors as-is.
          color
        else
          r, g, b = color.to_rgb
          Color.indexed(Color.rgb_to_ansi256_index(r, g, b))
        end
      else # TrueColor
        # In TrueColor mode, convert everything to RGB for consistent rendering
        # This matches Go lipgloss behavior
        case color.type
        when Color::Type::RGB
          color
        else
          r, g, b = color.to_rgb
          Color.rgb(r, g, b)
        end
      end
    end

    private def parse_sides_bool(sides : Array(Bool)) : Tuple(Bool, Bool, Bool, Bool)
      case sides.size
      when 0
        {true, true, true, true}
      when 1
        v = sides[0]
        {v, v, v, v}
      when 2
        {sides[0], sides[1], sides[0], sides[1]}
      when 3
        {sides[0], sides[1], sides[2], sides[1]}
      else
        {sides[0], sides[1], sides[2], sides[3]}
      end
    end

    private def maybe_convert_tabs(str : String) : String
      return str if @tab_width == NO_TAB_CONVERSION
      return str.gsub("\t", "") if @tab_width == 0
      str.gsub("\t", " " * @tab_width)
    end

    protected def self.word_wrap_cached(str : String, width : Int32) : String
      return str if width <= 0

      key = {str, width}
      cached = @@wrap_cache_lock.synchronize { @@wrap_cache[key]? }
      return cached if cached

      wrapped = word_wrap_uncached(str, width)

      @@wrap_cache_lock.synchronize do
        unless @@wrap_cache.has_key?(key)
          @@wrap_cache[key] = wrapped
          @@wrap_cache_order << key
          if @@wrap_cache_order.size > WRAP_CACHE_MAX
            evicted = @@wrap_cache_order.shift
            @@wrap_cache.delete(evicted)
          end
        end
      end

      wrapped
    end

    protected def self.word_wrap_uncached(str : String, width : Int32) : String
      return str if width <= 0
      Cellwrap.wrap(str, width)
    end

    private def align_text_horizontal(str : String, pos : Position, width : Int32) : String
      lines = str.split('\n')

      # Calculate actual width needed
      actual_width = width > 0 ? width : (lines.max_of? { |l| Text.width(l) } || 0)

      lines.map do |line|
        line_width = Text.width(line)
        gap = actual_width - line_width

        if gap <= 0
          line
        else
          case pos
          when Position::Right
            " " * gap + line
          when Position::Center
            left = gap // 2
            right = gap - left
            " " * left + line + " " * right
          else # Left
            line + " " * gap
          end
        end
      end.join('\n')
    end

    private def align_text_vertical(str : String, pos : Position, height : Int32) : String
      lines = str.split('\n')
      gap = height - lines.size

      return str if gap <= 0
      empty_line = ""

      case pos
      when Position::Bottom
        Array.new(gap, empty_line).concat(lines).join('\n')
      when Position::Center
        top = gap // 2
        bottom = gap - top
        (Array.new(top, empty_line) + lines + Array.new(bottom, empty_line)).join('\n')
      else # Top
        lines.concat(Array.new(gap, empty_line)).join('\n')
      end
    end

    private def apply_border(str : String) : String
      return str unless is_set?(Props::BorderStyle)

      has_top = get_border_top
      has_right = get_border_right
      has_bottom = get_border_bottom
      has_left = get_border_left

      return str if !has_top && !has_right && !has_bottom && !has_left

      lines = str.split('\n')
      width = lines.max_of? { |l| Text.width(l) } || 0

      border = @border_style

      # Build border strings with colors
      top_fg = resolve_color(@border_top_fg_color)
      top_bg = resolve_color(@border_top_bg_color)
      right_fg = resolve_color(@border_right_fg_color)
      right_bg = resolve_color(@border_right_bg_color)
      bottom_fg = resolve_color(@border_bottom_fg_color)
      bottom_bg = resolve_color(@border_bottom_bg_color)
      left_fg = resolve_color(@border_left_fg_color)
      left_bg = resolve_color(@border_left_bg_color)

      result = [] of String

      # Top border
      if has_top
        top_border = ""
        top_border += style_border(border.top_left, top_fg, top_bg) if has_left
        top_border += style_border(border.top * width, top_fg, top_bg)
        top_border += style_border(border.top_right, top_fg, top_bg) if has_right
        result << top_border
      end

      # Content with side borders
      lines.each do |line|
        bordered_line = ""
        bordered_line += style_border(border.left, left_fg, left_bg) if has_left
        bordered_line += line
        # Pad line to width
        line_gap = width - Text.width(line)
        bordered_line += " " * line_gap if line_gap > 0
        bordered_line += style_border(border.right, right_fg, right_bg) if has_right
        result << bordered_line
      end

      # Bottom border
      if has_bottom
        bottom_border = ""
        bottom_border += style_border(border.bottom_left, bottom_fg, bottom_bg) if has_left
        bottom_border += style_border(border.bottom * width, bottom_fg, bottom_bg)
        bottom_border += style_border(border.bottom_right, bottom_fg, bottom_bg) if has_right
        result << bottom_border
      end

      result.join('\n')
    end

    private def style_border(str : String, fg : Color?, bg : Color?) : String
      return str if fg.nil? && bg.nil?

      codes = [] of Int32
      codes.concat(fg.foreground_codes) if fg
      codes.concat(bg.background_codes) if bg

      "\e[#{codes.join(';')}m#{str}\e[0m"
    end

    private def apply_margins(str : String) : String
      return str if @margin_top == 0 && @margin_right == 0 && @margin_bottom == 0 && @margin_left == 0

      lines = str.split('\n')

      # Apply horizontal margins
      if @margin_left > 0 || @margin_right > 0
        left_margin = style_margin_spaces(" " * @margin_left)
        right_margin = style_margin_spaces(" " * @margin_right)
        lines = lines.map { |l| "#{left_margin}#{l}#{right_margin}" }
      end

      # Apply vertical margins
      if @margin_top > 0 || @margin_bottom > 0
        width = lines.max_of? { |l| Text.width(l) } || 0
        empty_line = style_margin_spaces(" " * width)
        if @margin_top > 0
          @margin_top.times { lines.unshift(empty_line) }
        end
        if @margin_bottom > 0
          @margin_bottom.times { lines << empty_line }
        end
      end

      lines.join('\n')
    end

    private def style_margin_spaces(spaces : String) : String
      bg = resolve_color(@margin_bg_color)
      return spaces unless bg

      codes = bg.background_codes
      return spaces if codes.empty?

      "\e[#{codes.join(';')}m#{spaces}\e[0m"
    end

    private def truncate_ansi(str : String, width : Int32) : String
      Text.truncate(str, width)
    end
  end

  # ========== MODULE-LEVEL LAYOUT UTILITIES ==========

  # Join strings horizontally with alignment
  def self.join_horizontal(pos : Position, *blocks : String) : String
    join_horizontal(pos, blocks.to_a)
  end

  def self.join_horizontal(pos : Position, *blocks : View) : String
    join_horizontal(pos, blocks.map(&.content))
  end

  def self.join_horizontal(pos : Float64, *blocks : String) : String
    join_horizontal(pos, blocks.to_a)
  end

  def self.join_horizontal(pos : Float64, *blocks : View) : String
    join_horizontal(pos, blocks.map(&.content))
  end

  def self.join_horizontal(pos : Position, blocks : Array(View)) : String
    join_horizontal(pos, blocks.map(&.content))
  end

  def self.join_horizontal(pos : Position, blocks : Array(String)) : String
    return "" if blocks.empty?

    block_lines = blocks.map(&.split('\n'))
    block_widths = block_lines.map { |lines| lines.max_of? { |l| Text.width(l) } || 0 }
    max_height = block_lines.max_of?(&.size) || 0

    # Pad each block
    padded_blocks = block_lines.map_with_index do |lines, i|
      width = block_widths[i]
      height_diff = max_height - lines.size
      empty_line = " " * width

      # Vertical alignment
      padded_lines = case pos
                     when Position::Bottom
                       Array.new(height_diff, empty_line) + lines
                     when Position::Center
                       top = height_diff // 2
                       bottom = height_diff - top
                       Array.new(top, empty_line) + lines + Array.new(bottom, empty_line)
                     else # Top
                       lines + Array.new(height_diff, empty_line)
                     end

      # Ensure each line is width chars
      padded_lines.map do |line|
        gap = width - Text.width(line)
        gap > 0 ? line + " " * gap : line
      end
    end

    # Join horizontally
    result = (0...max_height).map do |i|
      padded_blocks.map { |block| block[i]? || "" }.join
    end

    result.join('\n')
  end

  def self.join_horizontal(pos : Float64, blocks : Array(View)) : String
    join_horizontal(pos, blocks.map(&.content))
  end

  def self.join_horizontal(pos : Float64, blocks : Array(String)) : String
    return "" if blocks.empty?
    ratio = pos.clamp(0.0, 1.0)

    block_lines = blocks.map(&.split('\n'))
    block_widths = block_lines.map { |lines| lines.max_of? { |l| Text.width(l) } || 0 }
    max_height = block_lines.max_of?(&.size) || 0

    padded_blocks = block_lines.map_with_index do |lines, i|
      width = block_widths[i]
      height_diff = max_height - lines.size
      top = (height_diff * ratio).round.to_i.clamp(0, height_diff)
      bottom = height_diff - top
      empty_line = " " * width
      padded_lines = Array.new(top, empty_line) + lines + Array.new(bottom, empty_line)

      padded_lines.map do |line|
        gap = width - Text.width(line)
        gap > 0 ? line + " " * gap : line
      end
    end

    result = (0...max_height).map do |i|
      padded_blocks.map { |block| block[i]? || "" }.join
    end

    result.join('\n')
  end

  # Join strings vertically with alignment
  def self.join_vertical(pos : Position, *blocks : String) : String
    join_vertical(pos, blocks.to_a)
  end

  def self.join_vertical(pos : Position, *blocks : View) : String
    join_vertical(pos, blocks.map(&.content))
  end

  def self.join_vertical(pos : Float64, *blocks : String) : String
    join_vertical(pos, blocks.to_a)
  end

  def self.join_vertical(pos : Float64, *blocks : View) : String
    join_vertical(pos, blocks.map(&.content))
  end

  def self.join_vertical(pos : Position, blocks : Array(String)) : String
    return "" if blocks.empty?

    max_width = blocks.max_of? do |b|
      b.split('\n').max_of? { |l| Text.width(l) } || 0
    end || 0

    aligned = blocks.map do |block|
      block.split('\n').map do |line|
        gap = max_width - Text.width(line)
        if gap <= 0
          line
        else
          case pos
          when Position::Right
            " " * gap + line
          when Position::Center
            left = gap // 2
            right = gap - left
            " " * left + line + " " * right
          else # Left
            line + " " * gap
          end
        end
      end.join('\n')
    end

    aligned.join('\n')
  end

  def self.join_vertical(pos : Float64, blocks : Array(String)) : String
    return "" if blocks.empty?
    ratio = pos.clamp(0.0, 1.0)

    max_width = blocks.max_of? do |b|
      b.split('\n').max_of? { |l| Text.width(l) } || 0
    end || 0

    aligned = blocks.map do |block|
      block.split('\n').map do |line|
        gap = max_width - Text.width(line)
        if gap <= 0
          line
        else
          left = (gap * ratio).round.to_i.clamp(0, gap)
          right = gap - left
          " " * left + line + " " * right
        end
      end.join('\n')
    end

    aligned.join('\n')
  end

  # Place content within a box of given dimensions
  def self.place(width : Int32, height : Int32, h_pos : Position, v_pos : Position, content : String) : String
    lines = content.split('\n')
    content_width = lines.max_of? { |l| Text.width(l) } || 0
    content_height = lines.size

    # Vertical placement
    v_gap = height - content_height
    if v_gap > 0
      empty_line = " " * width
      case v_pos
      when Position::Bottom
        lines = Array.new(v_gap, empty_line) + lines
      when Position::Center
        top = v_gap // 2
        bottom = v_gap - top
        lines = Array.new(top, empty_line) + lines + Array.new(bottom, empty_line)
      else # Top
        lines = lines + Array.new(v_gap, empty_line)
      end
    end

    # Horizontal placement
    result = lines.map do |line|
      h_gap = width - Text.width(line)
      if h_gap <= 0
        line
      else
        case h_pos
        when Position::Right
          " " * h_gap + line
        when Position::Center
          left = h_gap // 2
          right = h_gap - left
          " " * left + line + " " * right
        else # Left
          line + " " * h_gap
        end
      end
    end

    # Crop if needed
    if result.size > height
      result = result[0, height]
    end

    result.join('\n')
  end

  def self.place_horizontal(width : Int32, pos : Position, content : String) : String
    height = content.split('\n').size
    place(width, height, pos, Position::Top, content)
  end

  def self.place_vertical(height : Int32, pos : Position, content : String) : String
    lines = content.split('\n')
    width = lines.max_of? { |l| Text.width(l) } || 0
    place(width, height, Position::Left, pos, content)
  end

  # Measure width of rendered string (max line width)
  def self.width(str : String) : Int32
    return 0 if str.empty?
    str.split('\n').max_of? { |l| Text.width(l) } || 0
  end

  # Measure height of rendered string (line count)
  def self.height(str : String) : Int32
    str.split('\n').size
  end

  # Get both width and height
  def self.size(str : String) : Tuple(Int32, Int32)
    lines = str.split('\n')
    w = lines.max_of? { |l| Text.width(l) } || 0
    {w, lines.size}
  end

  # Create a new style (convenience)
  def self.new_style : Style
    Style.new
  end
end
