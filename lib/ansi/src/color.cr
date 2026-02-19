require "colorful"

module Ansi
  alias PaletteColor = Color | BasicColor | IndexedColor | ExtendedColor | TrueColor | RGBColor | HexColor | XRGBColor | XRGBAColor | Colorful::Color

  struct Color
    getter r : UInt8
    getter g : UInt8
    getter b : UInt8
    getter a : UInt8

    def initialize(@r : UInt8, @g : UInt8, @b : UInt8, @a : UInt8 = 0xff_u8)
    end

    def self.black : Color
      Color.new(0_u8, 0_u8, 0_u8, 0xff_u8)
    end

    def rgba : {UInt32, UInt32, UInt32, UInt32}
      {r.to_u32 * 0x101_u32, g.to_u32 * 0x101_u32, b.to_u32 * 0x101_u32, a.to_u32 * 0x101_u32}
    end
  end

  # BasicColor is an ANSI 3-bit or 4-bit color with a value from 0 to 15.
  struct BasicColor
    getter value : UInt8

    def initialize(@value : UInt8)
    end

    def rgba : {UInt32, UInt32, UInt32, UInt32}
      Ansi.ansi_to_rgb(value).rgba
    end

    # Constants
    Black         = BasicColor.new(0_u8)
    Red           = BasicColor.new(1_u8)
    Green         = BasicColor.new(2_u8)
    Yellow        = BasicColor.new(3_u8)
    Blue          = BasicColor.new(4_u8)
    Magenta       = BasicColor.new(5_u8)
    Cyan          = BasicColor.new(6_u8)
    White         = BasicColor.new(7_u8)
    BrightBlack   = BasicColor.new(8_u8)
    BrightRed     = BasicColor.new(9_u8)
    BrightGreen   = BasicColor.new(10_u8)
    BrightYellow  = BasicColor.new(11_u8)
    BrightBlue    = BasicColor.new(12_u8)
    BrightMagenta = BasicColor.new(13_u8)
    BrightCyan    = BasicColor.new(14_u8)
    BrightWhite   = BasicColor.new(15_u8)
  end

  # IndexedColor is an ANSI 256 (8-bit) color with a value from 0 to 255.
  struct IndexedColor
    getter value : UInt8

    def initialize(@value : UInt8)
    end

    def rgba : {UInt32, UInt32, UInt32, UInt32}
      Ansi.ansi_to_rgb(value).rgba
    end
  end

  # ExtendedColor is an ANSI 256 (8-bit) color with a value from 0 to 255.
  #
  # Deprecated: use [IndexedColor] instead.
  alias ExtendedColor = IndexedColor

  # TrueColor is a 24-bit color that can be used in the terminal.
  # This can be used to represent RGB colors.
  struct TrueColor
    getter value : UInt32

    def initialize(@value : UInt32)
    end

    def rgba : {UInt32, UInt32, UInt32, UInt32}
      r, g, b = Ansi.hex_to_rgb(value)
      {r.to_u32 * 0x101_u32, g.to_u32 * 0x101_u32, b.to_u32 * 0x101_u32, 0xFFFF_u32}
    end
  end

  # RGBColor is a 24-bit color that can be used in the terminal.
  # This can be used to represent RGB colors.
  struct RGBColor
    getter r : UInt8
    getter g : UInt8
    getter b : UInt8

    def initialize(@r : UInt8, @g : UInt8, @b : UInt8)
    end

    def rgba : {UInt32, UInt32, UInt32, UInt32}
      {r.to_u32 * 0x101_u32, g.to_u32 * 0x101_u32, b.to_u32 * 0x101_u32, 0xFFFF_u32}
    end
  end

  # HexColor is a color that can be formatted as a hex string.
  struct HexColor
    getter value : String

    def initialize(@value : String)
    end

    # Parses a hex string to UInt32 color value
    private def parse_hex : UInt32?
      str = @value
      return nil if str.empty?

      # Remove leading '#'
      if str[0] == '#'
        str = str[1..]
      end

      case str.size
      when 6 # RRGGBB
        str.to_u32(16) rescue nil
      when 3 # RGB
        # Expand to RRGGBB: #RGB -> #RRGGBB
        r = str[0].to_s * 2
        g = str[1].to_s * 2
        b = str[2].to_s * 2
        (r + g + b).to_u32(16) rescue nil
      when 8 # RRGGBBAA (ignore alpha for now, use RGB)
        (str[0...6].to_u32(16) rescue nil)
      else
        nil
      end
    end

    # Returns the underlying Color, or nil if invalid
    private def color : Color?
      hex_value = parse_hex
      return nil unless hex_value

      r, g, b = Ansi.hex_to_rgb(hex_value)
      Color.new(r, g, b)
    end

    # RGBA returns the red, green, blue and alpha components of the color.
    def rgba : {UInt32, UInt32, UInt32, UInt32}
      c = color
      return {0_u32, 0_u32, 0_u32, 0_u32} unless c
      c.rgba
    end

    # Hex returns the hex representation of the color.
    def hex : String
      c = color
      return "" unless c
      sprintf("#%02x%02x%02x", c.r, c.g, c.b)
    end

    # String returns the color as a hex string.
    def to_s : String
      hex
    end
  end

  # XRGBColor is a color that can be formatted as an XParseColor rgb: string.
  #
  # See: https://linux.die.net/man/3/xparsecolor
  struct XRGBColor
    getter color : Color?

    def initialize(@color : Color? = nil)
    end

    # RGBA returns the RGBA values of the color.
    def rgba : {UInt32, UInt32, UInt32, UInt32}
      if color = @color
        color.rgba
      else
        {0_u32, 0_u32, 0_u32, 0_u32}
      end
    end

    # String returns the color as an XParseColor rgb: string.
    def to_s : String
      return "" unless @color
      r, g, b, _ = rgba
      sprintf("rgb:%04x/%04x/%04x", r, g, b)
    end
  end

  # XRGBAColor is a color that can be formatted as an XParseColor rgba: string.
  #
  # See: https://linux.die.net/man/3/xparsecolor
  struct XRGBAColor
    getter color : Color?

    def initialize(@color : Color? = nil)
    end

    # RGBA returns the RGBA values of the color.
    def rgba : {UInt32, UInt32, UInt32, UInt32}
      if color = @color
        color.rgba
      else
        {0_u32, 0_u32, 0_u32, 0_u32}
      end
    end

    # String returns the color as an XParseColor rgba: string.
    def to_s : String
      return "" unless @color
      r, g, b, a = rgba
      sprintf("rgba:%04x/%04x/%04x/%04x", r, g, b, a)
    end
  end

  # ansi_to_rgb converts an ANSI color to a 24-bit RGB color.
  def self.ansi_to_rgb(ansi : UInt8) : Color
    ANSI_HEX[ansi]? || Color.black
  end

  # hex_to_rgb converts a number in hexadecimal format to red, green, and blue values.
  def self.hex_to_rgb(hex : UInt32) : {UInt8, UInt8, UInt8}
    r = ((hex >> 16) & 0xff).to_u8
    g = ((hex >> 8) & 0xff).to_u8
    b = (hex & 0xff).to_u8
    {r, g, b}
  end

  # color_to_hex_string converts a color to a hex string.
  def self.color_to_hex_string(color : Color) : String
    sprintf("#%02x%02x%02x", color.r, color.g, color.b)
  end

  # x_parse_color parses XParseColor-compatible strings into a Color.
  # Supports:
  # - #RGB
  # - #RRGGBB
  # - rgb:RRRR/GGGG/BBBB
  # - rgba:RRRR/GGGG/BBBB/AAAA
  #
  # Returns nil for invalid input.
  def self.x_parse_color(s : String) : Color?
    if s.starts_with?("#")
      begin
        colorful = Colorful::Color.hex(s)
      rescue ArgumentError
        return nil
      end
      r, g, b = colorful.rgb255
      return Color.new(r, g, b)
    elsif s.starts_with?("rgb:")
      parts = s[4..].split("/")
      return nil unless parts.size == 3
      r = shift_component(parts[0])
      g = shift_component(parts[1])
      b = shift_component(parts[2])
      return Color.new(r.to_u8, g.to_u8, b.to_u8, 0xff_u8)
    elsif s.starts_with?("rgba:")
      parts = s[5..].split("/")
      return nil unless parts.size == 4
      r = shift_component(parts[0])
      g = shift_component(parts[1])
      b = shift_component(parts[2])
      a = shift_component(parts[3])
      return Color.new(r.to_u8, g.to_u8, b.to_u8, a.to_u8)
    end
    nil
  end

  private def self.shift_component(value : String) : UInt32
    parsed = value.to_u32(16) rescue 0_u32
    parsed > 0xff_u32 ? (parsed >> 8) : parsed
  end

  # Convert256 overloads for various color types
  def self.convert_256(color : IndexedColor) : IndexedColor
    color
  end

  def self.convert_256(color : BasicColor) : IndexedColor
    rgb = ansi_to_rgb(color.value)
    convert_256(Colorful::Color.new(r: rgb.r.to_f64 / 255.0, g: rgb.g.to_f64 / 255.0, b: rgb.b.to_f64 / 255.0))
  end

  def self.convert_256(color : TrueColor) : IndexedColor
    r, g, b = hex_to_rgb(color.value)
    convert_256(Colorful::Color.new(r: r.to_f64 / 255.0, g: g.to_f64 / 255.0, b: b.to_f64 / 255.0))
  end

  def self.convert_256(color : Color) : IndexedColor
    convert_256(Colorful::Color.new(r: color.r.to_f64 / 255.0, g: color.g.to_f64 / 255.0, b: color.b.to_f64 / 255.0))
  end

  def self.convert_256(color : RGBColor) : IndexedColor
    convert_256(Colorful::Color.new(r: color.r.to_f64 / 255.0, g: color.g.to_f64 / 255.0, b: color.b.to_f64 / 255.0))
  end

  def self.convert_256(color : HexColor) : IndexedColor
    if c = color.color
      convert_256(Colorful::Color.new(r: c.r.to_f64 / 255.0, g: c.g.to_f64 / 255.0, b: c.b.to_f64 / 255.0))
    else
      IndexedColor.new(0_u8)
    end
  end

  def self.convert_256(color : XRGBColor) : IndexedColor
    if c = color.color
      convert_256(Colorful::Color.new(r: c.r.to_f64 / 255.0, g: c.g.to_f64 / 255.0, b: c.b.to_f64 / 255.0))
    else
      IndexedColor.new(0_u8)
    end
  end

  def self.convert_256(color : XRGBAColor) : IndexedColor
    if c = color.color
      convert_256(Colorful::Color.new(r: c.r.to_f64 / 255.0, g: c.g.to_f64 / 255.0, b: c.b.to_f64 / 255.0))
    else
      IndexedColor.new(0_u8)
    end
  end

  # Convert256 converts a color, usually a 24-bit color, to xterm(1) 256 color palette.
  def self.convert_256(color : Colorful::Color) : IndexedColor
    # Convert from Colorful::Color to IndexedColor
    # Implementation based on Go's Convert256
    r = color.r * 255
    g = color.g * 255
    b = color.b * 255

    q2c = [0x00, 0x5f, 0x87, 0xaf, 0xd7, 0xff]

    # Map RGB to 6x6x6 cube
    qr = to_6_cube(r)
    cr = q2c[qr]
    qg = to_6_cube(g)
    cg = q2c[qg]
    qb = to_6_cube(b)
    cb = q2c[qb]

    # If we have hit the color exactly, return early.
    ci = (36 * qr) + (6 * qg) + qb
    if cr == r.to_i && cg == g.to_i && cb == b.to_i
      return IndexedColor.new((16 + ci).to_u8)
    end

    # Work out the closest grey (average of RGB).
    grey_avg = (r + g + b).to_i / 3
    grey_idx = if grey_avg > 238
                 23
               else
                 val = grey_avg - 3
                 val < 0 ? 0 : val // 10
               end
    grey = 8 + (10 * grey_idx)

    # Return the one which is nearer to the original input rgb value
    c2 = Colorful::Color.new(r: cr.to_f64 / 255.0, g: cg.to_f64 / 255.0, b: cb.to_f64 / 255.0)
    g2 = Colorful::Color.new(r: grey.to_f64 / 255.0, g: grey.to_f64 / 255.0, b: grey.to_f64 / 255.0)
    color_dist = color.distance_hsluv(c2)
    gray_dist = color.distance_hsluv(g2)

    if color_dist <= gray_dist
      IndexedColor.new((16 + ci).to_u8)
    else
      IndexedColor.new((232 + grey_idx).to_u8)
    end
  end

  # Convert16 converts a color to a 16-color ANSI color. It will first
  # try to find a match in the 256 xterm(1) color palette, and then map that to
  # the 16-color ANSI palette.
  def self.convert_16(color : BasicColor) : BasicColor
    color
  end

  def self.convert_16(color : IndexedColor) : BasicColor
    BasicColor.new(ANSI256_TO_16[color.value])
  end

  def self.convert_16(color : TrueColor) : BasicColor
    # Convert TrueColor to Colorful::Color via Color
    r, g, b = hex_to_rgb(color.value)
    colorful = Colorful::Color.new(r: r.to_f64 / 255.0, g: g.to_f64 / 255.0, b: b.to_f64 / 255.0)
    convert_16(colorful)
  end

  def self.convert_16(color : Color) : BasicColor
    convert_16(to_colorful(color))
  end

  def self.convert_16(color : Colorful::Color) : BasicColor
    c256 = convert_256(color)
    BasicColor.new(ANSI256_TO_16[c256.value])
  end

  private def self.to_6_cube(v : Float64) : Int32
    vi = v.to_i
    if vi < 48
      0
    elsif vi < 115
      1
    else
      ((vi - 35) / 40).to_i
    end
  end

  # dist_sq calculates the squared distance between two colors.
  def self.dist_sq(r1 : Int32, g1 : Int32, b1 : Int32, r2 : Int32, g2 : Int32, b2 : Int32) : Int32
    ((r1 - r2) * (r1 - r2) + (g1 - g2) * (g1 - g2) + (b1 - b2) * (b1 - b2))
  end

  # nearest_color_index finds the index of the nearest color in the palette to the given color.
  def self.nearest_color_index(color : Color, palette : Array(Color)) : Int32
    return -1 if palette.empty?
    min_dist = Int32::MAX
    min_index = 0
    palette.each_with_index do |pal_color, i|
      dist = dist_sq(color.r.to_i32, color.g.to_i32, color.b.to_i32,
        pal_color.r.to_i32, pal_color.g.to_i32, pal_color.b.to_i32)
      if dist < min_dist
        min_dist = dist
        min_index = i
      end
    end
    min_index
  end

  # nearest_color finds the nearest color in the palette to the given color.
  def self.nearest_color(color : Color, palette : Array(Color)) : Color
    index = nearest_color_index(color, palette)
    index >= 0 ? palette[index] : color
  end

  # Convert Color to Colorful::Color
  private def self.to_colorful(color : Color) : Colorful::Color
    Colorful::Color.new(r: color.r.to_f64 / 255.0, g: color.g.to_f64 / 255.0, b: color.b.to_f64 / 255.0)
  end

  # 6-level cube values
  private SIX_CUBE = [0x00_u8, 0x5f_u8, 0x87_u8, 0xaf_u8, 0xd7_u8, 0xff_u8]

  # RGB values of ANSI colors (0-255)
  private ANSI_HEX = begin
    table = Array.new(256) { Color.black }
    # Colors 0-15: fixed ANSI colors
    table[0] = Color.new(0x00_u8, 0x00_u8, 0x00_u8, 0xFF_u8)  # black
    table[1] = Color.new(0x80_u8, 0x00_u8, 0x00_u8, 0xFF_u8)  # red
    table[2] = Color.new(0x00_u8, 0x80_u8, 0x00_u8, 0xFF_u8)  # green
    table[3] = Color.new(0x80_u8, 0x80_u8, 0x00_u8, 0xFF_u8)  # yellow
    table[4] = Color.new(0x00_u8, 0x00_u8, 0x80_u8, 0xFF_u8)  # blue
    table[5] = Color.new(0x80_u8, 0x00_u8, 0x80_u8, 0xFF_u8)  # magenta
    table[6] = Color.new(0x00_u8, 0x80_u8, 0x80_u8, 0xFF_u8)  # cyan
    table[7] = Color.new(0xc0_u8, 0xc0_u8, 0xc0_u8, 0xFF_u8)  # silver
    table[8] = Color.new(0x80_u8, 0x80_u8, 0x80_u8, 0xFF_u8)  # gray
    table[9] = Color.new(0xff_u8, 0x00_u8, 0x00_u8, 0xFF_u8)  # bright red
    table[10] = Color.new(0x00_u8, 0xff_u8, 0x00_u8, 0xFF_u8) # bright green
    table[11] = Color.new(0xff_u8, 0xff_u8, 0x00_u8, 0xFF_u8) # bright yellow
    table[12] = Color.new(0x00_u8, 0x00_u8, 0xff_u8, 0xFF_u8) # bright blue
    table[13] = Color.new(0xff_u8, 0x00_u8, 0xff_u8, 0xFF_u8) # bright magenta
    table[14] = Color.new(0x00_u8, 0xff_u8, 0xff_u8, 0xFF_u8) # bright cyan
    table[15] = Color.new(0xff_u8, 0xff_u8, 0xff_u8, 0xFF_u8) # white

    # Colors 16-231: 6x6x6 color cube
    (16...232).each do |i|
      idx = i - 16
      b = idx % 6
      g = (idx // 6) % 6
      r = idx // 36
      table[i] = Color.new(SIX_CUBE[r], SIX_CUBE[g], SIX_CUBE[b], 0xFF_u8)
    end

    # Colors 232-255: grayscale
    (232...256).each do |i|
      gray = 8_u8 + ((i - 232) * 10).to_u8
      table[i] = Color.new(gray, gray, gray, 0xFF_u8)
    end

    table
  end

  # Mapping from 256-color index to 16-color ANSI palette
  private ANSI256_TO_16 = StaticArray[
    0_u8, 1_u8, 2_u8, 3_u8, 4_u8, 5_u8, 6_u8, 7_u8, 8_u8, 9_u8, 10_u8, 11_u8, 12_u8, 13_u8, 14_u8, 15_u8,
    0_u8, 4_u8, 4_u8, 4_u8, 12_u8, 12_u8, 2_u8, 6_u8, 4_u8, 4_u8, 12_u8, 12_u8, 2_u8, 2_u8, 6_u8, 4_u8,
    12_u8, 12_u8, 2_u8, 2_u8, 2_u8, 6_u8, 12_u8, 12_u8, 10_u8, 10_u8, 10_u8, 10_u8, 14_u8, 12_u8, 10_u8, 10_u8,
    10_u8, 10_u8, 10_u8, 14_u8, 1_u8, 5_u8, 4_u8, 4_u8, 12_u8, 12_u8, 3_u8, 8_u8, 4_u8, 4_u8, 12_u8, 12_u8,
    2_u8, 2_u8, 6_u8, 4_u8, 12_u8, 12_u8, 2_u8, 2_u8, 2_u8, 6_u8, 12_u8, 12_u8, 10_u8, 10_u8, 10_u8, 10_u8,
    14_u8, 12_u8, 10_u8, 10_u8, 10_u8, 10_u8, 10_u8, 14_u8, 1_u8, 1_u8, 5_u8, 4_u8, 12_u8, 12_u8, 1_u8, 1_u8,
    5_u8, 4_u8, 12_u8, 12_u8, 3_u8, 3_u8, 8_u8, 4_u8, 12_u8, 12_u8, 2_u8, 2_u8, 2_u8, 6_u8, 12_u8, 12_u8,
    10_u8, 10_u8, 10_u8, 10_u8, 14_u8, 12_u8, 10_u8, 10_u8, 10_u8, 10_u8, 10_u8, 14_u8, 1_u8, 1_u8, 1_u8, 5_u8,
    12_u8, 12_u8, 1_u8, 1_u8, 1_u8, 5_u8, 12_u8, 12_u8, 1_u8, 1_u8, 1_u8, 5_u8, 12_u8, 12_u8, 3_u8, 3_u8,
    3_u8, 7_u8, 12_u8, 12_u8, 10_u8, 10_u8, 10_u8, 10_u8, 14_u8, 12_u8, 10_u8, 10_u8, 10_u8, 10_u8, 10_u8, 14_u8,
    9_u8, 9_u8, 9_u8, 9_u8, 13_u8, 12_u8, 9_u8, 9_u8, 9_u8, 9_u8, 13_u8, 12_u8, 9_u8, 9_u8, 9_u8, 9_u8,
    13_u8, 12_u8, 9_u8, 9_u8, 9_u8, 9_u8, 13_u8, 12_u8, 11_u8, 11_u8, 11_u8, 11_u8, 7_u8, 12_u8, 10_u8, 10_u8,
    10_u8, 10_u8, 10_u8, 14_u8, 9_u8, 9_u8, 9_u8, 9_u8, 9_u8, 13_u8, 9_u8, 9_u8, 9_u8, 9_u8, 9_u8, 13_u8,
    9_u8, 9_u8, 9_u8, 9_u8, 9_u8, 13_u8, 9_u8, 9_u8, 9_u8, 9_u8, 9_u8, 13_u8, 9_u8, 9_u8, 9_u8, 9_u8,
    9_u8, 13_u8, 11_u8, 11_u8, 11_u8, 11_u8, 11_u8, 15_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 8_u8, 8_u8,
    8_u8, 8_u8, 8_u8, 8_u8, 7_u8, 7_u8, 7_u8, 7_u8, 7_u8, 7_u8, 15_u8, 15_u8, 15_u8, 15_u8, 15_u8, 15_u8,
  ]
end
