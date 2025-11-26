# Text styling utilities for terminal applications
module Term2
  # Style represents text styling attributes
  struct Style
    getter foreground : Color?
    getter background : Color?
    getter? bold : Bool
    getter? faint : Bool
    getter? italic : Bool
    getter? underline : Bool
    getter? blink : Bool
    getter? reverse : Bool
    getter? conceal : Bool
    getter? strike : Bool

    def initialize(@foreground : Color? = nil, @background : Color? = nil,
                   @bold : Bool = false, @faint : Bool = false, @italic : Bool = false,
                   @underline : Bool = false, @blink : Bool = false, @reverse : Bool = false,
                   @conceal : Bool = false, @strike : Bool = false)
    end

    # Apply this style to text
    def apply(text : String) : String
      return text unless any_style?

      String.build do |str|
        str << escape_sequence
        str << text
        str << "\e[0m"
      end
    end

    # Merge with another style
    def merge(other : Style) : Style
      Style.new(
        foreground: other.foreground || @foreground,
        background: other.background || @background,
        bold: @bold || other.bold,
        faint: @faint || other.faint,
        italic: @italic || other.italic,
        underline: @underline || other.underline,
        blink: @blink || other.blink,
        reverse: @reverse || other.reverse,
        conceal: @conceal || other.conceal,
        strike: @strike || other.strike
      )
    end

    # Check if any style is set
    private def any_style? : Bool
      !@foreground.nil? || !@background.nil? || @bold || @faint || @italic ||
        @underline || @blink || @reverse || @conceal || @strike
    end

    # Generate escape sequence for this style
    private def escape_sequence : String
      codes = [] of Int32

      # Reset all attributes first
      codes << 0

      # Foreground color
      if fg = @foreground
        codes.concat(fg.foreground_codes)
      end

      # Background color
      if bg = @background
        codes.concat(bg.background_codes)
      end

      # Text attributes
      codes << 1 if @bold
      codes << 2 if @faint
      codes << 3 if @italic
      codes << 4 if @underline
      codes << 5 if @blink
      codes << 7 if @reverse
      codes << 8 if @conceal
      codes << 9 if @strike

      "\e[#{codes.join(';')}m"
    end

    # Predefined styles
    def self.bold : Style
      Style.new(bold: true)
    end

    def self.italic : Style
      Style.new(italic: true)
    end

    def self.underline : Style
      Style.new(underline: true)
    end

    def self.reverse : Style
      Style.new(reverse: true)
    end

    def self.red : Style
      Style.new(foreground: Color::RED)
    end

    def self.green : Style
      Style.new(foreground: Color::GREEN)
    end

    def self.blue : Style
      Style.new(foreground: Color::BLUE)
    end

    def self.yellow : Style
      Style.new(foreground: Color::YELLOW)
    end

    def self.magenta : Style
      Style.new(foreground: Color::MAGENTA)
    end

    def self.cyan : Style
      Style.new(foreground: Color::CYAN)
    end

    def self.white : Style
      Style.new(foreground: Color::WHITE)
    end

    def self.black : Style
      Style.new(foreground: Color::BLACK)
    end
  end

  # Color represents terminal colors
  struct Color
    enum Type
      Named
      Indexed
      RGB
    end

    getter type : Type
    getter value : Int32 | {Int32, Int32, Int32}

    # Named colors
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

    def initialize(@type : Type, @value : Int32 | {Int32, Int32, Int32})
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
        [30 + @value.as(Int32)]
      when Type::Indexed
        [38, 5, @value.as(Int32)]
      when Type::RGB
        r, g, b = @value.as({Int32, Int32, Int32})
        [38, 2, r, g, b]
      else
        [] of Int32
      end
    end

    # Get background escape codes
    def background_codes : Array(Int32)
      case @type
      when Type::Named
        [40 + @value.as(Int32)]
      when Type::Indexed
        [48, 5, @value.as(Int32)]
      when Type::RGB
        r, g, b = @value.as({Int32, Int32, Int32})
        [48, 2, r, g, b]
      else
        [] of Int32
      end
    end
  end

  # Text styling utilities
  module Text
    # Apply a style to text
    def self.style(text : String, style : Style) : String
      style.apply(text)
    end

    # Apply multiple styles to text
    def self.style(text : String, *styles : Style) : String
      combined = styles.reduce(Style.new) { |acc, style| acc.merge(style) }
      combined.apply(text)
    end

    # Convenience methods for common styles
    def self.bold(text : String) : String
      Style.bold.apply(text)
    end

    def self.italic(text : String) : String
      Style.italic.apply(text)
    end

    def self.underline(text : String) : String
      Style.underline.apply(text)
    end

    def self.red(text : String) : String
      Style.red.apply(text)
    end

    def self.green(text : String) : String
      Style.green.apply(text)
    end

    def self.blue(text : String) : String
      Style.blue.apply(text)
    end

    def self.yellow(text : String) : String
      Style.yellow.apply(text)
    end

    def self.magenta(text : String) : String
      Style.magenta.apply(text)
    end

    def self.cyan(text : String) : String
      Style.cyan.apply(text)
    end

    def self.white(text : String) : String
      Style.white.apply(text)
    end

    def self.black(text : String) : String
      Style.black.apply(text)
    end
  end
end
