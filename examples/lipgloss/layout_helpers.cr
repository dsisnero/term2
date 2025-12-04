# Layout helpers for lipgloss examples
# Provides positioning and layout utilities similar to lipgloss's layout functions

module LipglossLayoutHelpers
  # Basic positioning function
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

  # Center text within a given width
  def center_text(text : String, width : Int32) : String
    text_width = text.size
    return text if text_width >= width

    padding = width - text_width
    left_pad = padding // 2
    right_pad = padding - left_pad

    " " * left_pad + text + " " * right_pad
  end

  # Left align text within a given width
  def left_text(text : String, width : Int32) : String
    text_width = text.size
    return text[0...width] if text_width >= width

    text + " " * (width - text_width)
  end

  # Right align text within a given width
  def right_text(text : String, width : Int32) : String
    text_width = text.size
    return text[text_width - width...text_width] if text_width >= width

    " " * (width - text_width) + text
  end

  # Simple box drawing
  def draw_box(width : Int32, height : Int32, content : String = "",
               border_style : Symbol = :single) : String
    borders = case border_style
              when :single
                {"┌", "─", "┐", "│", "└", "─", "┘"}
              when :double
                {"╔", "═", "╗", "║", "╚", "═", "╝"}
              when :rounded
                {"╭", "─", "╮", "│", "╰", "─", "╯"}
              when :thick
                {"┏", "━", "┓", "┃", "┗", "━", "┛"}
              else
                {"┌", "─", "┐", "│", "└", "─", "┘"}
              end

    tl, h, tr, v, bl, bh, br = borders

    top_border = tl + h * (width - 2) + tr
    bottom_border = bl + bh * (width - 2) + br

    String.build do |io|
      io << top_border << "\n"

      content_lines = content.lines
      (height - 2).times do |i|
        if i < content_lines.size
          line = content_lines[i]
          padded_line = center_text(line, width - 2)
          io << v << padded_line << v << "\n"
        else
          io << v << " " * (width - 2) << v << "\n"
        end
      end

      io << bottom_border
    end
  end

  # Create a grid layout
  def grid_layout(items : Array(String), columns : Int32,
                  cell_width : Int32, cell_height : Int32) : String
    rows = (items.size + columns - 1) // columns

    String.build do |io|
      rows.times do |row|
        columns.times do |col|
          index = row * columns + col
          if index < items.size
            cell = draw_box(cell_width, cell_height, items[index])
            io << cell
          else
            cell = draw_box(cell_width, cell_height, "")
            io << cell
          end

          io << "  " unless col == columns - 1
        end
        io << "\n"
      end
    end
  end

  # Responsive layout that adjusts columns based on available width
  def responsive_grid(items : Array(String), available_width : Int32,
                      min_cell_width : Int32 = 20, cell_height : Int32 = 8) : String
    # Calculate optimal columns
    columns = [available_width // (min_cell_width + 2), 1].max
    columns = [columns, items.size].min

    # Adjust cell width to fit available space
    cell_width = (available_width - (columns - 1) * 2) // columns

    grid_layout(items, columns, cell_width, cell_height)
  end

  # Create a two-column layout
  def two_column_layout(left_content : String, right_content : String,
                        total_width : Int32 = 80, gutter : Int32 = 4) : String
    col_width = (total_width - gutter) // 2

    left_lines = left_content.lines.to_a
    right_lines = right_content.lines.to_a
    max_lines = [left_lines.size, right_lines.size].max

    String.build do |io|
      max_lines.times do |i|
        left_line = i < left_lines.size ? left_lines[i] : ""
        right_line = i < right_lines.size ? right_lines[i] : ""

        left_padded = left_text(left_line, col_width)
        right_padded = left_text(right_line, col_width)

        io << left_padded << " " * gutter << right_padded << "\n"
      end
    end
  end

  # Create a header
  def create_header(title : String, width : Int32,
                    border_style : Symbol = :double) : String
    top_border, h, bottom_border = case border_style
                                   when :double
                                     {"╔", "═", "╗", "║", "╚", "═", "╝"}
                                   when :single
                                     {"┌", "─", "┐", "│", "└", "─", "┘"}
                                   else
                                     {"┌", "─", "┐", "│", "└", "─", "┘"}
                                   end

    tl, h, tr, v, bl, bh, br = top_border, h, bottom_border, "║", "╚", "═", "╝"

    String.build do |io|
      io << tl << h * (width - 2) << tr << "\n"
      io << v << center_text(title, width - 2) << v << "\n"
      io << bl << bh * (width - 2) << br
    end
  end

  # Create a separator line
  def separator(width : Int32, style : Symbol = :single) : String
    case style
    when :single
      "─" * width
    when :double
      "═" * width
    when :dashed
      "-" * width
    when :dotted
      "·" * width
    else
      "─" * width
    end
  end

  # Create a panel with title
  def create_panel(title : String, content : String, width : Int32, height : Int32) : String
    draw_box(width, height, content, :double)
  end

  # Layout with margins
  def with_margins(content : String, left : Int32 = 2, right : Int32 = 2,
                   top : Int32 = 1, bottom : Int32 = 1) : String
    lines = content.lines
    content_width = lines.max_of(&.size) || 0
    total_width = content_width + left + right

    String.build do |io|
      # Top margin
      top.times { io << " " * total_width << "\n" }

      # Content with side margins
      lines.each do |line|
        io << " " * left << line << " " * (total_width - left - line.size) << "\n"
      end

      # Bottom margin
      bottom.times { io << " " * total_width << "\n" }
    end
  end

  # Stack multiple contents vertically
  def vertical_stack(contents : Array(String), spacing : Int32 = 1) : String
    String.build do |io|
      contents.each_with_index do |content, i|
        io << content
        io << "\n" * spacing unless i == contents.size - 1
      end
    end
  end

  # Arrange contents horizontally
  def horizontal_arrange(contents : Array(String), spacing : Int32 = 2) : String
    # Convert all contents to arrays of lines
    content_lines = contents.map(&.lines.to_a)
    max_lines = content_lines.max_of(&.size) || 0

    # Get widths for each content
    content_widths = contents.map do |content|
      content.lines.max_of(&.size) || 0
    end

    String.build do |io|
      max_lines.times do |line_idx|
        contents.each_with_index do |_, content_idx|
          if line_idx < content_lines[content_idx].size
            line = content_lines[content_idx][line_idx]
            io << left_text(line, content_widths[content_idx])
          else
            io << " " * content_widths[content_idx]
          end

          io << " " * spacing unless content_idx == contents.size - 1
        end
        io << "\n"
      end
    end
  end
end
