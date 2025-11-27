require "./styles"

module Term2
  module LipGloss
    # Global setting for adaptive colors
    class_property? has_dark_background : Bool = true

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
    end

    enum Position
      Left
      Center
      Right
      Top
      Bottom
    end

    struct Border
      property top : String
      property bottom : String
      property left : String
      property right : String
      property top_left : String
      property top_right : String
      property bottom_left : String
      property bottom_right : String
      property middle_left : String
      property middle_right : String
      property middle : String
      property middle_top : String
      property middle_bottom : String

      def initialize(@top, @bottom, @left, @right, @top_left, @top_right, @bottom_left, @bottom_right,
                     @middle_left, @middle_right, @middle, @middle_top, @middle_bottom)
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

      def self.none
        nil
      end
    end

    struct AdaptiveColor
      getter light : Color
      getter dark : Color

      def initialize(@light, @dark)
      end
    end

    # Style is the core styling primitive for Lip Gloss
    class Style
      def copy : self
        new_style = Style.new
        new_style.foreground_color = @foreground_color
        new_style.background_color = @background_color
        new_style.bold = @bold
        new_style.italic = @italic
        new_style.underline = @underline
        new_style.strikethrough = @strikethrough
        new_style.reverse = @reverse
        new_style.blink = @blink
        new_style.faint = @faint
        new_style.transform_fn = @transform_fn

        new_style.padding = @padding # Struct copy
        new_style.margin = @margin   # Struct copy
        new_style.width_value = @width_value
        new_style.height_value = @height_value
        new_style.align_value = @align_value
        new_style.vertical_align_value = @vertical_align_value

        new_style.border_style = @border_style # Struct copy
        new_style.border_foreground_color = @border_foreground_color
        new_style.border_background_color = @border_background_color
        new_style.border_top = @border_top
        new_style.border_bottom = @border_bottom
        new_style.border_left = @border_left
        new_style.border_right = @border_right

        new_style
      end

      # Text Attributes
      property foreground_color : Color | AdaptiveColor | Nil
      property background_color : Color | AdaptiveColor | Nil
      property? bold : Bool = false
      property? italic : Bool = false
      property? underline : Bool = false
      property? strikethrough : Bool = false
      property? reverse : Bool = false
      property? blink : Bool = false
      property? faint : Bool = false
      property transform_fn : Proc(String, String)?

      # Layout
      property padding : Edges = Edges.new
      property margin : Edges = Edges.new
      property width_value : Int32?
      property height_value : Int32?
      property align_value : Position = Position::Left
      property vertical_align_value : Position = Position::Top

      # Border
      property border_style : Border?
      property border_foreground_color : Color | AdaptiveColor | Nil
      property border_background_color : Color | AdaptiveColor | Nil
      property? border_top : Bool = true
      property? border_bottom : Bool = true
      property? border_left : Bool = true
      property? border_right : Bool = true

      def initialize
      end

      # Fluent API - Colors
      def foreground(color : Color | AdaptiveColor) : self
        @foreground_color = color
        self
      end

      def foreground(sym : Symbol) : self
        foreground(color_from_symbol(sym))
      end

      def background(color : Color | AdaptiveColor) : self
        @background_color = color
        self
      end

      def background(sym : Symbol) : self
        background(color_from_symbol(sym))
      end

      # Fluent API - Border
      def border(style : Border) : self
        @border_style = style
        self
      end

      def border_foreground(color : Color | AdaptiveColor) : self
        @border_foreground_color = color
        self
      end

      def border_foreground(sym : Symbol) : self
        border_foreground(color_from_symbol(sym))
      end

      def border_background(color : Color | AdaptiveColor) : self
        @border_background_color = color
        self
      end

      def border_background(sym : Symbol) : self
        border_background(color_from_symbol(sym))
      end

      def border_top(val : Bool) : self
        @border_top = val
        self
      end

      def border_bottom(val : Bool) : self
        @border_bottom = val
        self
      end

      def border_left(val : Bool) : self
        @border_left = val
        self
      end

      def border_right(val : Bool) : self
        @border_right = val
        self
      end

      # Fluent API - Attributes
      def bold(val : Bool = true) : self
        @bold = val
        self
      end

      def italic(val : Bool = true) : self
        @italic = val
        self
      end

      def underline(val : Bool = true) : self
        @underline = val
        self
      end

      def strikethrough(val : Bool = true) : self
        @strikethrough = val
        self
      end

      def reverse(val : Bool = true) : self
        @reverse = val
        self
      end

      def blink(val : Bool = true) : self
        @blink = val
        self
      end

      def faint(val : Bool = true) : self
        @faint = val
        self
      end

      # Fluent API - Transformations
      def transform(fn : Proc(String, String)) : self
        @transform_fn = fn
        self
      end

      def upper_case : self
        @transform_fn = ->(s : String) { s.upcase }
        self
      end

      def lower_case : self
        @transform_fn = ->(s : String) { s.downcase }
        self
      end

      # Fluent API - Layout
      def padding(top : Int32, right : Int32, bottom : Int32, left : Int32) : self
        @padding = Edges.new(top, right, bottom, left)
        self
      end

      def padding(vertical : Int32, horizontal : Int32) : self
        @padding = Edges.symmetric(vertical, horizontal)
        self
      end

      def padding(all : Int32) : self
        @padding = Edges.all(all)
        self
      end

      def margin(top : Int32, right : Int32, bottom : Int32, left : Int32) : self
        @margin = Edges.new(top, right, bottom, left)
        self
      end

      def margin(vertical : Int32, horizontal : Int32) : self
        @margin = Edges.symmetric(vertical, horizontal)
        self
      end

      def margin(all : Int32) : self
        @margin = Edges.all(all)
        self
      end

      def width(w : Int32) : self
        @width_value = w
        self
      end

      def height(h : Int32) : self
        @height_value = h
        self
      end

      def align(pos : Position) : self
        @align_value = pos
        self
      end

      def vertical_align(pos : Position) : self
        @vertical_align_value = pos
        self
      end

      # Utilities
      def copy : Style
        dup
      end

      def unset_foreground : self
        @foreground_color = nil
        self
      end

      def unset_background : self
        @background_color = nil
        self
      end

      def unset_border : self
        @border_style = nil
        self
      end

      def unset_padding : self
        @padding = Edges.new
        self
      end

      def unset_margin : self
        @margin = Edges.new
        self
      end

      def unset_width : self
        @width_value = nil
        self
      end

      def unset_height : self
        @height_value = nil
        self
      end

      def unset_align : self
        @align_value = Position::Left
        self
      end

      # Rendering
      def render(text : String) : String
        if fn = @transform_fn
          text = fn.call(text)
        end

        lines = text.split('\n')

        # 1. Calculate dimensions and align content
        if w = @width_value
          content_width = w
          # TODO: Handle wrapping if text is wider than width
        end

        # 2. Apply alignment and fill to width
        aligned_lines = lines.map do |line|
          w = Term2::Text.width(line)
          if w < content_width
            padding = content_width - w
            case @align_value
            when Position::Left
              line + (" " * padding)
            when Position::Right
              (" " * padding) + line
            when Position::Center
              left = padding // 2
              right = padding - left
              (" " * left) + line + (" " * right)
            else
              line + (" " * padding)
            end
          else
            line
          end
        end

        # 3. Apply Padding
        padded_lines = apply_padding(aligned_lines, content_width)

        # 4. Apply Text Style (Color, Bold, etc.)
        # We apply style to each line individually to ensure background covers the full width
        styled_lines = padded_lines.map do |line|
          apply_text_style(line)
        end

        # 5. Apply Border
        bordered_lines = apply_border(styled_lines)

        # 6. Apply Margin
        margined_lines = apply_margin(bordered_lines)

        margined_lines.join('\n')
      end

      def horizontal_frame_size : Int32
        h_margin = @margin.left + @margin.right
        h_padding = @padding.left + @padding.right
        h_border = (@border_left ? 1 : 0) + (@border_right ? 1 : 0)
        h_margin + h_padding + h_border
      end

      def vertical_frame_size : Int32
        v_margin = @margin.top + @margin.bottom
        v_padding = @padding.top + @padding.bottom
        v_border = (@border_top ? 1 : 0) + (@border_bottom ? 1 : 0)
        v_margin + v_padding + v_border
      end

      private def apply_border(lines : Array(String)) : Array(String)
        return lines unless border = @border_style

        # Calculate width of the block (assuming all lines are same width after padding)
        width = lines.empty? ? 0 : Term2::Text.width(lines.first)

        # Create border style
        b_style = Term2::Style.new(
          foreground: resolve_color(@border_foreground_color),
          background: resolve_color(@border_background_color)
        )

        top_s = b_style.apply(border.top * width)
        bottom_s = b_style.apply(border.bottom * width)
        left_s = b_style.apply(border.left)
        right_s = b_style.apply(border.right)

        top_left_s = b_style.apply(border.top_left)
        top_right_s = b_style.apply(border.top_right)
        bottom_left_s = b_style.apply(border.bottom_left)
        bottom_right_s = b_style.apply(border.bottom_right)

        result = [] of String

        if @border_top
          left_corner = @border_left ? top_left_s : ""
          right_corner = @border_right ? top_right_s : ""
          result << "#{left_corner}#{top_s}#{right_corner}"
        end

        lines.each do |line|
          l = @border_left ? left_s : ""
          r = @border_right ? right_s : ""
          result << "#{l}#{line}#{r}"
        end

        if @border_bottom
          left_corner = @border_left ? bottom_left_s : ""
          right_corner = @border_right ? bottom_right_s : ""
          result << "#{left_corner}#{bottom_s}#{right_corner}"
        end

        result
      end

      private def apply_padding(lines : Array(String), content_width : Int32) : Array(String)
        top = @padding.top
        bottom = @padding.bottom
        left = @padding.left
        right = @padding.right

        return lines if top == 0 && bottom == 0 && left == 0 && right == 0

        left_str = " " * left
        right_str = " " * right

        # Apply horizontal padding
        horizontally_padded = lines.map { |_| left_str + l + right_str }

        # Apply vertical padding
        full_width = content_width + left + right
        empty_line = " " * full_width

        result = [] of String
        top.times { result << empty_line }
        result.concat(horizontally_padded)
        bottom.times { result << empty_line }

        result
      end

      private def apply_margin(lines : Array(String)) : Array(String)
        top = @margin.top
        bottom = @margin.bottom
        left = @margin.left
        right = @margin.right

        return lines if top == 0 && bottom == 0 && left == 0 && right == 0

        left_str = " " * left

        # Apply horizontal margin (left only, right is implicit)
        horizontally_margined = lines.map { |_| left_str + l }

        # Apply vertical margin
        # For margin, we just add empty lines (no background color)
        result = [] of String
        top.times { result << "" }
        result.concat(horizontally_margined)
        bottom.times { result << "" }

        result
      end

      private def color_from_symbol(sym : Symbol) : Color
        case sym
        when :black               then Color::BLACK
        when :red                 then Color::RED
        when :green               then Color::GREEN
        when :yellow              then Color::YELLOW
        when :blue                then Color::BLUE
        when :magenta             then Color::MAGENTA
        when :cyan                then Color::CYAN
        when :white               then Color::WHITE
        when :bright_black, :gray then Color::BRIGHT_BLACK
        when :bright_red          then Color::BRIGHT_RED
        when :bright_green        then Color::BRIGHT_GREEN
        when :bright_yellow       then Color::BRIGHT_YELLOW
        when :bright_blue         then Color::BRIGHT_BLUE
        when :bright_magenta      then Color::BRIGHT_MAGENTA
        when :bright_cyan         then Color::BRIGHT_CYAN
        when :bright_white        then Color::BRIGHT_WHITE
        else
          # Fallback or error? For now, let's default to white but maybe logging would be good.
          # Since this is a UI library, crashing might be too harsh, but silent failure is also bad.
          # Let's assume standard colors.
          Color::WHITE
        end
      end

      private def resolve_color(color : Color | AdaptiveColor | Nil) : Color?
        case color
        when Color
          color
        when AdaptiveColor
          LipGloss.has_dark_background? ? color.dark : color.light
        end
      end

      private def apply_text_style(text : String) : String
        # Use existing Term2::Style logic or reimplement
        style = Term2::Style.new(
          foreground: resolve_color(@foreground_color),
          background: resolve_color(@background_color),
          bold: @bold,
          faint: @faint,
          italic: @italic,
          underline: @underline,
          blink: @blink,
          reverse: @reverse,
          strike: @strikethrough
        )
        style.apply(text)
      end
    end

    # Layout Utilities
    def self.join_horizontal(pos : Position, *blocks : String) : String
      join_horizontal(pos, blocks.to_a)
    end

    def self.join_horizontal(pos : Position, blocks : Array(String)) : String
      return "" if blocks.empty?

      # Split all blocks into lines
      block_lines = blocks.map(&.split('\n'))

      # Calculate max width for EACH block
      block_widths = block_lines.map do |lines|
        lines.empty? ? 0 : lines.max_of { |_| Term2::Text.width(l) }
      end

      # Find max height
      max_height = block_lines.max_of(&.size)

      # Pad each block to max_height AND pad lines to block width
      padded_blocks = block_lines.map_with_index do |lines, i|
        height = lines.size
        diff = max_height - height
        width = block_widths[i]
        empty_line = " " * width

        # Vertical padding (add empty lines)
        lines_with_v_pad = case pos
                           when Position::Top
                             lines + Array.new(diff, empty_line)
                           when Position::Bottom
                             Array.new(diff, empty_line) + lines
                           when Position::Center
                             top = diff // 2
                             bottom = diff - top
                             Array.new(top, empty_line) + lines + Array.new(bottom, empty_line)
                           else # Default to Top
                             lines + Array.new(diff, empty_line)
                           end

        # Horizontal padding (ensure all lines are 'width' long)
        lines_with_v_pad.map do |line|
          w = Term2::Text.width(line)
          if w < width
            line + (" " * (width - w))
          else
            line
          end
        end
      end

      # Join lines horizontally
      result = [] of String
      max_height.times do |i|
        line_parts = padded_blocks.map do |lines|
          lines[i]? || "" # Should be padded, but safe navigation
        end
        result << line_parts.join
      end

      result.join('\n')
    end

    def self.join_vertical(pos : Position, *blocks : String) : String
      join_vertical(pos, blocks.to_a)
    end

    def self.join_vertical(pos : Position, blocks : Array(String)) : String
      return "" if blocks.empty?

      # Find max width (considering multi-line blocks)
      max_width = blocks.max_of do |_|
        lines = b.split('\n')
        lines.empty? ? 0 : lines.max_of { |line| Term2::Text.width(line) }
      end

      # Align each block
      aligned_blocks = blocks.map do |_|
        lines = block.split('\n')
        lines.map do |line|
          w = Term2::Text.width(line)
          diff = max_width - w

          case pos
          when Position::Left
            line + (" " * diff)
          when Position::Right
            (" " * diff) + line
          when Position::Center
            left = diff // 2
            right = diff - left
            (" " * left) + line + (" " * right)
          else # Default to Left
            line + (" " * diff)
          end
        end.join('\n')
      end

      aligned_blocks.join('\n')
    end

    def self.place(width : Int32, height : Int32, h_pos : Position, v_pos : Position, content : String) : String
      lines = content.split('\n')
      content_height = lines.size
      # Handle empty content
      if content.empty?
        lines = [] of String
      else
      end

      # Vertical Placement
      gap_y = height - content_height
      top_pad = 0
      bottom_pad = 0

      if gap_y > 0
        case v_pos
        when Position::Top
          bottom_pad = gap_y
        when Position::Bottom
          top_pad = gap_y
        when Position::Center
          top_pad = gap_y // 2
          bottom_pad = gap_y - top_pad
        else # Default Top
          bottom_pad = gap_y
        end
      end

      result = [] of String

      # Top padding
      top_pad.times { result << " " * width }

      # Content
      lines.each do |line|
        line_width = Term2::Text.width(line)
        gap_x = width - line_width

        if gap_x > 0
          case h_pos
          when Position::Left
            result << line + (" " * gap_x)
          when Position::Right
            result << (" " * gap_x) + line
          when Position::Center
            left = gap_x // 2
            right = gap_x - left
            result << (" " * left) + line + (" " * right)
          else # Default Left
            result << line + (" " * gap_x)
          end
        else
          # If content is wider, we currently don't crop (TODO: Implement ANSI-aware truncate)
          result << line
        end
      end

      # Bottom padding
      bottom_pad.times { result << " " * width }

      # Crop if taller (naive line cropping)
      if result.size > height
        result = result[0, height]
      end

      result.join('\n')
    end

    def self.place_horizontal(width : Int32, pos : Position, content : String) : String
      lines = content.split('\n')
      height = lines.size
      place(width, height, pos, Position::Top, content)
    end

    def self.place_vertical(height : Int32, pos : Position, content : String) : String
      lines = content.split('\n')
      width = lines.empty? ? 0 : lines.max_of { |_| Term2::Text.width(l) }
      place(width, height, Position::Left, pos, content)
    end

    def self.width(str : String) : Int32
      return 0 if str.empty?
      str.split('\n').max_of { |line| Term2::Text.width(line) }
    end

    def self.height(str : String) : Int32
      str.split('\n').size
    end
  end
end

require "./lipgloss/table"
require "./lipgloss/list"
require "./lipgloss/tree"
