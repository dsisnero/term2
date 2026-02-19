require "./style"

module Lipgloss
  module StyleTable
    HEADER_ROW = -1

    alias StyleFunc = Proc(Int32, Int32, Style)

    module Data
      abstract def at(row : Int32, cell : Int32) : String
      abstract def rows : Int32
      abstract def columns : Int32
    end

    class StringData
      include Data

      @rows : Array(Array(String))
      @columns : Int32

      def initialize(rows : Array(Array(String)) = [] of Array(String))
        @rows = [] of Array(String)
        @columns = 0
        rows.each { |row| append(row) }
      end

      def append(row : Array(String))
        @columns = Math.max(@columns, row.size)
        @rows << row
      end

      def append(row : Enumerable(String))
        append(row.to_a)
      end

      def item(*row : String) : self
        append(row.to_a)
        self
      end

      def at(row : Int32, cell : Int32) : String
        return "" unless row < @rows.size && cell < @rows[row].size
        @rows[row][cell]
      end

      def rows : Int32
        @rows.size
      end

      def columns : Int32
        @columns
      end
    end

    class Filter
      include Data

      @data : Data
      @filter : Proc(Int32, Bool)?

      def initialize(data : Data)
        @data = data
      end

      def filter(&block : Int32 -> Bool) : self
        @filter = block
        self
      end

      def at(row : Int32, cell : Int32) : String
        visible_row_index = 0
        (0...@data.rows).each do |source_row_index|
          if include_row?(source_row_index)
            return @data.at(source_row_index, cell) if visible_row_index == row
            visible_row_index += 1
          end
        end
        ""
      end

      def rows : Int32
        visible_row_count = 0
        (0...@data.rows).each do |source_row_index|
          visible_row_count += 1 if include_row?(source_row_index)
        end
        visible_row_count
      end

      def columns : Int32
        @data.columns
      end

      private def include_row?(idx : Int32) : Bool
        if f = @filter
          f.call(idx)
        else
          true
        end
      end
    end

    struct ResizerColumn
      property index : Int32
      property min : Int32
      property max : Int32
      property median : Int32
      property rows : Array(Array(String))
      property x_padding : Int32
      property fixed_width : Int32

      def initialize(@index, @min, @max, @median, @rows = [] of Array(String), @x_padding = 0, @fixed_width = 0)
      end
    end

    class Resizer
      property table_width : Int32
      property table_height : Int32
      getter headers : Array(String)
      getter all_rows : Array(Array(String))
      property row_heights : Array(Int32)
      property columns : Array(ResizerColumn)
      property? wrap : Bool = true
      property? border_column : Bool = true
      property y_paddings : Array(Array(Int32)) = [] of Array(Int32)

      def initialize(@table_width : Int32, @table_height : Int32, @headers : Array(String), rows : Array(Array(String)))
        @all_rows = !headers.empty? ? rows.dup.unshift(headers) : rows.dup
        @row_heights = Array.new(@all_rows.size, 0)
        @columns = [] of ResizerColumn

        @all_rows.each do |row|
          row.each_with_index do |cell, idx|
            cell_len = Lipgloss::Text.width(cell)
            if idx >= @columns.size
              @columns << ResizerColumn.new(idx, cell_len, cell_len, cell_len)
              next
            end

            col = @columns[idx]
            col.rows << row
            col.min = Math.min(col.min, cell_len)
            col.max = Math.max(col.max, cell_len)
            @columns[idx] = col
          end
        end

        @columns.each_with_index do |col, idx|
          widths = col.rows.map { |row| Lipgloss::Text.width(row[idx]) }
          new_col = @columns[idx]
          new_col.median = widths.empty? ? col.max : StyleTable.median(widths)
          @columns[idx] = new_col
        end
      end

      def optimized_widths : {Array(Int32), Array(Int32)}
        if max_total <= @table_width || @table_width <= 0
          expand_table_width
        else
          shrink_table_width
        end
      end

      private def expand_table_width : {Array(Int32), Array(Int32)}
        col_widths = max_column_widths
        loop do
          total = StyleTable.sum(col_widths) + total_horizontal_border
          break if total >= @table_width

          shorter_idx = 0
          shorter_width = Int32::MAX
          col_widths.each_with_index do |col_width, idx|
            next if col_width == @columns[idx].fixed_width
            if col_width < shorter_width
              shorter_width = col_width
              shorter_idx = idx
            end
          end
          col_widths[shorter_idx] += 1
        end
        {col_widths, expand_row_heights(col_widths)}
      end

      private def shrink_table_width : {Array(Int32), Array(Int32)}
        col_widths = max_column_widths

        shrink_big_columns = ->(very_big_only : Bool) do
          loop do
            total = StyleTable.sum(col_widths) + total_horizontal_border
            break if total <= @table_width

            big_idx = -Int32::MAX
            big_width = -Int32::MAX
            col_widths.each_with_index do |col_width, idx|
              next if col_width == @columns[idx].fixed_width
              if very_big_only
                next unless col_width >= (@table_width // 2)
              end
              if col_width > big_width
                big_width = col_width
                big_idx = idx
              end
            end
            break if big_idx < 0 || col_widths[big_idx] == 0
            col_widths[big_idx] -= 1
          end
        end

        shrink_to_median = -> {
          loop do
            total = StyleTable.sum(col_widths) + total_horizontal_border
            break if total <= @table_width

            big_diff = -Int32::MAX
            big_idx = -Int32::MAX
            col_widths.each_with_index do |col_width, idx|
              next if col_width == @columns[idx].fixed_width
              diff = col_width - @columns[idx].median
              if diff > 0 && diff > big_diff
                big_diff = diff
                big_idx = idx
              end
            end
            break if big_idx <= 0 || col_widths[big_idx] == 0
            col_widths[big_idx] -= 1
          end
        }

        shrink_big_columns.call(true)
        shrink_to_median.call
        shrink_big_columns.call(false)

        {col_widths, expand_row_heights(col_widths)}
      end

      def expand_row_heights(col_widths : Array(Int32)) : Array(Int32)
        row_heights = default_row_heights
        return row_heights unless @wrap

        has_headers = !@headers.empty?
        @all_rows.each_with_index do |row, row_index|
          row.each_with_index do |cell, column_index|
            next if has_headers && row_index == 0
            available = col_widths[column_index] - x_padding_for_col(column_index)
            height = detect_content_height(cell, available) + x_padding_for_cell(row_index, column_index)
            row_heights[row_index] = Math.max(row_heights[row_index], height)
          end
        end
        row_heights
      end

      private def detect_content_height(content : String, width : Int32) : Int32
        return 1 if width <= 0
        height = 0
        content = content.gsub("\r\n", "\n")
        content.split('\n').each do |line|
          wrapped = Cellwrap.wrap(Lipgloss::Text.strip_ansi(line), width)
          height += wrapped.count('\n') + 1
        end
        height
      end

      private def max_column_widths : Array(Int32)
        @columns.map do |col|
          if col.fixed_width > 0
            col.fixed_width
          else
            col.max + x_padding_for_col(col.index)
          end
        end
      end

      private def default_row_heights : Array(Int32)
        heights = Array(Int32).new(@all_rows.size, 1)
        heights.size.times do |row_index|
          if row_index < @row_heights.size
            heights[row_index] = @row_heights[row_index] > 0 ? @row_heights[row_index] : 1
          end
        end
        heights
      end

      private def total_horizontal_padding : Int32
        @columns.sum(&.x_padding)
      end

      private def total_horizontal_border : Int32
        (column_count * border_per_cell) + extra_border
      end

      private def border_per_cell : Int32
        @border_column ? 1 : 0
      end

      private def extra_border : Int32
        @border_column ? 1 : 0
      end

      private def column_count : Int32
        @columns.size
      end

      private def max_char_count : Int32
        @columns.sum do |col|
          if col.fixed_width > 0
            col.fixed_width - x_padding_for_col(col.index)
          else
            col.max
          end
        end
      end

      def max_total : Int32
        total = 0
        @columns.each_with_index do |col, idx|
          if col.fixed_width > 0
            total += col.fixed_width
          else
            total += col.max + x_padding_for_col(idx)
          end
        end
        total
      end

      def detect_table_width : Int32
        max_char_count + total_horizontal_padding + total_horizontal_border
      end

      # Debug/inspection helper
      def column_maxes : Array(Int32)
        @columns.map(&.max)
      end

      def x_padding_for_col(idx : Int32) : Int32
        col = @columns[idx]?
        col ? col.x_padding : 0
      end

      private def x_padding_for_cell(i : Int32, j : Int32) : Int32
        @y_paddings.dig?(i, j) || 0
      end
    end

    class Table
      getter border : Border = Border.rounded
      getter border_style : Style = Style.new
      getter base_style : Style = Style.new

      property? border_top : Bool = true
      property? border_bottom : Bool = true
      property? border_left : Bool = true
      property? border_right : Bool = true
      property? border_header : Bool = true
      property? border_column : Bool = true
      property? border_row : Bool = false

      property headers : Array(String) = [] of String
      property data : Data = StringData.new

      property width : Int32 = 0
      property height : Int32 = 0
      property? use_manual_height : Bool = false
      property offset : Int32 = 0
      property? wrap : Bool = true

      property style_func : StyleFunc? = ->(_row : Int32, _col : Int32) { Style.new }

      getter widths : Array(Int32) = [] of Int32
      getter heights : Array(Int32) = [] of Int32

      def initialize
      end

      def clear_rows : self
        @data = StringData.new
        self
      end

      def style_func(func : StyleFunc?) : self
        @style_func = func
        self
      end

      def style(row : Int32, col : Int32) : Style
        if func = @style_func
          func.call(row, col)
        else
          Style.new
        end
      end

      def data(data : Data) : self
        @data = data
        self
      end

      def rows(*rows : Array(String)) : self
        append_rows(rows.to_a)
        self
      end

      def rows(rows : Enumerable(Enumerable(String))) : self
        append_rows(rows.to_a.map(&.to_a))
        self
      end

      def append_rows(rows : Array(Array(String))) : Nil
        rows.each do |row|
          case d = @data
          when StringData
            d.append(row)
          end
        end
      end

      def row(*row : String) : self
        case d = @data
        when StringData
          d.append(row.to_a)
        end
        self
      end

      def row(row : Enumerable(String)) : self
        case d = @data
        when StringData
          d.append(row)
        end
        self
      end

      def headers(*headers : String) : self
        @headers = headers.to_a
        self
      end

      def border(border : Border) : self
        @border = border
        self
      end

      def border_style(style : Style) : self
        @border_style = style
        self
      end

      def base_style(style : Style) : self
        @base_style = style
        self
      end

      def width(w : Int32) : self
        @width = w
        self
      end

      def height(h : Int32) : self
        @height = h
        @use_manual_height = true
        self
      end

      def offset(o : Int32) : self
        @offset = o
        self
      end

      def y_offset(o : Int32) : self
        offset(o)
      end

      def wrap(v : Bool) : self
        @wrap = v
        self
      end

      def string : String
        has_headers = !@headers.empty?
        has_rows = @data && @data.rows > 0
        return "" unless has_headers || has_rows

        if has_headers
          (@headers.size...@data.columns).each { @headers << "" }
        end

        resize

        prefix_parts = [] of String
        prefix_parts << construct_top_border if @border_top
        prefix_parts << construct_headers if has_headers
        prefix = prefix_parts.join("\n")
        prefix += "\n" unless prefix.empty?

        io = String::Builder.new
        io << prefix

        bottom = @border_bottom ? construct_bottom_border : ""

        if @data.rows > 0
          if @use_manual_height
            top_height = prefix.empty? ? 0 : (Lipgloss::Text.height(prefix) - 1)
            available = @height - (top_height + Lipgloss::Text.height(bottom))
            available = Math.min(available, @data.rows)
            io << construct_rows(available)
          else
            (@offset...@data.rows).each do |row_index|
              io << construct_row(row_index, false)
            end
          end
        end

        io << bottom

        @base_style
          .max_height(compute_height)
          .max_width(@width)
          .render(io.to_s)
      end

      # Expose resize for debugging/testing
      def resize_for_spec : Nil
        resize
      end

      def render : String
        string
      end

      private def compute_height : Int32
        has_headers = !@headers.empty?
        StyleTable.sum(@heights) - 1 + StyleTable.btoi(has_headers) +
          StyleTable.btoi(@border_top) + StyleTable.btoi(@border_bottom) +
          StyleTable.btoi(@border_header) + @data.rows * StyleTable.btoi(@border_row)
      end

      private def resize : Nil
        rows_matrix = StyleTable.data_to_matrix(@data)
        resizer = Resizer.new(@width, @height, @headers, rows_matrix)
        resizer.wrap = @wrap
        resizer.border_column = @border_column
        resizer.y_paddings = Array.new(resizer.all_rows.size) { [] of Int32 }

        all_rows = !@headers.empty? ? [@headers] + rows_matrix : rows_matrix
        style_fn = @style_func || ->(_r : Int32, _c : Int32) { Style.new }

        all_rows.each_with_index do |row, row_index|
          resizer.y_paddings[row_index] = Array.new(row.size, 0)
          row.each_index do |column_index|
            col = resizer.columns[column_index]?
            next unless col

            content_row_index = !@headers.empty? ? row_index - 1 : row_index
            style = style_fn.call(content_row_index, column_index)
            top_margin, right_margin, bottom_margin, left_margin = style.margin
            top_padding, right_padding, bottom_padding, left_padding = style.padding

            total_h = left_margin + right_margin + left_padding + right_padding
            content_width = Lipgloss::Text.width(row[column_index])
            col.x_padding = Math.max(col.x_padding, total_h)
            col.min = Math.max(col.min, content_width)
            col.max = Math.max(col.max, content_width)
            if (fw = style.width) > 0
              col.fixed_width = Math.max(col.fixed_width, fw)
            end
            resizer.columns[column_index] = col

            resizer.row_heights[row_index] = Math.max(resizer.row_heights[row_index], style.height)

            total_v = top_margin + bottom_margin + top_padding + bottom_padding
            resizer.y_paddings[row_index][column_index] = total_v
          end
        end

        resizer.table_width = @width <= 0 ? resizer.detect_table_width : @width
        @widths, @heights = resizer.optimized_widths
      end

      private def construct_top_border : String
        s = String::Builder.new
        if @border_left
          s << @border_style.render(@border.top_left)
        end
        @widths.each_with_index do |col_width, idx|
          s << @border_style.render(@border.top * col_width)
          if idx < @widths.size - 1 && @border_column
            s << @border_style.render(@border.middle_top)
          end
        end
        if @border_right
          s << @border_style.render(@border.top_right)
        end
        s.to_s
      end

      private def construct_bottom_border : String
        s = String::Builder.new
        if @border_left
          s << @border_style.render(@border.bottom_left)
        end
        @widths.each_with_index do |col_width, idx|
          s << @border_style.render(@border.bottom * col_width)
          if idx < @widths.size - 1 && @border_column
            s << @border_style.render(@border.middle_bottom)
          end
        end
        if @border_right
          s << @border_style.render(@border.bottom_right)
        end
        s.to_s
      end

      private def construct_headers : String
        height = @heights[HEADER_ROW + 1]
        s = String::Builder.new
        if @border_left
          s << @border_style.render(@border.left)
        end

        @headers.each_with_index do |header, column_index|
          cell_style = style(HEADER_ROW, column_index)
          header_content = @wrap ? header : truncate_cell(header, HEADER_ROW, column_index)

          horiz = @widths[column_index] - cell_style.horizontal_margins
          vert = height - cell_style.vertical_margins
          s << cell_style
            .height(vert)
            .max_height(height)
            .width(horiz)
            .max_width(@widths[column_index])
            .render(truncate_cell(header_content, HEADER_ROW, column_index))

          if column_index < @headers.size - 1 && @border_column
            s << @border_style.render(@border.left)
          end
        end

        if @border_header
          s << @border_style.render(@border.right) if @border_right
          s << "\n"
          if @border_left
            s << @border_style.render(@border.middle_left)
          end
          @headers.each_with_index do |_, column_index|
            s << @border_style.render(@border.top * @widths[column_index])
            if column_index < @headers.size - 1 && @border_column
              s << @border_style.render(@border.middle)
            end
          end
          if @border_right
            s << @border_style.render(@border.middle_right)
          end
        elsif @border_right
          s << @border_style.render(@border.right)
        end

        s.to_s
      end

      private def construct_rows(available_lines : Int32) : String
        sb = String::Builder.new

        offset_row_count = @data.rows - @offset
        rows_to_render = [available_lines, 1].max
        needs_overflow = rows_to_render < offset_row_count
        row_idx = needs_overflow ? @offset : @data.rows - rows_to_render

        while rows_to_render > 0 && row_idx < @data.rows
          is_overflow = needs_overflow && rows_to_render == 1
          sb << construct_row(row_idx, is_overflow)
          row_idx += 1
          rows_to_render -= 1
        end

        sb.to_s
      end

      private def construct_row(index : Int32, is_overflow : Bool) : String
        sb = String::Builder.new
        has_headers = !@headers.empty?
        height_idx = index + StyleTable.btoi(has_headers)
        height = @heights[height_idx]
        height = 1 if is_overflow

        cells = [] of String
        if @border_left
          left = (@border_style.render(@border.left) + "\n") * height
          cells << left
        end

        (0...@data.columns).each do |column_index|
          cell_text = is_overflow ? "…" : @data.at(index, column_index)
          cell_style = style(index, column_index)
          cell_text = truncate_cell(cell_text, index, column_index) unless @wrap
          horiz = @widths[column_index] - cell_style.horizontal_margins
          vert = height - cell_style.vertical_margins
          rendered = cell_style
            .height(vert)
            .max_height(height)
            .width(horiz)
            .max_width(@widths[column_index])
            .render(cell_text)
          cells << rendered
          if column_index < @data.columns - 1 && @border_column
            cells << ((@border.left + "\n") * height)
          end
        end

        if @border_right
          right = (@border_style.render(@border.right) + "\n") * height
          cells << right
        end

        cells.map!(&.rstrip('\n'))
        sb << Lipgloss.join_horizontal(Lipgloss::Position::Top, cells)
        sb << "\n" if index < @data.rows - 1 || @border_bottom

        if @border_row && index < @data.rows - 1 && !is_overflow
          sb << @border_style.render(@border.middle_left) if @border_left
          @widths.each_with_index do |col_width, column_index|
            sb << @border_style.render(@border.bottom * col_width)
            if column_index < @widths.size - 1 && @border_column
              sb << @border_style.render(@border.middle)
            end
          end
          sb << @border_style.render(@border.middle_right) if @border_right
          sb << "\n"
        end

        sb.to_s
      end

      private def truncate_cell(cell : String, row_idx : Int32, col_idx : Int32) : String
        has_headers = !@headers.empty?
        height = @heights[row_idx + StyleTable.btoi(has_headers)]
        cell_width = @widths[col_idx]
        cell_style = style(row_idx, col_idx)
        length = (cell_width * height) - cell_style.horizontal_padding - cell_style.horizontal_margins
        StyleTable.truncate(cell, length, "…")
      end
    end

    def self.data_to_matrix(data : Data) : Array(Array(String))
      rows = data.rows
      cols = data.columns
      matrix = Array.new(rows) { Array.new(cols, "") }
      rows.times do |row_index|
        cols.times do |column_index|
          matrix[row_index][column_index] = data.at(row_index, column_index)
        end
      end
      matrix
    end

    def self.btoi(v : Bool) : Int32
      v ? 1 : 0
    end

    def self.sum(values : Array(Int32)) : Int32
      values.sum
    end

    def self.median(values : Array(Int32)) : Int32
      return 0 if values.empty?
      sorted = values.sort
      mid = sorted.size // 2
      if sorted.size.even?
        (sorted[mid - 1] + sorted[mid]) // 2
      else
        sorted[mid]
      end
    end

    def self.truncate(text : String, width : Int32, tail : String = "") : String
      return "" if width <= 0
      return text if Lipgloss::Text.width(text) <= width

      target = [width - Lipgloss::Text.width(tail), 0].max
      visible = String::Builder.new
      current = 0
      text.each_grapheme do |grapheme|
        g_width = Lipgloss::Text.width(grapheme.to_s)
        break if current + g_width > target
        visible << grapheme
        current += g_width
      end
      visible << tail
      visible.to_s
    end
  end
end
