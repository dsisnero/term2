module Term2
  module LipGloss
    class Table
      property headers : Array(String)
      property rows : Array(Array(String))
      property border : Border
      property border_style : Style
      property header_style : Style
      property cell_style : Style
      property width : Int32?
      property style_func : Proc(Int32, Int32, Style?)?

      def initialize
        @headers = [] of String
        @rows = [] of Array(String)
        @border = Border.normal
        @border_style = Style.new
        @header_style = Style.new
        @cell_style = Style.new
      end

      def headers(*h : String)
        @headers = h.to_a
        self
      end

      def headers(h : Array(String))
        @headers = h
        self
      end

      def rows(r : Array(Array(String)))
        @rows = r
        self
      end

      def row(*r : String)
        @rows << r.to_a
        self
      end

      def border(b : Border)
        @border = b
        self
      end

      def border_style(s : Style)
        @border_style = s
        self
      end

      def header_style(s : Style)
        @header_style = s
        self
      end

      def cell_style(s : Style)
        @cell_style = s
        self
      end

      def width(w : Int32)
        @width = w
        self
      end

      def style_func(fn : Proc(Int32, Int32, Style?))
        @style_func = fn
        self
      end

      def render : String
        return "" if @headers.empty? && @rows.empty?

        col_widths = calculate_widths

        # Apply width constraint if set
        if @width
          # This is a naive implementation. Real table resizing is hard.
          # For now, we just respect the calculated widths.
        end

        lines = [] of String

        # Top Border
        lines << render_top_border(col_widths) if has_border?

        # Headers
        if !@headers.empty?
          lines << render_row(@headers, col_widths, @header_style, -1)
          lines << render_header_separator(col_widths) if has_border? && !@rows.empty?
        end

        # Rows
        @rows.each_with_index do |row, i|
          lines << render_row(row, col_widths, @cell_style, i)
          # TODO: Row separators?
        end

        # Bottom Border
        lines << render_bottom_border(col_widths) if has_border?

        lines.join("\n")
      end

      private def has_border?
        # Check if border is not hidden/empty
        # For now assume yes if border is set
        true
      end

      private def calculate_widths
        widths = [] of Int32
        if !@headers.empty?
          widths = @headers.map { |header| Term2::LipGloss::Style.new.render(header).size }
        end

        @rows.each do |row|
          row.each_with_index do |cell, i|
            w = Term2::LipGloss::Style.new.render(cell).size
            if i >= widths.size
              widths << w
            else
              widths[i] = [widths[i], w].max
            end
          end
        end
        widths
      end

      private def render_top_border(widths : Array(Int32))
        left = @border.top_left
        right = @border.top_right
        mid = @border.top

        # Wait, Border struct in lipgloss.cr has:
        # top, bottom, left, right, top_left, top_right, bottom_left, bottom_right,
        # middle_left, middle_right, middle, middle_top, middle_bottom

        # For a table, we need joints between columns.
        # Let's assume standard border has these.

        parts = [] of String
        widths.each do |width|
          parts << (mid * (width + 2)) # +2 for padding?
        end

        # Actually, we need to account for cell padding.
        # Let's assume 1 space padding on each side for now.

        # Construct the full line
        @border_style.render("#{left}#{parts.join(@border.middle_top)}#{right}")
      end

      private def render_bottom_border(widths : Array(Int32))
        left = @border.bottom_left
        right = @border.bottom_right
        mid = @border.bottom

        parts = widths.map { |width| mid * (width + 2) }
        @border_style.render("#{left}#{parts.join(@border.middle_bottom)}#{right}")
      end

      private def render_header_separator(widths : Array(Int32))
        left = @border.middle_left
        right = @border.middle_right
        mid = @border.top # Use horizontal line character

        parts = widths.map { |width| mid * (width + 2) }
        @border_style.render("#{left}#{parts.join(@border.middle)}#{right}")
      end

      private def render_row(row : Array(String), widths : Array(Int32), default_style : Style, row_index : Int32)
        parts = [] of String
        widths.each_with_index do |_, col_index|
          content = col_index < row.size ? row[col_index] : ""

          style = default_style
          if fn = @style_func
            if s = fn.call(row_index, col_index)
              style = s
            end
          end

          # Using Style to pad/align
          cell_rendered = style.copy.width(w).render(content)
          parts << " #{cell_rendered} "
        end

        left = @border.left
        right = @border.right
        sep = @border.left

        line = parts.join(sep)
        @border_style.render("#{left}#{line}#{right}")
      end
    end
  end
end
