require "../term2"
require "./viewport"
require "./key"
require "./help"

module Term2
  module Bubbles
    class Table < Model
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
      property? focused : Bool = false
      property width : Int32 = 0
      property height : Int32 = 0

      # Styles
      property header_style : Style = Style.new(bold: true, underline: true)
      property selected_style : Style = Style.new(reverse: true)
      property cell_style : Style = Style.new

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

      def initialize(columns : Array(Column), rows : Array(Row), width : Int32 = 80, height : Int32 = 20)
        @columns = columns
        @rows = rows
        @width = width
        @height = height
        @viewport = Viewport.new(width, height - 2) # Reserve 2 lines for header?
        @key_map = KeyMap.new
        update_viewport
      end

      # Overload for easier initialization with tuples and arrays
      def initialize(columns : Array({String, Int32}), rows : Array(Array(String)), width : Int32 = 80, height : Int32 = 20)
        @columns = columns.map { |col| Column.new(col[0], col[1]) }
        @rows = rows
        @width = width
        @height = height
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

      def focus
        @focused = true
      end

      def blur
        @focused = false
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

      def update(msg : Message) : {Table, Cmd}
        case msg
        when KeyMsg
          if @focused
            handle_key(msg)
          end
        end
        {self, Cmd.none}
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
        # Render rows
        rendered_rows = @rows.map_with_index do |row, i|
          render_row(row, i == @cursor)
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

      def render_row(row : Row, selected : Bool) : String
        style = selected && @focused ? @selected_style : @cell_style

        cells = row.map_with_index do |cell, i|
          col = @columns[i]?
          width = col ? col.width : 10

          # Truncate or pad
          content = cell
          if content.size > width
            content = content[0...width]
          else
            content = content.ljust(width)
          end

          content
        end

        style.apply(cells.join(" "))
      end

      def render_header : String
        cells = @columns.map do |col|
          content = col.title
          if content.size > col.width
            content = content[0...col.width]
          else
            content = content.ljust(col.width)
          end
          content
        end

        @header_style.apply(cells.join(" "))
      end

      def view : String
        String.build do |io|
          io << render_header << "\n"
          io << @viewport.view
        end
      end
    end
  end
end
