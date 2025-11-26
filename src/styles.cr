# Text styling utilities for terminal applications
module Term2
  # Cursor provides escape sequence strings for cursor control and positioning.
  # These return strings (not printed directly) for use in view functions.
  #
  # Example:
  #   io << Cursor.move_to(5, 10) << "Hello"
  #   io << Cursor.home << S.bold | "Title"
  module Cursor
    # Move cursor to specific position (1-based row, col)
    def self.move_to(row : Int32, col : Int32) : String
      "\e[#{row};#{col}H"
    end

    # Shorthand for move_to
    def self.pos(row : Int32, col : Int32) : String
      move_to(row, col)
    end

    # Move cursor to home position (top-left)
    def self.home : String
      "\e[H"
    end

    # Move cursor up n lines
    def self.up(n : Int32 = 1) : String
      "\e[#{n}A"
    end

    # Move cursor down n lines
    def self.down(n : Int32 = 1) : String
      "\e[#{n}B"
    end

    # Move cursor right n columns
    def self.right(n : Int32 = 1) : String
      "\e[#{n}C"
    end

    # Move cursor left n columns
    def self.left(n : Int32 = 1) : String
      "\e[#{n}D"
    end

    # Save cursor position
    def self.save : String
      "\e[s"
    end

    # Restore cursor position
    def self.restore : String
      "\e[u"
    end

    # Hide cursor
    def self.hide : String
      "\e[?25l"
    end

    # Show cursor
    def self.show : String
      "\e[?25h"
    end

    # Clear from cursor to end of line
    def self.clear_line : String
      "\e[K"
    end

    # Clear entire line
    def self.clear_entire_line : String
      "\e[2K"
    end

    # Clear from cursor to end of screen
    def self.clear_to_end : String
      "\e[J"
    end

    # Clear entire screen
    def self.clear_screen : String
      "\e[2J"
    end

    # Clear screen and move to home
    def self.clear : String
      "\e[2J\e[H"
    end
  end

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
        bold: @bold || other.bold?,
        faint: @faint || other.faint?,
        italic: @italic || other.italic?,
        underline: @underline || other.underline?,
        blink: @blink || other.blink?,
        reverse: @reverse || other.reverse?,
        conceal: @conceal || other.conceal?,
        strike: @strike || other.strike?
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

  # Fluent style builder for composing multiple styles
  #
  # Example:
  #   S.bold.cyan.apply("Hello")
  #   S.red.on_white.underline.apply("World")
  #   S.fg(208).bold.apply("Orange")
  struct S
    @codes : Array(Int32)

    def initialize
      @codes = [] of Int32
    end

    def initialize(@codes : Array(Int32))
    end

    # Apply accumulated styles to text
    def apply(text : String) : String
      return text if @codes.empty?
      "\e[#{@codes.join(';')}m#{text}\e[0m"
    end

    # Shorthand for apply
    def |(text : String) : String
      apply(text)
    end

    # Text attributes
    def bold : S
      S.new(@codes + [1])
    end

    def faint : S
      S.new(@codes + [2])
    end

    def dim : S
      faint
    end

    def italic : S
      S.new(@codes + [3])
    end

    def underline : S
      S.new(@codes + [4])
    end

    def blink : S
      S.new(@codes + [5])
    end

    def reverse : S
      S.new(@codes + [7])
    end

    def hidden : S
      S.new(@codes + [8])
    end

    def strike : S
      S.new(@codes + [9])
    end

    # Standard foreground colors
    def black : S
      S.new(@codes + [30])
    end

    def red : S
      S.new(@codes + [31])
    end

    def green : S
      S.new(@codes + [32])
    end

    def yellow : S
      S.new(@codes + [33])
    end

    def blue : S
      S.new(@codes + [34])
    end

    def magenta : S
      S.new(@codes + [35])
    end

    def cyan : S
      S.new(@codes + [36])
    end

    def white : S
      S.new(@codes + [37])
    end

    def gray : S
      S.new(@codes + [90])
    end

    # Bright foreground colors
    def bright_red : S
      S.new(@codes + [91])
    end

    def bright_green : S
      S.new(@codes + [92])
    end

    def bright_yellow : S
      S.new(@codes + [93])
    end

    def bright_blue : S
      S.new(@codes + [94])
    end

    def bright_magenta : S
      S.new(@codes + [95])
    end

    def bright_cyan : S
      S.new(@codes + [96])
    end

    def bright_white : S
      S.new(@codes + [97])
    end

    # Background colors
    def on_black : S
      S.new(@codes + [40])
    end

    def on_red : S
      S.new(@codes + [41])
    end

    def on_green : S
      S.new(@codes + [42])
    end

    def on_yellow : S
      S.new(@codes + [43])
    end

    def on_blue : S
      S.new(@codes + [44])
    end

    def on_magenta : S
      S.new(@codes + [45])
    end

    def on_cyan : S
      S.new(@codes + [46])
    end

    def on_white : S
      S.new(@codes + [47])
    end

    # 256-color foreground
    def fg(color : Int32) : S
      S.new(@codes + [38, 5, color])
    end

    # 256-color background
    def bg(color : Int32) : S
      S.new(@codes + [48, 5, color])
    end

    # RGB foreground (true color)
    def fg(r : Int32, g : Int32, b : Int32) : S
      S.new(@codes + [38, 2, r, g, b])
    end

    # RGB background (true color)
    def bg(r : Int32, g : Int32, b : Int32) : S
      S.new(@codes + [48, 2, r, g, b])
    end

    # Class methods for starting chains
    {% for attr in [:bold, :faint, :dim, :italic, :underline, :blink, :reverse, :hidden, :strike] %}
      def self.{{attr.id}} : S
        S.new.{{attr.id}}
      end
    {% end %}

    {% for color in [:black, :red, :green, :yellow, :blue, :magenta, :cyan, :white, :gray] %}
      def self.{{color.id}} : S
        S.new.{{color.id}}
      end
    {% end %}

    {% for color in [:bright_red, :bright_green, :bright_yellow, :bright_blue, :bright_magenta, :bright_cyan, :bright_white] %}
      def self.{{color.id}} : S
        S.new.{{color.id}}
      end
    {% end %}

    {% for color in [:on_black, :on_red, :on_green, :on_yellow, :on_blue, :on_magenta, :on_cyan, :on_white] %}
      def self.{{color.id}} : S
        S.new.{{color.id}}
      end
    {% end %}

    def self.fg(color : Int32) : S
      S.new.fg(color)
    end

    def self.bg(color : Int32) : S
      S.new.bg(color)
    end

    def self.fg(r : Int32, g : Int32, b : Int32) : S
      S.new.fg(r, g, b)
    end

    def self.bg(r : Int32, g : Int32, b : Int32) : S
      S.new.bg(r, g, b)
    end
  end
end

# String extensions for simple single-style application
# For chained styles, use Term2::S builder instead
class String
  # Text attributes
  def bold : String
    "\e[1m#{self}\e[0m"
  end

  def faint : String
    "\e[2m#{self}\e[0m"
  end

  def dim : String
    faint
  end

  def italic : String
    "\e[3m#{self}\e[0m"
  end

  def underline : String
    "\e[4m#{self}\e[0m"
  end

  def blink : String
    "\e[5m#{self}\e[0m"
  end

  def reverse : String
    "\e[7m#{self}\e[0m"
  end

  def hidden : String
    "\e[8m#{self}\e[0m"
  end

  def strike : String
    "\e[9m#{self}\e[0m"
  end

  def strikethrough : String
    strike
  end

  # Standard foreground colors
  def black : String
    "\e[30m#{self}\e[0m"
  end

  def red : String
    "\e[31m#{self}\e[0m"
  end

  def green : String
    "\e[32m#{self}\e[0m"
  end

  def yellow : String
    "\e[33m#{self}\e[0m"
  end

  def blue : String
    "\e[34m#{self}\e[0m"
  end

  def magenta : String
    "\e[35m#{self}\e[0m"
  end

  def cyan : String
    "\e[36m#{self}\e[0m"
  end

  def white : String
    "\e[37m#{self}\e[0m"
  end

  def gray : String
    "\e[90m#{self}\e[0m"
  end

  # Bright foreground colors
  def bright_red : String
    "\e[91m#{self}\e[0m"
  end

  def bright_green : String
    "\e[92m#{self}\e[0m"
  end

  def bright_yellow : String
    "\e[93m#{self}\e[0m"
  end

  def bright_blue : String
    "\e[94m#{self}\e[0m"
  end

  def bright_magenta : String
    "\e[95m#{self}\e[0m"
  end

  def bright_cyan : String
    "\e[96m#{self}\e[0m"
  end

  def bright_white : String
    "\e[97m#{self}\e[0m"
  end

  # Background colors
  def on_black : String
    "\e[40m#{self}\e[0m"
  end

  def on_red : String
    "\e[41m#{self}\e[0m"
  end

  def on_green : String
    "\e[42m#{self}\e[0m"
  end

  def on_yellow : String
    "\e[43m#{self}\e[0m"
  end

  def on_blue : String
    "\e[44m#{self}\e[0m"
  end

  def on_magenta : String
    "\e[45m#{self}\e[0m"
  end

  def on_cyan : String
    "\e[46m#{self}\e[0m"
  end

  def on_white : String
    "\e[47m#{self}\e[0m"
  end

  # 256-color support
  def fg(color : Int32) : String
    "\e[38;5;#{color}m#{self}\e[0m"
  end

  def bg(color : Int32) : String
    "\e[48;5;#{color}m#{self}\e[0m"
  end

  # RGB color support (true color)
  def fg(r : Int32, g : Int32, b : Int32) : String
    "\e[38;2;#{r};#{g};#{b}m#{self}\e[0m"
  end

  def bg(r : Int32, g : Int32, b : Int32) : String
    "\e[48;2;#{r};#{g};#{b}m#{self}\e[0m"
  end

  # Styled - wraps text with style codes that compose properly
  def styled(*codes : Int32) : String
    "\e[#{codes.join(';')}m#{self}\e[0m"
  end
end
