require "../term2"
require "./viewport"
require "./key"
require "./help"

module Term2
  module Components
    class Table
      include Model

      # StyleFunc determines the style of a cell based on row and column position.
      alias StyleFunc = Proc(Int32, Int32, Style)

      alias Option = Proc(Table, Nil)

      struct Column
        getter title : String
        getter width : Int32

        def initialize(@title, @width)
        end
      end

      struct Styles
        getter header : Style
        getter cell : Style
        getter selected : Style

        def initialize(@header : Style = Style.new, @cell : Style = Style.new, @selected : Style = Style.new)
        end
      end

      alias Row = Array(String)

      property columns : Array(Column)
      property rows : Array(Row)
      property cursor : Int32 = 0
      property width : Int32 = 0
      property height : Int32 = 0
      property? focus : Bool = false
      property id : String = "" # Zone ID for focus management

      # Styles
      property header_style : Style = Style.new.bold(true).underline(true)
      property selected_style : Style = Style.new.reverse(true)
      property cell_style : Style = Style.new

      # StyleFunc for per-cell styling (overrides header_style/cell_style when set)
      property style_func : StyleFunc? = nil

      # Border configuration
      property border : Border = Border.new
      property border_style : Style = Style.new
      property border_top : Bool = false
      property border_bottom : Bool = false
      property border_left : Bool = false
      property border_right : Bool = false
      property border_header : Bool = false
      property border_column : Bool = false
      property border_row : Bool = false

      # Components
      property viewport : Viewport
      property key_map : KeyMap
      property help : Help = Help.new
      property start : Int32 = 0
      property end : Int32 = 0

      struct KeyMap
        getter line_up : Key::Binding
        getter line_down : Key::Binding
        getter page_up : Key::Binding
        getter page_down : Key::Binding
        getter goto_top : Key::Binding
        getter goto_bottom : Key::Binding

        def initialize
          @line_up = Key::Binding.new(["up", "k"], "↑/k", "up")
          @line_down = Key::Binding.new(["down", "j"], "↓/j", "down")
          @page_up = Key::Binding.new(["b", "pgup"], "b/pgup", "page up")
          @page_down = Key::Binding.new(["f", "pgdn", " "], "f/pgdn", "page down")
          @goto_top = Key::Binding.new(["home", "g"], "g/home", "go to start")
          @goto_bottom = Key::Binding.new(["end", "G"], "G/end", "go to end")
        end
      end

      def self.default_key_map : KeyMap
        KeyMap.new
      end

      def self.default_styles : Styles
        Styles.new(
          header: Style.new.padding(0, 1).bold(true),
          cell: Style.new.padding(0, 1),
          selected: Style.new.bold(true).foreground(Color::MAGENTA) # stripped in tests
        )
      end

      # Option-style constructor (parity with Bubbles)
      def self.build(*opts : Option) : Table
        table = Table.new
        opts.each(&.call(table))
        table.update_viewport
        table
      end

      # Keep existing constructors for compatibility
      def initialize(columns : Array(Column) = [] of Column, rows : Array(Row) = [] of Row, width : Int32 = 0, height : Int32 = 0, id : String = "")
        @viewport = Viewport.new(0, 20)
        @key_map = Table.default_key_map
        styles = Table.default_styles
        @header_style = styles.header
        @cell_style = styles.cell
        @selected_style = styles.selected
        initialize_defaults
        @columns = columns
        @rows = rows
        @width = width
        @height = height
        @id = id
        @viewport.width = width
        recalc_viewport_height
        update_viewport
      end

      # Overload for easier initialization with tuples and arrays
      def initialize(columns : Array({String, Int32}), rows : Array(Array(String)), width : Int32 = 0, height : Int32 = 0, id : String = "")
        initialize(columns.map { |col| Column.new(col[0], col[1]) }, rows, width, height, id)
      end

      # DSL-style initializer
      #
      # ```
      # table = Table.new(width: 50, height: 10) do |t|
      #   t.column "ID", 5
      #   t.column "Name", 20
      #   t.row "1", "Alice"
      #   t.row "2", "Bob"
      # end
      # ```
      def self.new(width : Int32 = 80, height : Int32 = 20, & : Table -> Nil)
        instance = new([] of Column, [] of Row, width, height)
        yield instance
        instance.update_viewport
        instance
      end

      private def initialize_defaults
        @columns = [] of Column
        @rows = [] of Row
        @cursor = 0
        @width = 0
        @height = 0
        @focus = false
        @id = ""
        styles = Table.default_styles
        @header_style = styles.header
        @cell_style = styles.cell
        @selected_style = styles.selected
        @style_func = nil
        @border = Border.new
        @border_style = Style.new
        @border_top = false
        @border_bottom = false
        @border_left = false
        @border_right = false
        @border_header = false
        @border_column = false
        @border_row = false
        @key_map = Table.default_key_map
        @help = Help.new
        @viewport ||= Viewport.new(0, 20)
      end

      def column(title : String, width : Int32)
        @columns << Column.new(title, width)
      end

      def row(*values : String)
        @rows << values.to_a
      end

      def row(values : Array(String))
        @rows << values
      end

      # Set the style function for per-cell styling
      def style_func(func : StyleFunc) : self
        @style_func = func
        self
      end

      def focused? : Bool
        @id.empty? ? true : Zone.focused?(@id)
      end

      def focus
        Zone.focus(@id) unless @id.empty?
      end

      def blur
        Zone.blur(@id) unless @id.empty?
      end

      def rows=(rows : Array(Row))
        @rows = rows
        @cursor = 0 if @cursor >= @rows.size
        recalc_viewport_height
        update_viewport
      end

      def columns=(columns : Array(Column))
        @columns = columns
        recalc_viewport_height
        update_viewport
      end

      def selected_row : Row?
        @rows[@cursor]?
      end

      def update(msg : Msg) : {Table, Cmd}
        return {self, Cmds.none} unless @focus
        case msg
        when KeyMsg
          case
          when @key_map.line_up.matches?(msg)
            move_up(1)
          when @key_map.line_down.matches?(msg)
            move_down(1)
          when @key_map.page_up.matches?(msg)
            move_up(@viewport.height)
          when @key_map.page_down.matches?(msg)
            move_down(@viewport.height)
          when @key_map.goto_top.matches?(msg)
            goto_top
          when @key_map.goto_bottom.matches?(msg)
            goto_bottom
          end
        end
        {self, Cmds.none}
      end

      def move_up(n : Int32)
        max_index = @rows.size - 1
        max_index = 0 if max_index < 0
        @cursor = (@cursor - n).clamp(0, max_index)
        keep_cursor_visible
        update_viewport
      end

      def move_down(n : Int32)
        max_index = @rows.size - 1
        max_index = 0 if max_index < 0
        @cursor = (@cursor + n).clamp(0, max_index)
        keep_cursor_visible
        update_viewport
      end

      def goto_top
        @cursor = 0
        @viewport.y_offset = 0
        update_viewport
      end

      def goto_bottom
        max_index = @rows.size - 1
        max_index = 0 if max_index < 0
        @cursor = max_index
        keep_cursor_visible
        update_viewport
      end

      def set_cursor(n : Int32)
        max_index = @rows.size - 1
        max_index = 0 if max_index < 0
        @cursor = n.clamp(0, max_index)
        keep_cursor_visible
        update_viewport
      end

      def focus
        @focus = true
        update_viewport
      end

      def blur
        @focus = false
        update_viewport
      end

      def keep_cursor_visible
        if @cursor < @viewport.y_offset
          @viewport.y_offset = @cursor
        elsif @cursor >= @viewport.y_offset + @viewport.height
          @viewport.y_offset = @cursor - @viewport.height + 1
        end
      end

      def set_width(w : Int32)
        @viewport.width = w
        update_viewport
      end

      def set_height(h : Int32)
        @height = h
        recalc_viewport_height
        update_viewport
      end

      def height_value : Int32
        @viewport.height
      end

      def width_value : Int32
        @viewport.width
      end

      def cursor_value : Int32
        @cursor
      end

      def update_viewport
        header_lines = render_header_lines
        lines = [] of String
        @rows.each_with_index do |row, i|
          lines.concat(render_row_lines(row, i, i == @cursor && @focus))
        end

        header_calc_height = @columns.empty? ? 0 : 1
        effective_height = if @height > 0
                             (@height - header_calc_height).clamp(0, Int32::MAX)
                           elsif @viewport.height != 0 && @viewport.height != 20
                             @viewport.height
                           else
                             20
                           end
        pad_width_source = lines.first? ? Term2::Text.width(lines.first) : 0
        header_width = header_lines.first? ? Term2::Text.width(header_lines.first) : 0
        pad_base_width = pad_width_source > 0 ? pad_width_source : header_width
        pad_line = if @viewport.width > 0
                     " " * @viewport.width
                   else
                     " " * pad_base_width
                   end

        start = @viewport.y_offset.clamp(0, Math.max(lines.size - effective_height, 0))
        lines = lines[start, effective_height] || [] of String
        while lines.size < effective_height
          lines << pad_line
        end

        @viewport.content = lines.join("\n")
      end

      private def recalc_viewport_height
        header_h = render_header_lines.size
        if @height > 0
          @viewport.height = (@height - header_h)
          @viewport.height = 0 if @viewport.height < 0
        end
      end

      # Get style for a cell, using style_func if set, otherwise defaults
      private def get_cell_style(row_idx : Int32, col_idx : Int32, selected : Bool) : Style
        return @style_func.not_nil!.call(row_idx, col_idx) if @style_func
        return @header_style if row_idx == -1
        return @selected_style if selected
        @cell_style
      end

      def render_row(row : Row, row_idx : Int32, selected : Bool) : String
        render_row_lines(row, row_idx, selected).first
      end

      def render_header : String
        render_header_lines.first
      end

      # Option helpers (parity with Bubbles)
      def self.with_columns(cols : Array(Column)) : Option
        ->(t : Table) { t.columns = cols }
      end

      def self.with_rows(rows : Array(Row)) : Option
        ->(t : Table) { t.rows = rows }
      end

      def self.with_height(h : Int32) : Option
        ->(t : Table) { t.set_height(h) }
      end

      def self.with_width(w : Int32) : Option
        ->(t : Table) { t.set_width(w) }
      end

      def self.with_focused(f : Bool) : Option
        ->(t : Table) { t.focus = f }
      end

      def self.with_styles(styles : Styles) : Option
        ->(t : Table) {
          t.header_style = styles.header
          t.cell_style = styles.cell
          t.selected_style = styles.selected
        }
      end

      def self.with_key_map(map : KeyMap) : Option
        ->(t : Table) { t.key_map = map }
      end

      def view : String
        header_lines = render_header_lines
        body = @viewport.content
        content = String.build do |io|
          unless header_lines.empty?
            io << header_lines.join("\n")
            io << "\n" unless body.empty?
          end
          io << body
        end
        @id.empty? ? content : Zone.mark(@id, content)
      end

      private def render_cell(text : String, width : Int32, style : Style) : String
        truncated = truncate_with_ellipsis(text, width)
        pad_len = width - Term2::Text.width(truncated)
        padded = truncated + (" " * pad_len)

        padding = style.padding
        left_pad = " " * padding.left
        right_pad = " " * padding.right

        "#{left_pad}#{padded}#{right_pad}"
      end

      private def truncate_with_ellipsis(text : String, width : Int32) : String
        return "" if width <= 0
        return text if Term2::Text.width(text) <= width

        target = width - 1
        target = 0 if target < 0
        current_width = 0
        chars = [] of Char

        text.each_char do |ch|
          cw = Term2::Text.char_width(ch)
          break if current_width + cw > target
          chars << ch
          current_width += cw
        end

        if chars.empty?
          "…"
        else
          chars.join + "…"
        end
      end

      private def pad_to_viewport(line : String) : String
        return line if @viewport.width <= 0
        line.ljust(@viewport.width)
      end

      private def border_visible?(style : Style) : Bool
        border = style.border_style
        !border.top.empty? || !border.bottom.empty? || !border.left.empty? || !border.right.empty?
      end

      private def render_header_lines : Array(String)
        return [""] if @columns.empty?
        first_style = get_cell_style(-1, 0, false)
        if border_visible?(first_style)
          render_bordered_header
        else
          main_line = @columns.map_with_index { |col, col_idx| render_cell(col.title, col.width, get_cell_style(-1, col_idx, false)) }.join
          style = first_style
          lines = [] of String
          blank = " " * Term2::Text.width(main_line)
          style.padding.top.times { lines << blank }
          lines << main_line
          style.padding.bottom.times { lines << blank }
          lines
        end
      end

      private def render_row_lines(row : Row, row_idx : Int32, selected : Bool) : Array(String)
        return [pad_to_viewport("")] if @columns.empty?
        first_style = get_cell_style(row_idx, 0, selected)
        if border_visible?(first_style)
          render_bordered_row(row)
        else
          main_line = pad_to_viewport(row.map_with_index { |cell, col_idx|
            col = @columns[col_idx]?
            width = col ? col.width : 10
            render_cell(cell, width, get_cell_style(row_idx, col_idx, selected))
          }.join)
          style = first_style
          lines = [] of String
          blank = pad_to_viewport(" " * Term2::Text.width(main_line))
          style.padding.top.times { lines << blank }
          lines << main_line
          style.padding.bottom.times { lines << blank }
          lines
        end
      end

      private def render_bordered_header : Array(String)
        top = String.build do |io|
          @columns.each do |col|
            io << "┌" << "─" * col.width << "┐"
          end
        end

        mid = String.build do |io|
          @columns.each_with_index do |col, _|
            content = truncate_with_ellipsis(col.title, col.width)
            pad_len = col.width - Term2::Text.width(content)
            io << "│" << content << (" " * pad_len) << "│"
          end
        end

        bottom = String.build do |io|
          @columns.each do |col|
            io << "└" << "─" * col.width << "┘"
          end
        end

        [pad_to_viewport(top), pad_to_viewport(mid), pad_to_viewport(bottom)]
      end

      private def render_bordered_row(row : Row) : Array(String)
        top = String.build do |io|
          @columns.each do |col|
            io << "┌" << "─" * col.width << "┐"
          end
        end

        mid = String.build do |io|
          row.each_with_index do |cell, col_idx|
            col = @columns[col_idx]?
            width = col ? col.width : 10
            content = truncate_with_ellipsis(cell, width)
            pad_len = width - Term2::Text.width(content)
            io << "│" << content << (" " * pad_len) << "│"
          end
        end

        bottom = String.build do |io|
          @columns.each do |col|
            io << "└" << "─" * col.width << "┘"
          end
        end

        [top, mid, bottom].map { |l| pad_to_viewport(l) }
      end
    end
  end
end
