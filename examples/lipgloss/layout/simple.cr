# Port of lipgloss layout/simple example to term2
# Original Go code: https://github.com/charmbracelet/lipgloss/blob/main/examples/layout/simple/main.go
#
# This example demonstrates simple text positioning similar to lipgloss's Place() function.
# Since term2 doesn't have an exact equivalent, we create simple positioning functions.

module LipglossLayoutHelpers
  # Simple positioning function that mimics lipgloss.Place()
  # Places text within a given width and height, with horizontal and vertical alignment
  def place_text(text : String, width : Int32, height : Int32,
                 h_align : Symbol = :center, v_align : Symbol = :center) : String
    lines = text.lines

    # Calculate vertical padding
    v_padding = height - lines.size
    v_padding_top = case v_align
                    when :top    then 0
                    when :center then v_padding // 2
                    when :bottom then v_padding
                    else              0
                    end

    # Calculate horizontal alignment for each line
    aligned_lines = lines.map do |line|
      line_width = line.size
      h_padding = width - line_width

      h_padding_left = case h_align
                       when :left   then 0
                       when :center then h_padding // 2
                       when :right  then h_padding
                       else              0
                       end

      " " * h_padding_left + line + " " * (h_padding - h_padding_left)
    end

    # Build the final output with vertical padding
    String.build do |io|
      # Top padding
      v_padding_top.times { io << " " * width << "\n" }

      # Content lines
      aligned_lines.each { |line| io << line << "\n" }

      # Bottom padding
      (v_padding - v_padding_top).times { io << " " * width << "\n" }
    end
  end

  # Simple box drawing function
  def draw_box(width : Int32, height : Int32, content : String = "") : String
    top_border = "┌" + "─" * (width - 2) + "┐"
    bottom_border = "└" + "─" * (width - 2) + "┘"

    String.build do |io|
      io << top_border << "\n"

      # Content lines or empty middle
      content_lines = content.lines
      (height - 2).times do |i|
        if i < content_lines.size
          line = content_lines[i]
          line_width = line.size
          padding = width - 2 - line_width
          left_pad = padding // 2
          right_pad = padding - left_pad
          io << "│" << " " * left_pad << line << " " * right_pad << "│\n"
        else
          io << "│" << " " * (width - 2) << "│\n"
        end
      end

      io << bottom_border
    end
  end
end

include LipglossLayoutHelpers

puts "Lipgloss Layout/Simple Example Ported to Term2"
puts "=" * 60

# Example 1: Simple centered text
text1 = "Hello, World!"
placed1 = place_text(text1, 50, 10, :center, :center)
puts "Example 1: Centered Text in 50x10 area"
puts placed1
puts "-" * 60

# Example 2: Top-left aligned text
text2 = "Top Left"
placed2 = place_text(text2, 40, 8, :left, :top)
puts "Example 2: Top-Left Aligned in 40x8 area"
puts placed2
puts "-" * 60

# Example 3: Bottom-right aligned text
text3 = "Bottom Right"
placed3 = place_text(text3, 40, 8, :right, :bottom)
puts "Example 3: Bottom-Right Aligned in 40x8 area"
puts placed3
puts "-" * 60

# Example 4: Box with centered content
box_content = "Centered\nin a box"
box = draw_box(30, 8, box_content)
puts "Example 4: Box with centered content (30x8)"
puts box
puts "-" * 60

# Example 5: Multiple alignment examples
puts "Example 5: Multiple alignment examples in boxes"
puts

alignments = [
  {:left, :top, "Top-Left"},
  {:center, :top, "Top-Center"},
  {:right, :top, "Top-Right"},
  {:left, :center, "Middle-Left"},
  {:center, :center, "Center"},
  {:right, :center, "Middle-Right"},
  {:left, :bottom, "Bottom-Left"},
  {:center, :bottom, "Bottom-Center"},
  {:right, :bottom, "Bottom-Right"},
]

alignments.each_slice(3) do |row|
  row.each do |h_align, v_align, label|
    placed = place_text(label, 18, 6, h_align, v_align)
    box = draw_box(20, 8, placed)
    print box
    print "  "
  end
  puts
end

puts "=" * 60
puts "Layout examples completed!"
