# View layout utilities for terminal applications
module Term2
  # View represents a rectangular area in the terminal.
  #
  # Views are used for layout calculations and can be split, padded,
  # centered, and nested to create complex UI arrangements.
  #
  # ```
  # # Create a full-screen view
  # screen = Term2::View.new(0, 0, 80, 24)
  #
  # # Add margins
  # content = screen.margin(top: 1, bottom: 1, left: 2, right: 2)
  #
  # # Split horizontally
  # left, right = content.split_horizontal(0.3)
  #
  # # Create a centered dialog
  # dialog = screen.center(40, 10)
  # ```
  struct View
    # X position (column, 0-based)
    getter x : Int32
    # Y position (row, 0-based)
    getter y : Int32
    # Width in columns
    getter width : Int32
    # Height in rows
    getter height : Int32

    def initialize(@x : Int32, @y : Int32, @width : Int32, @height : Int32)
    end

    # Check if a point is within this view.
    def contains?(point_x : Int32, point_y : Int32) : Bool
      point_x >= @x && point_x < @x + @width &&
        point_y >= @y && point_y < @y + @height
    end

    # Get the right edge (rightmost column).
    def right : Int32
      @x + @width - 1
    end

    # Get the bottom edge (bottom row).
    def bottom : Int32
      @y + @height - 1
    end

    # Create a subview within this view.
    #
    # Coordinates are relative to this view's origin.
    def subview(x : Int32, y : Int32, width : Int32, height : Int32) : View
      View.new(@x + x, @y + y, width.clamp(0, @width - x), height.clamp(0, @height - y))
    end

    # Create a subview with margins from each edge.
    def margin(top : Int32 = 0, right : Int32 = 0, bottom : Int32 = 0, left : Int32 = 0) : View
      View.new(
        @x + left,
        @y + top,
        (@width - left - right).clamp(0, @width),
        (@height - top - bottom).clamp(0, @height)
      )
    end

    # Create a centered subview of the given dimensions.
    def center(width : Int32, height : Int32) : View
      x = @x + (@width - width) // 2
      y = @y + (@height - height) // 2
      View.new(x, y, width.clamp(0, @width), height.clamp(0, @height))
    end

    # Split the view horizontally into two parts.
    #
    # Returns {left, right} views.
    def split_horizontal(ratio : Float64 = 0.5) : {View, View}
      split_point = (@width * ratio).round.to_i
      left = View.new(@x, @y, split_point, @height)
      right = View.new(@x + split_point, @y, @width - split_point, @height)
      {left, right}
    end

    # Split the view vertically into two parts.
    #
    # Returns {top, bottom} views.
    def split_vertical(ratio : Float64 = 0.5) : {View, View}
      split_point = (@height * ratio).round.to_i
      top = View.new(@x, @y, @width, split_point)
      bottom = View.new(@x, @y + split_point, @width, @height - split_point)
      {top, bottom}
    end

    # Create a view with uniform padding on all sides.
    def padding(all : Int32) : View
      margin(top: all, right: all, bottom: all, left: all)
    end

    # Create a view with separate horizontal and vertical padding.
    def padding(horizontal : Int32, vertical : Int32) : View
      margin(top: vertical, right: horizontal, bottom: vertical, left: horizontal)
    end

    # Create a view with custom padding on each side.
    def padding(top : Int32 = 0, right : Int32 = 0, bottom : Int32 = 0, left : Int32 = 0) : View
      margin(top: top, right: right, bottom: bottom, left: left)
    end
  end

  # Layout utilities for arranging views.
  #
  # Provides helpers for common layout patterns like grids and flex layouts.
  module Layout
    # Arrange views in a horizontal row
    def self.horizontal(*views : View) : Array(View)
      views.to_a
    end

    # Arrange views in a vertical column
    def self.vertical(*views : View) : Array(View)
      views.to_a
    end

    # Create a grid layout
    def self.grid(container : View, rows : Int32, cols : Int32) : Array(View)
      cell_width = container.width // cols
      cell_height = container.height // rows

      views = [] of View

      rows.times do |row|
        cols.times do |col|
          x = container.x + col * cell_width
          y = container.y + row * cell_height
          width = (col == cols - 1) ? container.width - col * cell_width : cell_width
          height = (row == rows - 1) ? container.height - row * cell_height : cell_height
          views << View.new(x, y, width, height)
        end
      end

      views
    end

    # Create a flexbox-like layout
    def self.flex(container : View, direction : Symbol = :horizontal, spacing : Int32 = 0) : Array(View)
      # Simple flex layout - for more complex layouts, use a dedicated layout engine
      case direction
      when :horizontal
        available_width = container.width - (spacing * (container.width - 1))
        item_width = available_width // container.width

        container.width.times.map do |i|
          View.new(
            container.x + i * (item_width + spacing),
            container.y,
            item_width,
            container.height
          )
        end.to_a
      when :vertical
        available_height = container.height - (spacing * (container.height - 1))
        item_height = available_height // container.height

        container.height.times.map do |i|
          View.new(
            container.x,
            container.y + i * (item_height + spacing),
            container.width,
            item_height
          )
        end.to_a
      else
        [] of View
      end
    end
  end

  # Rendering utilities for views
  module Render
    # Clear a view area
    def self.clear(view : View)
      # Move to top-left of view
      print "\e[#{view.y + 1};#{view.x + 1}H"

      # Clear each row
      view.height.times do |row|
        print "\e[#{view.y + row + 1};#{view.x + 1}H"
        print " " * view.width
      end

      # Move back to top-left
      print "\e[#{view.y + 1};#{view.x + 1}H"
    end

    # Render text within a view
    def self.text(view : View, text : String, x : Int32 = 0, y : Int32 = 0,
                  wrap : Bool = false, align : Symbol = :left)
      return if x >= view.width || y >= view.height

      lines = if wrap
                wrap_text(text, view.width - x)
              else
                text.lines
              end

      lines.each_with_index do |line, line_index|
        render_y = view.y + y + line_index
        break if render_y >= view.y + view.height

        # Handle alignment
        rendered_line = case align
                        when :center
                          line.center(view.width - x)
                        when :right
                          line.rjust(view.width - x)
                        else
                          line.ljust(view.width - x)
                        end

        # Move to position and render
        print "\e[#{render_y + 1};#{view.x + x + 1}H"
        print rendered_line[0, view.width - x]
      end
    end

    # Render a border around a view
    def self.border(view : View, style : Symbol = :single)
      border_chars = case style
                     when :single
                       {'┌', '┐', '└', '┘', '─', '│'}
                     when :double
                       {'╔', '╗', '╚', '╝', '═', '║'}
                     when :rounded
                       {'╭', '╮', '╰', '╯', '─', '│'}
                     else
                       {'+', '+', '+', '+', '-', '|'}
                     end

      top_left, top_right, bottom_left, bottom_right, horizontal, vertical = border_chars

      # Top border
      print "\e[#{view.y};#{view.x}H"
      print top_left
      print horizontal * (view.width - 2)
      print top_right

      # Bottom border
      print "\e[#{view.y + view.height - 1};#{view.x}H"
      print bottom_left
      print horizontal * (view.width - 2)
      print bottom_right

      # Side borders
      (view.height - 2).times do |row|
        print "\e[#{view.y + row + 1};#{view.x}H"
        print vertical
        print "\e[#{view.y + row + 1};#{view.x + view.width - 1}H"
        print vertical
      end
    end

    # Fill a view with a character
    def self.fill(view : View, char : Char = ' ')
      view.height.times do |row|
        print "\e[#{view.y + row + 1};#{view.x + 1}H"
        print char.to_s * view.width
      end
    end

    private def self.wrap_text(text : String, width : Int32) : Array(String)
      lines = [] of String
      current_line = ""

      text.split(' ').each do |word|
        if current_line.empty?
          current_line = word
        elsif current_line.size + word.size + 1 <= width
          current_line += " " + word
        else
          lines << current_line
          current_line = word
        end
      end

      lines << current_line unless current_line.empty?
      lines
    end
  end
end
