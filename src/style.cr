# Term2 Style - A complete port of Lipgloss styling
# This is the core styling primitive for Term2

module Term2
  # Global setting for adaptive colors
  class_property? has_dark_background : Bool = true

  # Tab width default
  TAB_WIDTH_DEFAULT = 4

  # NoTabConversion can be passed to TabWidth to disable tab replacement
  NO_TAB_CONVERSION = -1

  # Supported color profiles (parity with Lip Gloss/termenv)
  enum ColorProfile
    ASCII
    ANSI
    ANSI256
    TrueColor
  end

  # StyleRenderer manages color profile and background detection (mirrors Lip Gloss)
  class StyleRenderer
    @@default_renderer = StyleRenderer.new

    @color_profile : ColorProfile = ColorProfile::TrueColor
    @has_dark_background : Bool = true
    @output : IO? = nil

    def self.default : StyleRenderer
      @@default_renderer
    end

    def color_profile : ColorProfile
      @color_profile
    end

    def color_profile=(profile : ColorProfile)
      @color_profile = profile
    end

    def has_dark_background? : Bool
      @has_dark_background
    end

    def output : IO?
      @output
    end

    def output=(io : IO?)
      @output = io
    end

    def has_dark_background=(val : Bool)
      @has_dark_background = val
    end

    # Factory for styles bound to this renderer
    def new_style : Style
      style = Style.new
      style.renderer(self)
    end
  end

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

    def get_top_size : Int32
      @top.empty? ? 0 : 1
    end

    def get_bottom_size : Int32
      @bottom.empty? ? 0 : 1
    end

    def get_left_size : Int32
      @left.empty? ? 0 : 1
    end

    def get_right_size : Int32
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

      r = hex[0, 2].to_i(16)
      g = hex[2, 2].to_i(16)
      b = hex[4, 2].to_i(16)
      rgb(r, g, b)
    end

    # Create an indexed color (0-255)
    def self.indexed(index : Int32) : Color
      new(Type::Indexed, index.clamp(0, 255))
    end

    # Create an RGB color
    def self.rgb(r : Int32, g : Int32, b : Int32) : Color
      new(Type::RGB, {r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255)})
    end

    # Convert to RGB tuple (using xterm palette for indexed/named)
    def to_rgb : Tuple(Int32, Int32, Int32)
      case @type
      when Type::RGB
        @value.as(Tuple(Int32, Int32, Int32))
      when Type::Indexed
        idx = @value.as(Int32)
        Color.rgb_from_ansi256(idx)
      when Type::Named
        idx = @value.as(Int32)
        Color.rgb_from_ansi16(idx)
      else
        {0, 0, 0}
      end
    end

    # Convert this color to a given profile (degrading if needed)
    def to_profile(profile : ColorProfile) : Color?
      case profile
      when ColorProfile::ASCII
        nil
      when ColorProfile::ANSI
        r, g, b = to_rgb
        Color.new(Type::Named, Color.rgb_to_ansi16(r, g, b))
      when ColorProfile::ANSI256
        case @type
        when Type::Indexed, Type::Named
          self
        else
          r, g, b = to_rgb
          Color.indexed(Color.rgb_to_ansi256(r, g, b))
        end
      else
        self
      end
    end

    def self.rgb_from_ansi16(idx : Int32) : Tuple(Int32, Int32, Int32)
      palette = [
        {0, 0, 0},
        {205, 0, 0},
        {0, 205, 0},
        {205, 205, 0},
        {0, 0, 238},
        {205, 0, 205},
        {0, 205, 205},
        {229, 229, 229},
        {127, 127, 127},
        {255, 0, 0},
        {0, 255, 0},
        {255, 255, 0},
        {92, 92, 255},
        {255, 0, 255},
        {0, 255, 255},
        {255, 255, 255},
      ]
      palette[idx.clamp(0, 15)]
    end

    def self.rgb_from_ansi256(idx : Int32) : Tuple(Int32, Int32, Int32)
      return rgb_from_ansi16(idx) if idx < 16
      if idx >= 232
        gray = 8 + 10 * (idx - 232)
        {gray, gray, gray}
      else
        c = idx - 16
        r = c // 36
        g = (c % 36) // 6
        b = c % 6
        {
          ansi_component(r),
          ansi_component(g),
          ansi_component(b),
        }
      end
    end

    def self.ansi_component(v : Int32) : Int32
      return 0 if v <= 0
      55 + v * 40
    end

    def self.rgb_to_ansi256(r : Int32, g : Int32, b : Int32) : Int32
      # Compute color cube index
      rr = component_to_ansi_level(r)
      gg = component_to_ansi_level(g)
      bb = component_to_ansi_level(b)
      cube_idx = 16 + 36 * rr + 6 * gg + bb
      cube_r, cube_g, cube_b = rgb_from_ansi256(cube_idx)

      # Compute grayscale index
      gray = ((r + g + b) / 3).to_f
      gray_level = (((gray - 8.0) / 10.0).round.to_i32).clamp(0, 23)
      gray_idx = 232 + gray_level
      gray_val = 8 + gray_level * 10

      cube_dist = color_distance(r, g, b, cube_r, cube_g, cube_b)
      gray_dist = color_distance(r, g, b, gray_val, gray_val, gray_val)

      cube_dist <= gray_dist ? cube_idx : gray_idx
    end

    def self.rgb_to_ansi16(r : Int32, g : Int32, b : Int32) : Int32
      # Use ansi256 conversion then map to nearest of 16 colors
      idx256 = rgb_to_ansi256(r, g, b)
      target_r, target_g, target_b = rgb_from_ansi256(idx256)
      best_idx = 0
      best_dist = Int32::MAX
      16.times do |i|
        pr, pg, pb = rgb_from_ansi16(i)
        dist = color_distance(target_r, target_g, target_b, pr, pg, pb)
        if dist < best_dist
          best_dist = dist
          best_idx = i
        end
      end
      best_idx
    end

    def self.component_to_ansi_level(c : Int32) : Int32
      return 0 if c < 48
      return 5 if c > 228
      ((c - 35) // 40).clamp(0, 5)
    end

    def self.color_distance(r1 : Int32, g1 : Int32, b1 : Int32, r2 : Int32, g2 : Int32, b2 : Int32) : Int32
      dr = r1 - r2
      dg = g1 - g2
      db = b1 - b2
      dr*dr + dg*dg + db*db
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

    # Get RGBA components (0-65535) similar to Go's color.Color RGBA
    def rgba(renderer : StyleRenderer = StyleRenderer.default) : Tuple(UInt32, UInt32, UInt32, UInt32)
      r8, g8, b8 = to_rgb
      {(r8 * 257).to_u32, (g8 * 257).to_u32, (b8 * 257).to_u32, 0xFFFFu32}
    end

    # For equality comparison
    def ==(other : Color) : Bool
      @type == other.type && @value == other.value
    end
  end

  # Text utilities for measuring and manipulating styled text
  module Text
    # Strip ANSI escape codes from text
    def self.strip_ansi(text : String) : String
      text.gsub(/\e\[[0-9;]*m/, "")
    end

    # Calculate the display width of text (ignoring ANSI codes)
    def self.width(text : String) : Int32
      strip_ansi(text).each_char.sum { |c| char_width(c) }
    end

    # Get width of a single character (handles wide chars)
    def self.char_width(c : Char) : Int32
      # Simple heuristic: CJK and some other chars are double-width
      code = c.ord
      if code >= 0x1100 && (
           (code <= 0x115F) ||                   # Hangul Jamo
           (code >= 0x2E80 && code <= 0x9FFF) || # CJK
           (code >= 0xAC00 && code <= 0xD7A3) || # Hangul Syllables
           (code >= 0xF900 && code <= 0xFAFF) || # CJK Compatibility
           (code >= 0xFE10 && code <= 0xFE1F) || # Vertical forms
           (code >= 0xFE30 && code <= 0xFE6F) || # CJK Compatibility Forms
           (code >= 0xFF00 && code <= 0xFF60) || # Fullwidth Forms
           (code >= 0xFFE0 && code <= 0xFFE6) || # Fullwidth Forms
           (code >= 0x20000 && code <= 0x2FFFF)  # CJK Extension B+
         )
        2
      else
        1
      end
    end

    # Truncate text to width, respecting ANSI codes
    def self.truncate(text : String, width : Int32) : String
      return text if width <= 0

      visible_width = 0
      result = String::Builder.new
      in_escape = false

      text.each_char do |c|
        if c == '\e'
          in_escape = true
          result << c
        elsif in_escape
          result << c
          in_escape = false if c == 'm'
        elsif visible_width < width
          char_w = char_width(c)
          if visible_width + char_w <= width
            result << c
            visible_width += char_w
          end
        end
      end

      result.to_s
    end
  end

  # NoColor represents the absence of color (used to disable styling)
  struct NoColor
    def rgba(renderer : StyleRenderer = StyleRenderer.default) : Tuple(UInt32, UInt32, UInt32, UInt32)
      {0u32, 0u32, 0u32, 0xFFFFu32}
    end
  end

  # AdaptiveColor provides different colors for light and dark backgrounds
  struct AdaptiveColor
    getter light : Color
    getter dark : Color

    def initialize(@light : Color, @dark : Color)
    end

    def resolve(renderer : StyleRenderer = StyleRenderer.default) : Color
      renderer.has_dark_background? ? @dark : @light
    end

    def rgba(renderer : StyleRenderer = StyleRenderer.default) : Tuple(UInt32, UInt32, UInt32, UInt32)
      resolve(renderer).rgba(renderer)
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
    def resolve(renderer : StyleRenderer = StyleRenderer.default) : Color?
      case renderer.color_profile
      when ColorProfile::TrueColor
        @true_color || @ansi256 || @ansi
      when ColorProfile::ANSI256
        @ansi256 || @ansi || @true_color
      when ColorProfile::ANSI
        @ansi || @ansi256 || @true_color
      else
        nil
      end
    end

    def rgba(renderer : StyleRenderer = StyleRenderer.default) : Tuple(UInt32, UInt32, UInt32, UInt32)
      (resolve(renderer) || Color::BLACK).rgba(renderer)
    end
  end

  # Style is the core styling primitive - a complete Lipgloss port
  class Style
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
    @fg_color : Color | AdaptiveColor | CompleteColor | NoColor | Nil = nil
    @bg_color : Color | AdaptiveColor | CompleteColor | NoColor | Nil = nil

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
    @margin_bg_color : Color | AdaptiveColor | NoColor | Nil = nil

    # Border
    @border_style : Border = Border.new
    @border_top_fg_color : Color | AdaptiveColor | NoColor | Nil = nil
    @border_right_fg_color : Color | AdaptiveColor | NoColor | Nil = nil
    @border_bottom_fg_color : Color | AdaptiveColor | NoColor | Nil = nil
    @border_left_fg_color : Color | AdaptiveColor | NoColor | Nil = nil
    @border_top_bg_color : Color | AdaptiveColor | NoColor | Nil = nil
    @border_right_bg_color : Color | AdaptiveColor | NoColor | Nil = nil
    @border_bottom_bg_color : Color | AdaptiveColor | NoColor | Nil = nil
    @border_left_bg_color : Color | AdaptiveColor | NoColor | Nil = nil

    # Other
    @tab_width : Int32 = TAB_WIDTH_DEFAULT
    @transform : Proc(String, String)? = nil
    @renderer : StyleRenderer? = nil

    def initialize
    end

    # Create a new style (factory method like Lipgloss)
    def self.new_style : Style
      StyleRenderer.default.new_style
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

    # Bind this style to a specific renderer (for color profiles/backgrounds)
    def renderer(r : StyleRenderer) : Style
      @renderer = r
      self
    end

    # Colors
    def foreground(c : Color | AdaptiveColor | CompleteColor) : Style
      @fg_color = c
      @props |= Props::Foreground
      self
    end

    def foreground(hex : String) : Style
      foreground(Color.from_hex(hex))
    end

    def background(c : Color | AdaptiveColor | CompleteColor) : Style
      @bg_color = c
      @props |= Props::Background
      self
    end

    def background(hex : String) : Style
      background(Color.from_hex(hex))
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

    def margin_background(c : Color | AdaptiveColor) : Style
      @margin_bg_color = c
      @props |= Props::MarginBackground
      self
    end

    # Border
    def border(b : Border) : Style
      border(b, true)
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

    def border_foreground(c : Color | AdaptiveColor) : Style
      @border_top_fg_color = c
      @border_right_fg_color = c
      @border_bottom_fg_color = c
      @border_left_fg_color = c
      @props |= Props::BorderTopForeground | Props::BorderRightForeground |
                Props::BorderBottomForeground | Props::BorderLeftForeground
      self
    end

    def border_top_foreground(c : Color | AdaptiveColor) : Style
      @border_top_fg_color = c
      @props |= Props::BorderTopForeground
      self
    end

    def border_right_foreground(c : Color | AdaptiveColor) : Style
      @border_right_fg_color = c
      @props |= Props::BorderRightForeground
      self
    end

    def border_bottom_foreground(c : Color | AdaptiveColor) : Style
      @border_bottom_fg_color = c
      @props |= Props::BorderBottomForeground
      self
    end

    def border_left_foreground(c : Color | AdaptiveColor) : Style
      @border_left_fg_color = c
      @props |= Props::BorderLeftForeground
      self
    end

    def border_background(c : Color | AdaptiveColor) : Style
      @border_top_bg_color = c
      @border_right_bg_color = c
      @border_bottom_bg_color = c
      @border_left_bg_color = c
      @props |= Props::BorderTopBackground | Props::BorderRightBackground |
                Props::BorderBottomBackground | Props::BorderLeftBackground
      self
    end

    def border_top_background(c : Color | AdaptiveColor) : Style
      @border_top_bg_color = c
      @props |= Props::BorderTopBackground
      self
    end

    def border_right_background(c : Color | AdaptiveColor) : Style
      @border_right_bg_color = c
      @props |= Props::BorderRightBackground
      self
    end

    def border_bottom_background(c : Color | AdaptiveColor) : Style
      @border_bottom_bg_color = c
      @props |= Props::BorderBottomBackground
      self
    end

    def border_left_background(c : Color | AdaptiveColor) : Style
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
    def set_string(*strs : String) : Style
      @value = strs.join(" ")
      self
    end

    # ========== GETTERS ==========

    # Crystal-idiomatic boolean getters
    def bold? : Bool
      get_bool(Props::Bold)
    end

    def italic? : Bool
      get_bool(Props::Italic)
    end

    def underline? : Bool
      get_bool(Props::Underline)
    end

    def strikethrough? : Bool
      get_bool(Props::Strikethrough)
    end

    def reverse? : Bool
      get_bool(Props::Reverse)
    end

    def blink? : Bool
      get_bool(Props::Blink)
    end

    def faint? : Bool
      get_bool(Props::Faint)
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

    def renderer : StyleRenderer
      @renderer || StyleRenderer.default
    end

    def foreground_color : Color?
      resolve_color(@fg_color)
    end

    def background_color : Color?
      resolve_color(@bg_color)
    end

    # Aliases for backwards compatibility
    def get_bold : Bool
      bold?
    end

    def get_italic : Bool
      italic?
    end

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

    def get_strikethrough_spaces : Bool
      strikethrough_spaces?
    end

    def get_color_whitespace : Bool
      color_whitespace?
    end

    def get_foreground : Color?
      foreground_color
    end

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
      get_border_top ? @border_style.get_top_size : 0
    end

    def get_border_right_size : Int32
      get_border_right ? @border_style.get_right_size : 0
    end

    def get_border_bottom_size : Int32
      get_border_bottom ? @border_style.get_bottom_size : 0
    end

    def get_border_left_size : Int32
      get_border_left ? @border_style.get_left_size : 0
    end

    def get_horizontal_border_size : Int32
      get_border_left_size + get_border_right_size
    end

    def get_vertical_border_size : Int32
      get_border_top_size + get_border_bottom_size
    end

    def get_horizontal_frame_size : Int32
      get_horizontal_border_size
    end

    def get_vertical_frame_size : Int32
      get_vertical_border_size
    end

    def get_frame_size : Tuple(Int32, Int32)
      {get_horizontal_frame_size, get_vertical_frame_size}
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
        if other.@props.{{prop.id.underscore}}?
          @props = Props.new(@props.value | Props::{{prop.id}}.value)
          # Copy the attr bit from other
          bit_mask = 1u32 << Props::{{prop.id}}.value.trailing_zeros_count
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
        @tab_width, @transform, @renderer
      )
    end

    # Internal method to receive copied properties
    protected def copy_from(
      props : Props, value : String, attrs : UInt32,
      fg_color : Color | AdaptiveColor | CompleteColor | NoColor | Nil,
      bg_color : Color | AdaptiveColor | CompleteColor | NoColor | Nil,
      width : Int32, height : Int32, max_width : Int32, max_height : Int32,
      align_horizontal : Position, align_vertical : Position,
      padding_top : Int32, padding_right : Int32, padding_bottom : Int32, padding_left : Int32,
      margin_top : Int32, margin_right : Int32, margin_bottom : Int32, margin_left : Int32,
      margin_bg_color : Color | AdaptiveColor | NoColor | Nil,
      border_style : Border,
      border_top_fg_color : Color | AdaptiveColor | NoColor | Nil,
      border_right_fg_color : Color | AdaptiveColor | NoColor | Nil,
      border_bottom_fg_color : Color | AdaptiveColor | NoColor | Nil,
      border_left_fg_color : Color | AdaptiveColor | NoColor | Nil,
      border_top_bg_color : Color | AdaptiveColor | NoColor | Nil,
      border_right_bg_color : Color | AdaptiveColor | NoColor | Nil,
      border_bottom_bg_color : Color | AdaptiveColor | NoColor | Nil,
      border_left_bg_color : Color | AdaptiveColor | NoColor | Nil,
      tab_width : Int32, transform : Proc(String, String)?,
      renderer : StyleRenderer?,
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
      @renderer = renderer
    end

    # ========== STRING / RENDER ==========

    # String implements the Stringer interface
    def to_s : String
      render(@value)
    end

    # Render applies the style to the given string(s)
    def render : String
      render([] of String)
    end

    def render(*strs : String) : String
      render(strs.to_a)
    end

    def render(strs : Array(String)) : String
      str = @value.empty? ? strs.join(" ") : ([@value] + strs).join(" ")
      render_string(str)
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

      color_whitespace = get_color_whitespace
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
        str = word_wrap(str, wrap_at) if wrap_at > 0
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

      main_codes = base_codes.dup
      space_codes = base_codes.dup

      if underline_val
        main_codes << 4 << 4
        space_codes << 4 if underline_spaces
      elsif underline_spaces
        space_codes << 4
      end

      if strikethrough_val
        main_codes << 9
        space_codes << 9 if strikethrough_spaces
      elsif strikethrough_spaces
        space_codes << 9
      end

      use_space_styler = underline_val || strikethrough_val || underline_spaces || strikethrough_spaces

      # Apply text styling
      if main_codes.any? || space_codes.any?
        lines = str.split('\n')
        str = lines.map { |line| apply_codes_to_line(line, main_codes, space_codes, use_space_styler) }.join('\n')
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

    private def apply_codes_to_line(line : String, codes : Array(Int32), space_codes : Array(Int32), use_space_styler : Bool) : String
      return line if line.empty?

      if use_space_styler
        styled = String::Builder.new
        line.each_char do |ch|
          if ch == ' '
            if space_codes.any?
              styled << "\e[#{space_codes.join(';')}m#{ch}\e[0m"
            else
              styled << ch
            end
          else
            if codes.any?
              styled << "\e[#{codes.join(';')}m#{ch}\e[0m"
            else
              styled << ch
            end
          end
        end
        return styled.to_s
      end

      # default: style entire line as a block
      return line if codes.empty?
      "\e[#{codes.join(';')}m#{line}\e[0m"
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

    private def get_bool(prop : Props) : Bool
      (@attrs & (1u32 << prop.value.trailing_zeros_count)) != 0
    end

    private def is_set?(prop : Props) : Bool
      @props.includes?(prop)
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

    private def inherit_border_color(prop : Props, other : Style, color : Color | AdaptiveColor | Nil, &block : (Color | AdaptiveColor | Nil) ->)
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

    private def resolve_color(c : Color | AdaptiveColor | CompleteColor | NoColor | Nil) : Color?
      resolve_color(c, renderer)
    end

    private def resolve_color(c : Color | AdaptiveColor | CompleteColor | NoColor | Nil, r : StyleRenderer) : Color?
      case c
      when Color
        c.to_profile(r.color_profile)
      when AdaptiveColor
        resolve_color(c.resolve(r), r)
      when CompleteColor
        color = c.resolve(r)
        color ? resolve_color(color, r) : nil
      when NoColor
        nil
      else
        nil
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

    private def word_wrap(str : String, width : Int32) : String
      return str if width <= 0

      lines = str.split('\n')
      result = [] of String

      lines.each do |line|
        if Text.width(line) <= width
          result << line
        else
          # Simple word wrap
          words = line.split(' ')
          current_line = ""

          words.each do |word|
            if current_line.empty?
              current_line = word
            elsif Text.width(current_line) + 1 + Text.width(word) <= width
              current_line += " " + word
            else
              result << current_line
              current_line = word
            end
          end

          result << current_line unless current_line.empty?
        end
      end

      result.join('\n')
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
      width = lines.max_of? { |l| Text.width(l) } || 0

      # Apply horizontal margins
      if @margin_left > 0 || @margin_right > 0
        left_margin = " " * @margin_left
        lines = lines.map { |l| "#{left_margin}#{l}" }
      end

      # Apply vertical margins
      if @margin_top > 0
        @margin_top.times { lines.unshift("") }
      end

      if @margin_bottom > 0
        @margin_bottom.times { lines << "" }
      end

      lines.join('\n')
    end

    private def truncate_ansi(str : String, width : Int32) : String
      # Simple truncation - doesn't handle ANSI codes perfectly
      # TODO: Implement proper ANSI-aware truncation
      visible_width = 0
      result = String::Builder.new
      in_escape = false

      str.each_char do |c|
        if c == '\e'
          in_escape = true
          result << c
        elsif in_escape
          result << c
          in_escape = false if c == 'm'
        elsif visible_width < width
          result << c
          visible_width += 1
        end
      end

      result.to_s
    end
  end

  # ========== MODULE-LEVEL LAYOUT UTILITIES ==========

  # Join strings horizontally with alignment
  def self.join_horizontal(pos : Position, *blocks : String) : String
    join_horizontal_enum(pos, blocks.to_a)
  end

  def self.join_horizontal(pos_ratio : Float64, *blocks : String) : String
    join_horizontal_ratio(pos_ratio, blocks.to_a)
  end

  private def self.join_horizontal_enum(pos : Position, blocks : Array(String)) : String
    return "" if blocks.empty?

    block_lines = blocks.map(&.split('\n'))
    block_widths = block_lines.map { |lines| lines.max_of? { |l| Text.width(l) } || 0 }
    max_height = block_lines.max_of?(&.size) || 0

    padded_blocks = block_lines.map_with_index do |lines, i|
      width = block_widths[i]
      height_diff = max_height - lines.size
      empty_line = " " * width

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

  private def self.join_horizontal_ratio(pos_ratio : Float64, blocks : Array(String)) : String
    return "" if blocks.empty?
    return blocks.first if blocks.size == 1

    block_lines = blocks.map(&.split('\n'))
    block_widths = block_lines.map { |lines| lines.max_of? { |l| Text.width(l) } || 0 }
    max_height = block_lines.max_of?(&.size) || 0

    padded_blocks = block_lines.map_with_index do |lines, i|
      width = block_widths[i]
      height_diff = max_height - lines.size
      empty_line = " " * width

      if height_diff <= 0
        padded = lines
      else
        top = (height_diff * pos_ratio).round.to_i32
        bottom = height_diff - top
        padded = Array.new(top, empty_line) + lines + Array.new(bottom, empty_line)
      end

      padded.map do |line|
        gap = width - Text.width(line)
        gap > 0 ? line + " " * gap : line
      end
    end

    result = (0...max_height).map do |i|
      padded_blocks.map { |block| block[i]? || "" }.join
    end
    result.join('\n')
  end

  def self.join_horizontal(pos_ratio : Float64, blocks : Array(String)) : String
    # Treat ratio 0..1 between Top and Bottom
    join_horizontal(Position.new(pos_ratio_to_enum(pos_ratio)), blocks)
  end

  # Join strings vertically with alignment
  def self.join_vertical(pos : Position, *blocks : String) : String
    join_vertical_enum(pos, blocks.to_a)
  end

  def self.join_vertical(pos_ratio : Float64, *blocks : String) : String
    join_vertical_ratio(pos_ratio, blocks.to_a)
  end

  private def self.join_vertical_enum(pos : Position, blocks : Array(String)) : String
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

  private def self.join_vertical_ratio(pos_ratio : Float64, blocks : Array(String)) : String
    return "" if blocks.empty?
    return blocks.first if blocks.size == 1

    max_width = blocks.max_of? do |b|
      b.split('\n').max_of? { |l| Text.width(l) } || 0
    end || 0

    aligned = blocks.map do |block|
      lines = block.split('\n')
      lines.map do |line|
        gap = max_width - Text.width(line)
        if gap <= 0
          line
        else
          left = (gap * pos_ratio).round.to_i32
          right = gap - left
          " " * left + line + " " * right
        end
      end.join('\n')
    end

    aligned.join('\n')
  end

  # Range represents a span of visible cells to style
  struct Range
    getter start : Int32
    getter finish : Int32
    getter style : Style

    def initialize(@start : Int32, @finish : Int32, @style : Style)
    end

    def contains?(pos : Int32) : Bool
      pos >= @start && pos < @finish
    end
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

  # Return the first Unicode rune as a String (parity helper)
  def self.get_first_rune_as_string(str : String) : String
    return "" if str.empty?
    reader = Char::Reader.new(str)
    String.build { |io| io << reader.current_char }
  end

  # Apply styles to specific rune indices (parity with Lipgloss StyleRunes)
  def self.style_runes(str : String, indices : Array(Int32), match_style : Style, unmatched_style : Style = Style.new) : String
    index_set = indices.to_set
    builder = String::Builder.new
    current_match = index_set.includes?(0)
    chunk = String::Builder.new

    flush = ->(matched : Bool, chunk_str : String) do
      return if chunk_str.empty?
      style = matched ? match_style : unmatched_style
      builder << style.render(chunk_str)
    end

    str.each_char_with_index do |ch, idx|
      desired = index_set.includes?(idx)
      if idx == 0
        # already set
      elsif desired != current_match
        flush.call(current_match, chunk.to_s)
        chunk = String::Builder.new
        current_match = desired
      end
      chunk << ch
    end

    flush.call(current_match, chunk.to_s)
    builder.to_s
  end

  # Apply styles to ranges of visible cells (parity with Lipgloss StyleRanges)
  def self.style_ranges(str : String, ranges : Array(Range)) : String
    return str if ranges.empty?
    builder = String::Builder.new
    pos = 0
    current_range : Range? = nil
    chunk = String::Builder.new
    active_ansi = String::Builder.new

    flush = ->(range : Range?, chunk_str : String) do
      return if chunk_str.empty?
      if range
        builder << range.style.render(chunk_str)
        builder << active_ansi.to_s unless active_ansi.empty?
      else
        builder << chunk_str
      end
    end

    reader = Char::Reader.new(str)
    while reader.has_next?
      ch = reader.current_char
      if ch == '\e' # ANSI escape
        flush.call(current_range, chunk.to_s)
        chunk = String::Builder.new
        seq = String::Builder.new
        seq << ch
        reader.next_char
        while reader.has_next?
          c2 = reader.current_char
          seq << c2
          reader.next_char
          break if c2 == 'm'
        end
        seq_str = seq.to_s
        builder << seq_str
        active_ansi = String::Builder.new if seq_str.includes?("[0m")
        active_ansi << seq_str unless seq_str.includes?("[0m")
        next
      end

      ch_str = ch.to_s
      width = Text.char_width(ch)

      match = ranges.find { |r| r.contains?(pos) || r.contains?(pos + width - 1) }

      if match != current_range
        flush.call(current_range, chunk.to_s)
        chunk = String::Builder.new
        current_range = match
      end

      chunk << ch_str
      pos += width
      reader.next_char
    end

    flush.call(current_range, chunk.to_s)
    builder.to_s
  end

  def self.style_ranges(str : String, *ranges : Range) : String
    style_ranges(str, ranges.to_a)
  end

  # Create a new style (convenience)
  def self.new_style : Style
    Style.new
  end

  # Create a new renderer (parity helper)
  def self.new_renderer(io : IO = STDOUT) : StyleRenderer
    r = StyleRenderer.new
    r.output = io
    r
  end
end
