require "../term2"
require "./viewport"
require "./key"
require "./help"

module Term2
  module Components
    class Table
      include Model

      # HeaderRow constant used in StyleFunc to identify the header row
      HEADER_ROW = -1

      # StyleFunc determines the style of a cell based on row and column position.
      # Row -1 (HEADER_ROW) indicates the header row.
      #
      # Example:
      # ```
      # table.style_func = ->(row : Int32, col : Int32) {
      #   case row
      #   when Table::HEADER_ROW
      #     Style.new.bold(true).foreground(Color::CYAN)
      #   when .even?
      #     Style.new.background(Color.new(Color::Type::Indexed, 236))
      #   else
      #     Style.new
      #   end
      # }
      # ```
      alias StyleFunc = Proc(Int32, Int32, Style)

      struct Column
        getter title : String
        getter width : Int32

        def initialize(@title, @width)
        end
      end

      alias Row = Array(String)

      property columns : Array(Column)
      property rows : Array(Row)
      property cursor : Int32 = 0
      property width : Int32 = 0
      property height : Int32 = 0
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

      struct KeyMap
        getter line_up : Key::Binding
        getter line_down : Key::Binding
        getter page_up : Key::Binding
        getter page_down : Key::Binding
        getter goto_top : Key::Binding
        getter goto_bottom : Key::Binding

        def initialize
          @line_up = Key::Binding.new(["up", "k"], "up", "up")
          @line_down = Key::Binding.new(["down", "j"], "down", "down")
          @page_up = Key::Binding.new(["pgup", "b"], "pgup", "page up")
          @page_down = Key::Binding.new(["pgdown", "f", "space"], "pgdn", "page down")
          @goto_top = Key::Binding.new(["home", "g"], "home", "go to top")
          @goto_bottom = Key::Binding.new(["end", "G"], "end", "go to bottom")
        end
      end

      def initialize(columns : Array(Column), rows : Array(Row), width : Int32 = 80, height : Int32 = 20, id : String = "")
        @columns = columns
        @rows = rows
        @width = width
        @height = height
        @id = id
        @viewport = Viewport.new(width, height - 2) # Reserve 2 lines for header?
        @key_map = KeyMap.new
        update_viewport
      end

      # Overload for easier initialization with tuples and arrays
      def initialize(columns : Array({String, Int32}), rows : Array(Array(String)), width : Int32 = 80, height : Int32 = 20, id : String = "")
        @columns = columns.map { |col| Column.new(col[0], col[1]) }
        @rows = rows
        @width = width
        @height = height
        @id = id
        @viewport = Viewport.new(width, height - 2)
        @key_map = KeyMap.new
        update_viewport
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

      def column(title : String, width : Int32)
        @columns << Column.new(title, width)
      end

      def row(*values : String)
        @rows << values.to_a
      end

      def row(values : Array(String))
        @rows << values
      end

      # Fluent setters for border configuration
      def border(border : Border) : self
        @border = border
        self
      end

      def border_style(style : Style) : self
        @border_style = style
        self
      end

      def border_top(v : Bool) : self
        @border_top = v
        self
      end

      def border_bottom(v : Bool) : self
        @border_bottom = v
        self
      end

      def border_left(v : Bool) : self
        @border_left = v
        self
      end

      def border_right(v : Bool) : self
        @border_right = v
        self
      end

      def border_header(v : Bool) : self
        @border_header = v
        self
      end

      def border_column(v : Bool) : self
        @border_column = v
        self
      end

      def border_row(v : Bool) : self
        @border_row = v
        self
      end

      # Enable all borders at once with a specific border style
      def bordered(border : Border = Border.rounded) : self
        @border = border
        @border_top = true
        @border_bottom = true
        @border_left = true
        @border_right = true
        @border_header = true
        @border_column = true
        self
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
        @cursor = 0
        update_viewport
      end

      def columns=(columns : Array(Column))
        @columns = columns
        update_viewport
      end

      def selected_row : Row?
        @rows[@cursor]?
      end

      def update(msg : Msg) : {Table, Cmd}
        case msg
        when ZoneClickMsg
          if msg.id == @id
            focus
            # Calculate which row was clicked based on y position (offset by header)
            clicked_row = @viewport.y_offset + msg.y - 1 # -1 for header
            if clicked_row >= 0 && clicked_row < @rows.size
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
        when @key_map.goto_top.matches?(msg)
          @cursor = 0
          update_viewport
        when @key_map.goto_bottom.matches?(msg)
          @cursor = [@rows.size - 1, 0].max
          update_viewport
        end
      end

      def move_cursor(delta : Int32)
        @cursor = (@cursor + delta).clamp(0, [@rows.size - 1, 0].max)
        update_viewport
      end

      def update_viewport
        # Render rows without borders (borders applied in view)
        rendered_rows = @rows.map_with_index do |row, i|
          render_row(row, i, i == @cursor)
        end

        @viewport.content = rendered_rows.join("\n")

        # Scroll viewport to keep cursor visible
        # Viewport handles scrolling by lines.
        # We need to map cursor index to viewport y_offset.

        if @cursor < @viewport.y_offset
          @viewport.y_offset = @cursor
        elsif @cursor >= @viewport.y_offset + @viewport.height
          @viewport.y_offset = @cursor - @viewport.height + 1
        end
      end

      # Get style for a cell, using style_func if set, otherwise defaults
      private def get_cell_style(row_idx : Int32, col_idx : Int32, selected : Bool) : Style
        if func = @style_func
          func.call(row_idx, col_idx)
        elsif row_idx == HEADER_ROW
          @header_style
        elsif selected && focused?
          @selected_style
        else
          @cell_style
        end
      end

      def render_row(row : Row, row_idx : Int32, selected : Bool) : String
        separator = @border_column ? @border_style.render(@border.middle) : " "

        cells = row.map_with_index do |cell, col_idx|
          col = @columns[col_idx]?
          width = col ? col.width : 10

          # Truncate or pad
          content = cell
          if content.size > width
            content = content[0...width]
          else
            content = content.ljust(width)
          end

          style = get_cell_style(row_idx, col_idx, selected)
          style.render(content)
        end

        row_content = cells.join(separator)

        # Add left/right borders
        if @border_left
          row_content = @border_style.render(@border.left) + row_content
        end
        if @border_right
          row_content = row_content + @border_style.render(@border.right)
        end

        row_content
      end

      def render_header : String
        separator = @border_column ? @border_style.render(@border.middle) : " "

        cells = @columns.map_with_index do |col, col_idx|
          content = col.title
          if content.size > col.width
            content = content[0...col.width]
          else
            content = content.ljust(col.width)
          end

          style = get_cell_style(HEADER_ROW, col_idx, false)
          style.render(content)
        end

        row_content = cells.join(separator)

        # Add left/right borders
        if @border_left
          row_content = @border_style.render(@border.left) + row_content
        end
        if @border_right
          row_content = row_content + @border_style.render(@border.right)
        end

        row_content
      end

      # Calculate total width of a row (for border rendering)
      private def calculate_row_width : Int32
        col_widths = @columns.sum(&.width)
        separator_count = @columns.size - 1
        separator_width = @border_column ? 1 : 1 # Either border char or space
        col_widths + (separator_count * separator_width)
      end

      # Render top border line
      private def render_top_border : String
        return "" unless @border_top

        width = calculate_row_width
        line = @border.top * width

        result = ""
        result += @border.top_left if @border_left
        result += line
        result += @border.top_right if @border_right

        @border_style.render(result)
      end

      # Render bottom border line
      private def render_bottom_border : String
        return "" unless @border_bottom

        width = calculate_row_width
        line = @border.bottom * width

        result = ""
        result += @border.bottom_left if @border_left
        result += line
        result += @border.bottom_right if @border_right

        @border_style.render(result)
      end

      # Render header separator line
      private def render_header_separator : String
        return "" unless @border_header

        width = calculate_row_width
        line = @border.top * width

        result = ""
        result += @border.middle_left if @border_left
        result += line
        result += @border.middle_right if @border_right

        @border_style.render(result)
      end

      def view : String
        content = String.build do |io|
          # Top border
          top = render_top_border
          io << top << "\n" unless top.empty?

          # Header
          io << render_header << "\n"

          # Header separator
          sep = render_header_separator
          io << sep << "\n" unless sep.empty?

          # Body (via viewport)
          io << @viewport.view

          # Bottom border
          bottom = render_bottom_border
          io << "\n" << bottom unless bottom.empty?
        end

        # Wrap with zone marker if we have an ID
        @id.empty? ? content : Zone.mark(@id, content)
      end
    end
  end
end
