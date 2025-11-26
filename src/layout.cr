require "./term2"
require "./view"

module Term2
  module Layout
    abstract class Node
      property width : Int32 = 0
      property height : Int32 = 0
      property flex : Int32 = 0

      # Measure the node given constraints
      abstract def measure(max_width : Int32, max_height : Int32)

      # Render the node at the given absolute position
      abstract def render(io : IO, x : Int32, y : Int32)
    end

    class Text < Node
      def initialize(@content : String)
      end

      def measure(max_width : Int32, max_height : Int32)
        lines = @content.split("\n")
        @width = lines.max_of? { |line| Term2::Text.width(line) } || 0
        @height = lines.size
      end

      def render(io : IO, x : Int32, y : Int32)
        lines = @content.split("\n")
        lines.each_with_index do |line, i|
          io << Cursor.move_to(y + i + 1, x + 1)
          io << line
        end
      end
    end

    class VStack < Node
      @children = [] of Node

      def add(node : Node)
        @children << node
      end

      def measure(max_width : Int32, max_height : Int32)
        # First pass: measure non-flex children
        used_height = 0
        flex_total = 0
        max_child_width = 0

        @children.each do |child|
          if child.flex > 0
            flex_total += child.flex
          else
            child.measure(max_width, max_height - used_height)
            used_height += child.height
            max_child_width = {max_child_width, child.width}.max
          end
        end

        # Second pass: measure flex children
        if flex_total > 0
          remaining_height = (max_height - used_height).clamp(0, max_height)
          unit_height = remaining_height // flex_total

          @children.each do |child|
            if child.flex > 0
              # Give proportional height
              h = (child.flex * unit_height)
              # Add remainder to last flex child? Simplified for now.
              child.measure(max_width, h)
              used_height += child.height
              max_child_width = {max_child_width, child.width}.max
            end
          end
        end

        @width = max_child_width
        @height = used_height
      end

      def render(io : IO, x : Int32, y : Int32)
        current_y = y
        @children.each do |child|
          child.render(io, x, current_y)
          current_y += child.height
        end
      end
    end

    class HStack < Node
      @children = [] of Node
      @gap : Int32

      def initialize(@gap : Int32 = 0)
      end

      def add(node : Node)
        @children << node
      end

      def measure(max_width : Int32, max_height : Int32)
        # First pass: measure non-flex children
        used_width = 0
        flex_total = 0
        max_child_height = 0

        # Account for gaps
        total_gaps = (@children.size - 1).clamp(0, @children.size) * @gap
        available_width = max_width - total_gaps

        @children.each do |child|
          if child.flex > 0
            flex_total += child.flex
          else
            child.measure(available_width - used_width, max_height)
            used_width += child.width
            max_child_height = {max_child_height, child.height}.max
          end
        end

        # Second pass: measure flex children
        if flex_total > 0
          remaining_width = (available_width - used_width).clamp(0, available_width)
          unit_width = remaining_width // flex_total

          @children.each do |child|
            if child.flex > 0
              w = (child.flex * unit_width)
              child.measure(w, max_height)
              used_width += child.width
              max_child_height = {max_child_height, child.height}.max
            end
          end
        end

        @width = used_width + total_gaps
        @height = max_child_height
      end

      def render(io : IO, x : Int32, y : Int32)
        current_x = x
        @children.each_with_index do |child, i|
          current_x += @gap if i > 0
          child.render(io, current_x, y)
          current_x += child.width
        end
      end
    end

    class Border < Node
      def initialize(@child : Node, @title : String? = nil, @active : Bool = false)
      end

      def measure(max_width : Int32, max_height : Int32)
        # Border takes 2 chars width and 2 chars height
        child_max_width = (max_width - 2).clamp(0, max_width)
        child_max_height = (max_height - 2).clamp(0, max_height)

        # If child is flexible, we want to fill the available space
        # If not, we wrap the child
        if @flex > 0
          @width = max_width
          @height = max_height
          # Remeasure child to fill?
          @child.measure(child_max_width, child_max_height)
        else
          @child.measure(child_max_width, child_max_height)
          @width = @child.width + 2
          @height = @child.height + 2
        end
      end

      def render(io : IO, x : Int32, y : Int32)
        return if @width < 2 || @height < 2

        style = @active ? Term2::S.bold.cyan : Term2::S.gray

        # Top
        io << Cursor.move_to(y + 1, x + 1)
        io << (style | "┌")

        title = @title
        title_width = title ? title.size + 2 : 0
        available_width = @width - 2

        if title && title_width <= available_width
          # Draw title
          padding = available_width - title_width
          left_pad = padding // 2
          right_pad = padding - left_pad

          (left_pad).times { io << (style | "─") }
          io << " " << title << " "
          (right_pad).times { io << (style | "─") }
        else
          (available_width).times { io << (style | "─") }
        end
        io << (style | "┐")

        # Sides
        (1...@height - 1).each do |i|
          io << Cursor.move_to(y + 1 + i, x + 1)
          io << (style | "│")
          io << Cursor.move_to(y + 1 + i, x + @width)
          io << (style | "│")
        end

        # Bottom
        io << Cursor.move_to(y + @height, x + 1)
        io << (style | "└")
        (available_width).times { io << (style | "─") }
        io << (style | "┘")

        # Render child
        # Ensure we don't render outside the border
        # The child should have been measured to fit inside
        @child.render(io, x + 1, y + 1)
      end
    end

    class Padding < Node
      def initialize(@child : Node, @amount : Int32 = 1)
      end

      def measure(max_width : Int32, max_height : Int32)
        pad = @amount * 2
        child_max_width = (max_width - pad).clamp(0, max_width)
        child_max_height = (max_height - pad).clamp(0, max_height)

        @child.measure(child_max_width, child_max_height)

        if @flex > 0
          @width = max_width
          @height = max_height
          @child.measure(max_width - pad, max_height - pad)
        else
          @width = @child.width + pad
          @height = @child.height + pad
        end
      end

      def render(io : IO, x : Int32, y : Int32)
        @child.render(io, x + @amount, y + @amount)
      end
    end

    # Builder DSL
    class Builder
      getter root : Node

      def initialize
        @root = VStack.new # Default root
        @stack = [@root] of Node
      end

      def text(content : String)
        node = Text.new(content)
        add_to_current(node)
      end

      def h_stack(gap : Int32 = 0, flex : Int32 = 0, &)
        node = HStack.new(gap)
        node.flex = flex
        add_to_current(node)
        @stack.push(node)
        with self yield
        @stack.pop
      end

      def v_stack(flex : Int32 = 0, &)
        node = VStack.new
        node.flex = flex
        add_to_current(node)
        @stack.push(node)
        with self yield
        @stack.pop
      end

      def border(title : String? = nil, active : Bool = false, flex : Int32 = 0, &)
        # We need a temporary container for the block content
        # But Border only takes one child.
        # Let's assume the block creates one child, or we wrap it in a VStack?
        # For simplicity, let's say border wraps a VStack by default if multiple children?
        # Or better: use a temporary capture mechanism.

        # Actually, let's just make Border wrap a VStack internally if needed,
        # or require the user to provide a single node?
        # The DSL `with self yield` adds to the *current* node.
        # So we need to create the Border, add it to current, then push the Border's child container?
        # But Border isn't a container in the same way (it has 1 child).

        # Let's make Border wrap a VStack.
        container = VStack.new
        container.flex = 1 # Fill the border

        node = Border.new(container, title, active)
        node.flex = flex

        add_to_current(node)
        @stack.push(container)
        with self yield
        @stack.pop
      end

      def padding(amount : Int32 = 1, flex : Int32 = 0, &)
        container = VStack.new
        container.flex = 1

        node = Padding.new(container, amount)
        node.flex = flex

        add_to_current(node)
        @stack.push(container)
        with self yield
        @stack.pop
      end

      def add(node : Node)
        add_to_current(node)
      end

      private def add_to_current(node : Node)
        current = @stack.last
        if current.is_a?(VStack)
          current.add(node)
        elsif current.is_a?(HStack)
          current.add(node)
        end
      end
    end

    def self.render(width : Int32, height : Int32, &) : String
      builder = Builder.new
      with builder yield

      root = builder.root
      root.measure(width, height)

      String.build do |io|
        root.render(io, 0, 0)
      end
    end
  end
end
