require "colorful"

module Ansi
  # Attr is a SGR (Select Graphic Rendition) style attribute.
  alias Attr = Int32

  # AnyColor is a union of all color types that can be used with Style.
  alias AnyColor = BasicColor | IndexedColor | TrueColor | Color | Colorful::Color | Nil

  # ResetStyle is a SGR (Select Graphic Rendition) style sequence that resets
  # all attributes.
  # See: https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
  ResetStyle = "\e[m"

  # Style represents an ANSI SGR (Select Graphic Rendition) style.
  class Style
    getter attrs : Array(String)

    def initialize(attrs : Array(String))
      @attrs = attrs
    end

    # NewStyle returns a new style with the given attributes. Attributes are SGR
    # (Select Graphic Rendition) codes that control text formatting like bold,
    # italic, colors, etc.
    def self.new(attrs : Array(Attr)) : Style
      if attrs.empty?
        return Style.new([] of String)
      end

      strs = [] of String
      attrs.each do |a|
        str = ATTR_STRINGS[a]?
        if str
          strs << str
        else
          a = 0 if a < 0
          strs << a.to_s
        end
      end
      Style.new(strs)
    end

    # String returns the ANSI SGR (Select Graphic Rendition) style sequence for
    # the given style.
    def to_s : String
      if @attrs.empty?
        ResetStyle
      else
        "\e[" + @attrs.join(";") + "m"
      end
    end

    # Styled returns a styled string with the given style applied. The style is
    # applied at the beginning and reset at the end of the string.
    def styled(str : String) : String
      if @attrs.empty?
        str
      else
        to_s + str + ResetStyle
      end
    end

    # Append an attribute string and return a new Style
    private def append_attr(str : String) : Style
      Style.new(@attrs + [str])
    end

    # Bold appends the bold or normal intensity style attribute to the style.
    def bold : Style
      append_attr(ATTR_STRINGS[AttrBold])
    end

    # Faint appends the faint or normal intensity style attribute to the style.
    def faint : Style
      append_attr(ATTR_STRINGS[AttrFaint])
    end

    # Italic appends the italic or no italic style attribute to the style.
    # When v is true, text is rendered in italic. When false, italic is disabled.
    def italic(v : Bool) : Style
      if v
        append_attr(ATTR_STRINGS[AttrItalic])
      else
        append_attr(ATTR_STRINGS[AttrNoItalic])
      end
    end

    # Underline appends the underline or no underline style attribute to the style.
    # When v is true, text is underlined. When false, underline is disabled.
    def underline(v : Bool) : Style
      if v
        append_attr(ATTR_STRINGS[AttrUnderline])
      else
        append_attr(ATTR_STRINGS[AttrNoUnderline])
      end
    end

    # DefaultBackgroundColor appends the default background color style attribute to the style.
    def default_background_color : Style
      append_attr(ATTR_STRINGS[AttrDefaultBackgroundColor])
    end

    # ForegroundColor appends the foreground color style attribute to the style.
    # If c is nil, the default foreground color is used.
    def foreground_color(c : AnyColor = nil) : Style
      if c.nil?
        append_attr(ATTR_STRINGS[AttrDefaultForegroundColor])
      else
        append_attr(foreground_color_string(c))
      end
    end

    # BackgroundColor appends the background color style attribute to the style.
    # If c is nil, the default background color is used.
    def background_color(c : AnyColor = nil) : Style
      if c.nil?
        append_attr(ATTR_STRINGS[AttrDefaultBackgroundColor])
      else
        append_attr(background_color_string(c))
      end
    end

    # UnderlineColor appends the underline color style attribute to the style.
    # If c is nil, the default underline color is used.
    def underline_color(c : AnyColor = nil) : Style
      if c.nil?
        append_attr(ATTR_STRINGS[AttrDefaultUnderlineColor])
      else
        append_attr(underline_color_string(c))
      end
    end

    # Reset appends the reset style attribute to the style. This resets all
    # formatting attributes to their defaults.
    def reset : Style
      append_attr(ATTR_STRINGS[AttrReset])
    end

    # Normal appends the normal intensity style attribute to the style. This
    # resets Bold and Faint attributes.
    def normal : Style
      append_attr(ATTR_STRINGS[AttrNormalIntensity])
    end

    # Blink appends the slow blink or no blink style attribute to the style.
    # When v is true, text blinks slowly (less than 150 per minute). When false,
    # blinking is disabled.
    def blink(v : Bool) : Style
      if v
        append_attr(ATTR_STRINGS[AttrBlink])
      else
        append_attr(ATTR_STRINGS[AttrNoBlink])
      end
    end

    # RapidBlink appends the rapid blink or no blink style attribute to the style.
    # When v is true, text blinks rapidly (150+ per minute). When false, blinking
    # is disabled.
    # Note that this is not widely supported in terminal emulators.
    def rapid_blink(v : Bool) : Style
      if v
        append_attr(ATTR_STRINGS[AttrRapidBlink])
      else
        append_attr(ATTR_STRINGS[AttrNoBlink])
      end
    end

    # Reverse appends the reverse or no reverse style attribute to the style.
    # When v is true, foreground and background colors are swapped. When false,
    # reverse video is disabled.
    def reverse(v : Bool) : Style
      if v
        append_attr(ATTR_STRINGS[AttrReverse])
      else
        append_attr(ATTR_STRINGS[AttrNoReverse])
      end
    end

    # Conceal appends the conceal or no conceal style attribute to the style.
    # When v is true, text is hidden/concealed. When false, concealment is
    # disabled.
    def conceal(v : Bool) : Style
      if v
        append_attr(ATTR_STRINGS[AttrConceal])
      else
        append_attr(ATTR_STRINGS[AttrNoConceal])
      end
    end

    # Strikethrough appends the strikethrough or no strikethrough style attribute
    # to the style. When v is true, text is rendered with a horizontal line through
    # it. When false, strikethrough is disabled.
    def strikethrough(v : Bool) : Style
      if v
        append_attr(ATTR_STRINGS[AttrStrikethrough])
      else
        append_attr(ATTR_STRINGS[AttrNoStrikethrough])
      end
    end

    # UnderlineStyle appends the underline style attribute to the style.
    # Supports various underline styles including single, double, curly, dotted,
    # and dashed.
    def underline_style(u : Underline) : Style
      case u
      when Underline::None
        underline(false)
      when Underline::Single
        underline(true)
      when Underline::Double
        append_attr("4:2")
      when Underline::Curly
        append_attr("4:3")
      when Underline::Dotted
        append_attr("4:4")
      when Underline::Dashed
        append_attr("4:5")
      else
        self
      end
    end

    # Underline represents an ANSI SGR (Select Graphic Rendition) underline style.
    enum Underline
      None
      Single
      Double
      Curly
      Dotted
      Dashed
    end

    # UnderlineStyle represents an ANSI underline style.
    # Deprecated: use [Underline] instead.
    alias UnderlineStyle = Underline

    # Underline styles constants.
    UnderlineNone   = Underline::None
    UnderlineSingle = Underline::Single
    UnderlineDouble = Underline::Double
    UnderlineCurly  = Underline::Curly
    UnderlineDotted = Underline::Dotted
    UnderlineDashed = Underline::Dashed

    # Underline styles constants (deprecated aliases for compatibility)
    NoUnderlineStyle     = Underline::None
    SingleUnderlineStyle = Underline::Single
    DoubleUnderlineStyle = Underline::Double
    CurlyUnderlineStyle  = Underline::Curly
    DottedUnderlineStyle = Underline::Dotted
    DashedUnderlineStyle = Underline::Dashed

    # More deprecated constants
    UnderlineStyleNone   = Underline::None
    UnderlineStyleSingle = Underline::Single
    UnderlineStyleDouble = Underline::Double
    UnderlineStyleCurly  = Underline::Curly
    UnderlineStyleDotted = Underline::Dotted
    UnderlineStyleDashed = Underline::Dashed

    # Private helper functions for color string conversion
    # ameba:disable Metrics/CyclomaticComplexity
    private def foreground_color_string(c : BasicColor | IndexedColor | TrueColor | Color | Colorful::Color) : String
      case c
      when BasicColor
        case c.value
        when  0 then ATTR_STRINGS[AttrBlackForegroundColor]
        when  1 then ATTR_STRINGS[AttrRedForegroundColor]
        when  2 then ATTR_STRINGS[AttrGreenForegroundColor]
        when  3 then ATTR_STRINGS[AttrYellowForegroundColor]
        when  4 then ATTR_STRINGS[AttrBlueForegroundColor]
        when  5 then ATTR_STRINGS[AttrMagentaForegroundColor]
        when  6 then ATTR_STRINGS[AttrCyanForegroundColor]
        when  7 then ATTR_STRINGS[AttrWhiteForegroundColor]
        when  8 then ATTR_STRINGS[AttrBrightBlackForegroundColor]
        when  9 then ATTR_STRINGS[AttrBrightRedForegroundColor]
        when 10 then ATTR_STRINGS[AttrBrightGreenForegroundColor]
        when 11 then ATTR_STRINGS[AttrBrightYellowForegroundColor]
        when 12 then ATTR_STRINGS[AttrBrightBlueForegroundColor]
        when 13 then ATTR_STRINGS[AttrBrightMagentaForegroundColor]
        when 14 then ATTR_STRINGS[AttrBrightCyanForegroundColor]
        when 15 then ATTR_STRINGS[AttrBrightWhiteForegroundColor]
        else
          "39" # Default foreground
        end
      when IndexedColor
        "38;5;" + c.value.to_s
      when TrueColor
        r, g, b = Ansi.hex_to_rgb(c.value)
        "38;2;" + r.to_s + ";" + g.to_s + ";" + b.to_s
      when Colorful::Color
        "38;2;" + (c.r * 255).to_i.to_s + ";" + (c.g * 255).to_i.to_s + ";" + (c.b * 255).to_i.to_s
      else
        # Assume it's a Color struct
        "38;2;" + c.r.to_s + ";" + c.g.to_s + ";" + c.b.to_s
      end
    end

    # ameba:disable Metrics/CyclomaticComplexity
    private def background_color_string(c : BasicColor | IndexedColor | TrueColor | Color | Colorful::Color) : String
      case c
      when BasicColor
        case c.value
        when  0 then ATTR_STRINGS[AttrBlackBackgroundColor]
        when  1 then ATTR_STRINGS[AttrRedBackgroundColor]
        when  2 then ATTR_STRINGS[AttrGreenBackgroundColor]
        when  3 then ATTR_STRINGS[AttrYellowBackgroundColor]
        when  4 then ATTR_STRINGS[AttrBlueBackgroundColor]
        when  5 then ATTR_STRINGS[AttrMagentaBackgroundColor]
        when  6 then ATTR_STRINGS[AttrCyanBackgroundColor]
        when  7 then ATTR_STRINGS[AttrWhiteBackgroundColor]
        when  8 then ATTR_STRINGS[AttrBrightBlackBackgroundColor]
        when  9 then ATTR_STRINGS[AttrBrightRedBackgroundColor]
        when 10 then ATTR_STRINGS[AttrBrightGreenBackgroundColor]
        when 11 then ATTR_STRINGS[AttrBrightYellowBackgroundColor]
        when 12 then ATTR_STRINGS[AttrBrightBlueBackgroundColor]
        when 13 then ATTR_STRINGS[AttrBrightMagentaBackgroundColor]
        when 14 then ATTR_STRINGS[AttrBrightCyanBackgroundColor]
        when 15 then ATTR_STRINGS[AttrBrightWhiteBackgroundColor]
        else
          "49" # Default background
        end
      when IndexedColor
        "48;5;" + c.value.to_s
      when TrueColor
        r, g, b = Ansi.hex_to_rgb(c.value)
        "48;2;" + r.to_s + ";" + g.to_s + ";" + b.to_s
      when Colorful::Color
        "48;2;" + (c.r * 255).to_i.to_s + ";" + (c.g * 255).to_i.to_s + ";" + (c.b * 255).to_i.to_s
      else
        # Assume it's a Color struct
        "48;2;" + c.r.to_s + ";" + c.g.to_s + ";" + c.b.to_s
      end
    end

    private def underline_color_string(c : BasicColor | IndexedColor | TrueColor | Color | Colorful::Color) : String
      case c
      when BasicColor
        # NOTE: we can't use 3-bit and 4-bit ANSI color codes with underline
        # color, use 256-color instead.
        "58;5;" + c.value.to_s
      when IndexedColor
        "58;5;" + c.value.to_s
      when TrueColor
        r, g, b = Ansi.hex_to_rgb(c.value)
        "58;2;" + r.to_s + ";" + g.to_s + ";" + b.to_s
      when Colorful::Color
        "58;2;" + (c.r * 255).to_i.to_s + ";" + (c.g * 255).to_i.to_s + ";" + (c.b * 255).to_i.to_s
      else
        # Assume it's a Color struct
        "58;2;" + c.r.to_s + ";" + c.g.to_s + ";" + c.b.to_s
      end
    end

    # Deprecated methods for compatibility with Go API

    # NoItalic appends the no italic style attribute to the style.
    #
    # Deprecated: use #italic(false) instead.
    def no_italic : Style
      append_attr(ATTR_STRINGS[AttrNoItalic])
    end

    # NoUnderline appends the no underline style attribute to the style.
    #
    # Deprecated: use #underline(false) instead.
    def no_underline : Style
      append_attr(ATTR_STRINGS[AttrNoUnderline])
    end

    # NoBlink appends the no blink style attribute to the style.
    #
    # Deprecated: use #blink(false) or #rapid_blink(false) instead.
    def no_blink : Style
      append_attr(ATTR_STRINGS[AttrNoBlink])
    end

    # NoReverse appends the no reverse style attribute to the style.
    #
    # Deprecated: use #reverse(false) instead.
    def no_reverse : Style
      append_attr(ATTR_STRINGS[AttrNoReverse])
    end

    # NoConceal appends the no conceal style attribute to the style.
    #
    # Deprecated: use #conceal(false) instead.
    def no_conceal : Style
      append_attr(ATTR_STRINGS[AttrNoConceal])
    end

    # NoStrikethrough appends the no strikethrough style attribute to the style.
    #
    # Deprecated: use #strikethrough(false) instead.
    def no_strikethrough : Style
      append_attr(ATTR_STRINGS[AttrNoStrikethrough])
    end

    # DefaultForegroundColor appends the default foreground color style attribute to the style.
    #
    # Deprecated: use #foreground_color(nil) instead.
    def default_foreground_color : Style
      append_attr(ATTR_STRINGS[AttrDefaultForegroundColor])
    end

    # DefaultUnderlineColor appends the default underline color style attribute to the style.
    #
    # Deprecated: use #underline_color(nil) instead.
    def default_underline_color : Style
      append_attr(ATTR_STRINGS[AttrDefaultUnderlineColor])
    end
  end

  # SGR (Select Graphic Rendition) style attributes.
  # See: https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
  AttrReset                        =   0
  AttrBold                         =   1
  AttrFaint                        =   2
  AttrItalic                       =   3
  AttrUnderline                    =   4
  AttrBlink                        =   5
  AttrRapidBlink                   =   6
  AttrReverse                      =   7
  AttrConceal                      =   8
  AttrStrikethrough                =   9
  AttrNormalIntensity              =  22
  AttrNoItalic                     =  23
  AttrNoUnderline                  =  24
  AttrNoBlink                      =  25
  AttrNoReverse                    =  27
  AttrNoConceal                    =  28
  AttrNoStrikethrough              =  29
  AttrBlackForegroundColor         =  30
  AttrRedForegroundColor           =  31
  AttrGreenForegroundColor         =  32
  AttrYellowForegroundColor        =  33
  AttrBlueForegroundColor          =  34
  AttrMagentaForegroundColor       =  35
  AttrCyanForegroundColor          =  36
  AttrWhiteForegroundColor         =  37
  AttrExtendedForegroundColor      =  38
  AttrDefaultForegroundColor       =  39
  AttrBlackBackgroundColor         =  40
  AttrRedBackgroundColor           =  41
  AttrGreenBackgroundColor         =  42
  AttrYellowBackgroundColor        =  43
  AttrBlueBackgroundColor          =  44
  AttrMagentaBackgroundColor       =  45
  AttrCyanBackgroundColor          =  46
  AttrWhiteBackgroundColor         =  47
  AttrExtendedBackgroundColor      =  48
  AttrDefaultBackgroundColor       =  49
  AttrExtendedUnderlineColor       =  58
  AttrDefaultUnderlineColor        =  59
  AttrBrightBlackForegroundColor   =  90
  AttrBrightRedForegroundColor     =  91
  AttrBrightGreenForegroundColor   =  92
  AttrBrightYellowForegroundColor  =  93
  AttrBrightBlueForegroundColor    =  94
  AttrBrightMagentaForegroundColor =  95
  AttrBrightCyanForegroundColor    =  96
  AttrBrightWhiteForegroundColor   =  97
  AttrBrightBlackBackgroundColor   = 100
  AttrBrightRedBackgroundColor     = 101
  AttrBrightGreenBackgroundColor   = 102
  AttrBrightYellowBackgroundColor  = 103
  AttrBrightBlueBackgroundColor    = 104
  AttrBrightMagentaBackgroundColor = 105
  AttrBrightCyanBackgroundColor    = 106
  AttrBrightWhiteBackgroundColor   = 107
  AttrRGBColorIntroducer           =   2
  AttrExtendedColorIntroducer      =   5

  # Deprecated: use Attr* constants instead.
  ResetAttr                        = AttrReset
  BoldAttr                         = AttrBold
  FaintAttr                        = AttrFaint
  ItalicAttr                       = AttrItalic
  UnderlineAttr                    = AttrUnderline
  SlowBlinkAttr                    = AttrBlink
  RapidBlinkAttr                   = AttrRapidBlink
  ReverseAttr                      = AttrReverse
  ConcealAttr                      = AttrConceal
  StrikethroughAttr                = AttrStrikethrough
  NormalIntensityAttr              = AttrNormalIntensity
  NoItalicAttr                     = AttrNoItalic
  NoUnderlineAttr                  = AttrNoUnderline
  NoBlinkAttr                      = AttrNoBlink
  NoReverseAttr                    = AttrNoReverse
  NoConcealAttr                    = AttrNoConceal
  NoStrikethroughAttr              = AttrNoStrikethrough
  BlackForegroundColorAttr         = AttrBlackForegroundColor
  RedForegroundColorAttr           = AttrRedForegroundColor
  GreenForegroundColorAttr         = AttrGreenForegroundColor
  YellowForegroundColorAttr        = AttrYellowForegroundColor
  BlueForegroundColorAttr          = AttrBlueForegroundColor
  MagentaForegroundColorAttr       = AttrMagentaForegroundColor
  CyanForegroundColorAttr          = AttrCyanForegroundColor
  WhiteForegroundColorAttr         = AttrWhiteForegroundColor
  ExtendedForegroundColorAttr      = AttrExtendedForegroundColor
  DefaultForegroundColorAttr       = AttrDefaultForegroundColor
  BlackBackgroundColorAttr         = AttrBlackBackgroundColor
  RedBackgroundColorAttr           = AttrRedBackgroundColor
  GreenBackgroundColorAttr         = AttrGreenBackgroundColor
  YellowBackgroundColorAttr        = AttrYellowBackgroundColor
  BlueBackgroundColorAttr          = AttrBlueBackgroundColor
  MagentaBackgroundColorAttr       = AttrMagentaBackgroundColor
  CyanBackgroundColorAttr          = AttrCyanBackgroundColor
  WhiteBackgroundColorAttr         = AttrWhiteBackgroundColor
  ExtendedBackgroundColorAttr      = AttrExtendedBackgroundColor
  DefaultBackgroundColorAttr       = AttrDefaultBackgroundColor
  ExtendedUnderlineColorAttr       = AttrExtendedUnderlineColor
  DefaultUnderlineColorAttr        = AttrDefaultUnderlineColor
  BrightBlackForegroundColorAttr   = AttrBrightBlackForegroundColor
  BrightRedForegroundColorAttr     = AttrBrightRedForegroundColor
  BrightGreenForegroundColorAttr   = AttrBrightGreenForegroundColor
  BrightYellowForegroundColorAttr  = AttrBrightYellowForegroundColor
  BrightBlueForegroundColorAttr    = AttrBrightBlueForegroundColor
  BrightMagentaForegroundColorAttr = AttrBrightMagentaForegroundColor
  BrightCyanForegroundColorAttr    = AttrBrightCyanForegroundColor
  BrightWhiteForegroundColorAttr   = AttrBrightWhiteForegroundColor
  BrightBlackBackgroundColorAttr   = AttrBrightBlackBackgroundColor
  BrightRedBackgroundColorAttr     = AttrBrightRedBackgroundColor
  BrightGreenBackgroundColorAttr   = AttrBrightGreenBackgroundColor
  BrightYellowBackgroundColorAttr  = AttrBrightYellowBackgroundColor
  BrightBlueBackgroundColorAttr    = AttrBrightBlueBackgroundColor
  BrightMagentaBackgroundColorAttr = AttrBrightMagentaBackgroundColor
  BrightCyanBackgroundColorAttr    = AttrBrightCyanBackgroundColor
  BrightWhiteBackgroundColorAttr   = AttrBrightWhiteBackgroundColor
  RGBColorIntroducerAttr           = AttrRGBColorIntroducer
  ExtendedColorIntroducerAttr      = AttrExtendedColorIntroducer

  # Mapping from Attr to string representation
  private ATTR_STRINGS = {
    AttrReset                        => "0",
    AttrBold                         => "1",
    AttrFaint                        => "2",
    AttrItalic                       => "3",
    AttrUnderline                    => "4",
    AttrBlink                        => "5",
    AttrRapidBlink                   => "6",
    AttrReverse                      => "7",
    AttrConceal                      => "8",
    AttrStrikethrough                => "9",
    AttrNormalIntensity              => "22",
    AttrNoItalic                     => "23",
    AttrNoUnderline                  => "24",
    AttrNoBlink                      => "25",
    AttrNoReverse                    => "27",
    AttrNoConceal                    => "28",
    AttrNoStrikethrough              => "29",
    AttrBlackForegroundColor         => "30",
    AttrRedForegroundColor           => "31",
    AttrGreenForegroundColor         => "32",
    AttrYellowForegroundColor        => "33",
    AttrBlueForegroundColor          => "34",
    AttrMagentaForegroundColor       => "35",
    AttrCyanForegroundColor          => "36",
    AttrWhiteForegroundColor         => "37",
    AttrExtendedForegroundColor      => "38",
    AttrDefaultForegroundColor       => "39",
    AttrBlackBackgroundColor         => "40",
    AttrRedBackgroundColor           => "41",
    AttrGreenBackgroundColor         => "42",
    AttrYellowBackgroundColor        => "43",
    AttrBlueBackgroundColor          => "44",
    AttrMagentaBackgroundColor       => "45",
    AttrCyanBackgroundColor          => "46",
    AttrWhiteBackgroundColor         => "47",
    AttrExtendedBackgroundColor      => "48",
    AttrDefaultBackgroundColor       => "49",
    AttrExtendedUnderlineColor       => "58",
    AttrDefaultUnderlineColor        => "59",
    AttrBrightBlackForegroundColor   => "90",
    AttrBrightRedForegroundColor     => "91",
    AttrBrightGreenForegroundColor   => "92",
    AttrBrightYellowForegroundColor  => "93",
    AttrBrightBlueForegroundColor    => "94",
    AttrBrightMagentaForegroundColor => "95",
    AttrBrightCyanForegroundColor    => "96",
    AttrBrightWhiteForegroundColor   => "97",
    AttrBrightBlackBackgroundColor   => "100",
    AttrBrightRedBackgroundColor     => "101",
    AttrBrightGreenBackgroundColor   => "102",
    AttrBrightYellowBackgroundColor  => "103",
    AttrBrightBlueBackgroundColor    => "104",
    AttrBrightMagentaBackgroundColor => "105",
    AttrBrightCyanBackgroundColor    => "106",
    AttrBrightWhiteBackgroundColor   => "107",
  }
end

private def self.cmyk_to_rgb(c : Int32, m : Int32, y : Int32, k : Int32) : {UInt8, UInt8, UInt8}
  r = (255 - c) * (255 - k) // 255
  g = (255 - m) * (255 - k) // 255
  b = (255 - y) * (255 - k) // 255
  {r.to_u8, g.to_u8, b.to_u8}
end

# ReadStyleColor decodes a color from a slice of parameters. It returns the
# number of parameters read and the color. This function is used to read SGR
# color parameters following the ITU T.416 standard.
#
# It supports reading the following color types:
#   - 0: implementation defined
#   - 1: transparent
#   - 2: RGB direct color
#   - 3: CMY direct color
#   - 4: CMYK direct color
#   - 5: indexed color
#   - 6: RGBA direct color (WezTerm extension)
#
# The parameters can be separated by semicolons (;) or colons (:). Mixing
# separators is not allowed.
# ameba:disable Metrics/CyclomaticComplexity
def self.read_style_color(params : Params) : {Int32, PaletteColor?}
  return {0, nil} if params.size < 2

  _s, s_more, s_ok = params.param(0, 0)
  p, p_more, p_ok = params.param(1, 0)
  return {0, nil} unless s_ok && p_ok

  color_type = p
  n = 2

  get_param = ->(idx : Int32) { params.param(idx, 0)[0] }
  has_more = ->(idx : Int32) { params.param(idx, 0)[1] }

  # ameba:disable Metrics/CyclomaticComplexity
  paramsfn = -> {
    if s_more && p_more && params.size > 8 && has_more.call(2) && has_more.call(3) && has_more.call(4) && has_more.call(5) && has_more.call(6) && has_more.call(7)
      n += 7
      {get_param.call(3), get_param.call(4), get_param.call(5), get_param.call(6)}
    elsif s_more && p_more && params.size > 7 && has_more.call(2) && has_more.call(3) && has_more.call(4) && has_more.call(5) && has_more.call(6)
      n += 6
      {get_param.call(3), get_param.call(4), get_param.call(5), get_param.call(6)}
    elsif s_more && p_more && params.size > 6 && has_more.call(2) && has_more.call(3) && has_more.call(4) && has_more.call(5)
      n += 5
      {get_param.call(3), get_param.call(4), get_param.call(5), get_param.call(6)}
    elsif s_more && p_more && params.size > 5 && has_more.call(2) && has_more.call(3) && has_more.call(4) && !has_more.call(5)
      n += 4
      {get_param.call(3), get_param.call(4), get_param.call(5), -1}
    elsif s_more && p_more && p == 2 && has_more.call(2) && has_more.call(3) && !has_more.call(4)
      n += 3
      {get_param.call(2), get_param.call(3), get_param.call(4), -1}
    elsif !s_more && !p_more && p == 2 && !has_more.call(2) && !has_more.call(3) && !has_more.call(4)
      n += 3
      {get_param.call(2), get_param.call(3), get_param.call(4), -1}
    else
      {-1, -1, -1, -1}
    end
  }

  case color_type
  when 0 # implementation defined
    return {2, nil}
  when 1 # transparent
    return {2, Color.new(0_u8, 0_u8, 0_u8, 0_u8)}
  when 2 # RGB direct color
    return {0, nil} if params.size < 5
    r, g, b, _a = paramsfn.call
    return {0, nil} if r < 0 || g < 0 || b < 0
    return {n, Color.new(r.to_u8, g.to_u8, b.to_u8, 0xff_u8)}
  when 3 # CMY direct color
    return {0, nil} if params.size < 5
    c, m, y, _k = paramsfn.call
    return {0, nil} if c < 0 || m < 0 || y < 0
    r, g, b = cmyk_to_rgb(c, m, y, 0)
    return {n, Color.new(r, g, b, 0xff_u8)}
  when 4 # CMYK direct color
    return {0, nil} if params.size < 6
    c, m, y, k = paramsfn.call
    return {0, nil} if c < 0 || m < 0 || y < 0 || k < 0
    r, g, b = cmyk_to_rgb(c, m, y, k)
    return {n, Color.new(r, g, b, 0xff_u8)}
  when 5 # indexed color
    return {0, nil} if params.size < 3
    if (s_more && p_more && !has_more.call(2)) || (!s_more && !p_more && !has_more.call(2))
      return {3, ExtendedColor.new(get_param.call(2).to_u8)}
    end
    return {0, nil}
  when 6 # RGBA direct color
    return {0, nil} if params.size < 6
    r, g, b, a = paramsfn.call
    return {0, nil} if r < 0 || g < 0 || b < 0 || a < 0
    return {n, Color.new(r.to_u8, g.to_u8, b.to_u8, a.to_u8)}
  else
    return {0, nil}
  end
end
