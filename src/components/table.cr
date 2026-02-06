require "nucleoc"
require "../term2"
require "./help"
require "./key"
require "./viewport"

module Term2
  module Components
    class Table
      include Model

      # HeaderRow constant used in StyleFunc to identify the header row
      HEADER_ROW = -1

      # StyleFunc determines the style of a cell based on row and column position.
      alias StyleFunc = Proc(Int32, Int32, Lipgloss::Style)

      # Option type for functional configuration (Go-style)
      alias Option = Proc(Table, Nil)

      struct Column
        getter title : String
        getter width : Int32

        def initialize(@title, @width)
        end
      end

      # Styles container for matching Go API
      class Styles
        property header : Lipgloss::Style
        property cell : Lipgloss::Style
        property selected : Lipgloss::Style

        def initialize(@header = Lipgloss::Style.new.bold(true).padding(0, 1),
                       @cell = Lipgloss::Style.new.padding(0, 1),
                       @selected = Lipgloss::Style.new.bold(true).foreground(Lipgloss::Color.indexed(212)))
        end
      end

      def self.default_styles : Styles
        Styles.new
      end

      alias Row = Array(String)

      property columns : Array(Column) = [] of Column
      property rows : Array(Row) = [] of Row
      property filter_text : String = ""
      property cursor : Int32 = 0
      property width : Int32 = 0
      # Total height including header + viewport. If 0, uses Bubble Tea defaults.
      property height : Int32 = 0
      property id : String = ""
      property? focus : Bool = false

      # Styles
      property styles : Styles = Styles.new

      # Legacy style properties mapped to styles object
      def header_style : Lipgloss::Style
        @styles.header
      end

      def header_style=(s : Lipgloss::Style)
        @styles.header = s
      end

      def cell_style : Lipgloss::Style
        @styles.cell
      end

      def cell_style=(s : Lipgloss::Style)
        @styles.cell = s
      end

      def selected_style : Lipgloss::Style
        @styles.selected
      end

      def selected_style=(s : Lipgloss::Style)
        @styles.selected = s
      end

      property style_func : StyleFunc? = nil

      # Lipgloss::Border configuration
      property border : Lipgloss::Border = Lipgloss::Border.new
      property border_style : Lipgloss::Style = Lipgloss::Style.new
      property border_top : Bool = false
      property border_bottom : Bool = false
      property border_left : Bool = false
      property border_right : Bool = false
      property border_header : Bool = false
      property border_column : Bool = false
      property border_row : Bool = false

      struct FilteredRow
        property index : Int32
        property row : Row
        property score : UInt16

        def initialize(@index, @row, @score)
        end
      end

      alias FilterFunc = Proc(String, Array(Row), Array(FilteredRow))

      @filtered_rows : Array(FilteredRow) = [] of FilteredRow

      # Components
      property viewport : Viewport
      property key_map : KeyMap
      property filter_func : FilterFunc = ->Table.default_filter(String, Array(Row))

      struct KeyMap
        getter line_up : Key::Binding
        getter line_down : Key::Binding
        getter page_up : Key::Binding
        getter page_down : Key::Binding
        getter half_page_up : Key::Binding
        getter half_page_down : Key::Binding
        getter goto_top : Key::Binding
        getter goto_bottom : Key::Binding

        def initialize
          @line_up = Key::Binding.new(["up", "k"], "up", "up")
          @line_down = Key::Binding.new(["down", "j"], "down", "down")
          @page_up = Key::Binding.new(["b", "pgup"], "b/pgup", "page up")
          @page_down = Key::Binding.new(["f", "pgdown", " "], "f/pgdn", "page down")
          @half_page_up = Key::Binding.new(["u", "ctrl+u"], "u", "½ page up")
          @half_page_down = Key::Binding.new(["d", "ctrl+d"], "d", "½ page down")
          @goto_top = Key::Binding.new(["home", "g"], "g/home", "go to start")
          @goto_bottom = Key::Binding.new(["end", "G"], "G/end", "go to end")
        end
      end

      def initialize(columns : Array(Column | Tuple(String, Int32)) = [] of Column, rows : Array(Row) = [] of Row, width : Int32 = 0, height : Int32 = 0, id : String = "")
        @columns = columns.map do |col|
          case col
          when Column
            col
          else
            Column.new(col[0], col[1])
          end
        end
        @rows = rows
        @width = width
        @height = height
        @id = id
        # Bubble Tea default viewport size: width 0, height 20.
        @viewport = Viewport.new(@width, 20)
        @key_map = KeyMap.new
        if @height > 0
          self.height = @height
        end
        update_viewport
      end

      def height=(h : Int32)
        @height = h
        header = render_header
        header_height = header.empty? ? 1 : Lipgloss::Text.height(header)
        @viewport.height = [h - header_height, 1].max
        update_viewport
      end

      # --- Builder API (Go-style) ---

      def self.build(*options : Option) : Table
        table = new
        options.each(&.call(table))
        table.update_viewport
        table
      end

      def self.with_columns(cols : Array(Column)) : Option
        ->(t : Table) { t.columns = cols; nil }
      end

      def self.with_rows(rows : Array(Row)) : Option
        ->(t : Table) { t.rows = rows; nil }
      end

      def self.with_height(h : Int32) : Option
        ->(t : Table) {
          t.height = h
          header = t.render_header
          header_height = header.empty? ? 1 : Lipgloss::Text.height(header)
          t.viewport.height = [h - header_height, 1].max
          nil
        }
      end

      def self.with_width(w : Int32) : Option
        ->(t : Table) {
          t.width = w
          t.viewport.width = w
          nil
        }
      end

      def self.with_styles(s : Styles) : Option
        ->(t : Table) { t.styles = s; nil }
      end

      # --- DSL API ---

      def self.new(width : Int32 = 0, height : Int32 = 0, & : Table -> Nil)
        instance = new([] of Column, [] of Row, width, height)
        yield instance
        instance.update_viewport
        instance
      end

      # --- Methods ---

      def column(title : String, width : Int32)
        @columns << Column.new(title, width)
      end

      def row(*values : String)
        @rows << values.to_a
      end

      def row(values : Array(String))
        @rows << values
      end

      def goto_top
        @cursor = 0
        update_viewport
      end

      def goto_bottom
        @cursor = [visible_rows.size - 1, 0].max
        update_viewport
      end

      def move_up(n : Int32)
        move_cursor(-n)
      end

      def move_down(n : Int32)
        move_cursor(n)
      end

      def focused? : Bool
        @focus
      end

      def focus
        @focus = true
      end

      def blur
        @focus = false
      end

      def rows=(rows : Array(Row))
        @rows = rows
        apply_filter
      end

      def columns=(columns : Array(Column))
        @columns = columns
        update_viewport
      end

      def selected_row : Row?
        visible_rows[@cursor]?
      end

      def update(msg : Msg) : {Table, Cmd}
        case msg
        when ZoneClickMsg
          if msg.id == @id
            focus
            clicked_row = @viewport.y_offset + msg.y - 1
            if clicked_row >= 0 && clicked_row < visible_rows.size
              @cursor = clicked_row
              update_viewport
            end
          end
        when KeyMsg
          if focused?
            handle_key(msg)
          end
        end
        {self, nil}
      end

      def handle_key(msg : KeyMsg)
        case
        when @key_map.line_up.matches?(msg)
          move_cursor(-1)
        when @key_map.line_down.matches?(msg)
          move_cursor(1)
        when @key_map.page_up.matches?(msg)
          move_cursor(-@viewport.height)
        when @key_map.page_down.matches?(msg)
          move_cursor(@viewport.height)
        when @key_map.half_page_up.matches?(msg)
          move_cursor(-(@viewport.height // 2))
        when @key_map.half_page_down.matches?(msg)
          move_cursor(@viewport.height // 2)
        when @key_map.goto_top.matches?(msg)
          goto_top
        when @key_map.goto_bottom.matches?(msg)
          goto_bottom
        end
      end

      def move_cursor(delta : Int32)
        @cursor = (@cursor + delta).clamp(0, [visible_rows.size - 1, 0].max)
        update_viewport
      end

      def filter_text=(text : String)
        @filter_text = text
        apply_filter
      end

      def visible_rows : Array(Row)
        return @rows if @filter_text.empty?
        @filtered_rows.map(&.row)
      end

      def self.default_filter(term : String, targets : Array(Row)) : Array(FilteredRow)
        return [] of FilteredRow if term.empty?

        ranks = [] of FilteredRow

        targets.each_with_index do |row, idx|
          target = row.join(" ")
          if score = Nucleoc.fuzzy_match(target, term)
            ranks << FilteredRow.new(idx, row, score)
          end
        end

        ranks.sort! do |a, b|
          score_comparison = b.score <=> a.score
          if score_comparison != 0
            score_comparison
          else
            a.index <=> b.index
          end
        end

        ranks
      end

      private def apply_filter
        if @filter_text.empty?
          @filtered_rows.clear
        else
          @filtered_rows = @filter_func.call(@filter_text, @rows)
        end
        @cursor = 0
        update_viewport
      end

      def update_viewport
        @viewport.width = @width if @width > 0

        rows_for_view = visible_rows
        rendered_rows = rows_for_view.map_with_index do |row, i|
          render_row(row, i, i == @cursor)
        end

        @viewport.content = rendered_rows.join("\n")

        if @cursor < @viewport.y_offset
          @viewport.y_offset = @cursor
        elsif @cursor >= @viewport.y_offset + @viewport.height
          @viewport.y_offset = @cursor - @viewport.height + 1
        end
      end

      private def get_cell_style(row_idx : Int32, col_idx : Int32, selected : Bool) : Lipgloss::Style
        if func = @style_func
          func.call(row_idx, col_idx)
        elsif row_idx == HEADER_ROW
          @styles.header
        else
          @styles.cell
        end
      end

      # Public for testing
      def render_row(row : Row, row_idx : Int32, selected : Bool) : String
        cells = [] of String

        row.each_with_index do |cell, col_idx|
          col = @columns[col_idx]?
          next unless col
          next if col.width <= 0

          inner = Lipgloss::Style.new.width(col.width).max_width(col.width).inline(true)
          content =
            if Lipgloss::Text.width(cell) > col.width && col.width > 1
              Lipgloss::Text.truncate(cell, col.width - 1) + "…"
            else
              cell
            end
          rendered_cell = inner.render(content)

          style = get_cell_style(row_idx, col_idx, selected)
          cells << style.render(rendered_cell)
        end

        row_content = Lipgloss::Style.join_horizontal(Lipgloss::Position::Top, cells)

        if selected
          row_content = @styles.selected.render(row_content)
        end

        if @border_left
          row_content = @border_style.render(@border.left) + row_content
        end
        if @border_right
          row_content = row_content + @border_style.render(@border.right)
        end

        row_content
      end

      def render_header : String
        cells = [] of String

        @columns.each_with_index do |col, col_idx|
          next if col.width <= 0
          inner = Lipgloss::Style.new.width(col.width).max_width(col.width).inline(true)
          content =
            if Lipgloss::Text.width(col.title) > col.width && col.width > 1
              Lipgloss::Text.truncate(col.title, col.width - 1) + "…"
            else
              col.title
            end
          rendered_cell = inner.render(content)

          style = get_cell_style(HEADER_ROW, col_idx, false)
          cells << style.render(rendered_cell)
        end

        row_content = Lipgloss::Style.join_horizontal(Lipgloss::Position::Top, cells)

        if @border_left
          row_content = @border_style.render(@border.left) + row_content
        end
        if @border_right
          row_content = row_content + @border_style.render(@border.right)
        end

        row_content
      end

      def view : View
        content = String.build do |io|
          # Header
          io << render_header << "\n"

          # Body
          io << @viewport.view.content
        end

        final_content = @id.empty? ? content : Zone.mark(@id, content)
        View.new(content: final_content)
      end
    end
  end
end
