require "../term2"
require "./paginator"
require "./help"
require "./key"

module Term2
  module Components
    class List < Model
      module Item
        abstract def title : String
        abstract def description : String
        abstract def filter_value : String
      end

      struct DefaultItem
        include Item
        getter title : String
        getter description : String

        def initialize(@title, @description = "")
        end

        def filter_value : String
          title
        end
      end

      # Helper to create a DefaultItem easily
      def self.item(title : String, description : String = "")
        DefaultItem.new(title, description)
      end

      module ItemDelegate
        abstract def render(io : IO, item : Item, index : Int32, selected : Bool)
        abstract def height : Int32
        abstract def spacing : Int32
        # abstract def update(msg : Message, model : List) : Cmd
      end

      class DefaultDelegate
        include ItemDelegate

        property selected_style : Style = Style.new(foreground: Color::MAGENTA)
        property normal_style : Style = Style.new
        property desc_style : Style = Style.new(faint: true)

        def height : Int32
          2
        end

        def spacing : Int32
          1
        end

        def render(io : IO, item : Item, index : Int32, selected : Bool)
          title_style = selected ? selected_style : normal_style
          cursor = selected ? "> " : "  "

          io << title_style.apply("#{cursor}#{item.title}")
          io << "\n"
          io << desc_style.apply("    #{item.description}")
        end
      end

      property items : Array(Item)
      property index : Int32 = 0
      property width : Int32 = 20
      property height : Int32 = 10

      property paginator : Paginator
      property delegate : ItemDelegate

      # Key bindings
      property key_map : KeyMap

      struct KeyMap
        getter cursor_up : Key::Binding
        getter cursor_down : Key::Binding
        getter next_page : Key::Binding
        getter prev_page : Key::Binding

        def initialize
          @cursor_up = Key::Binding.new(["up", "k"], "up", "up")
          @cursor_down = Key::Binding.new(["down", "j"], "down", "down")
          @next_page = Key::Binding.new(["right", "l", "pgdn"], "right", "next page")
          @prev_page = Key::Binding.new(["left", "h", "pgup"], "left", "prev page")
        end
      end

      def initialize(items : Array(Item) = [] of Item, width : Int32 = 20, height : Int32 = 10)
        @items = items
        @width = width
        @height = height
        @paginator = Paginator.new
        @delegate = DefaultDelegate.new
        @key_map = KeyMap.new
        update_pagination
      end

      # Overload for simple string lists
      def self.new(items : Array(String), width : Int32 = 20, height : Int32 = 10)
        list_items = items.map { |i| DefaultItem.new(i).as(Item) }
        new(list_items, width, height)
      end

      # Overload for title + description lists
      def self.new(items : Array({String, String}), width : Int32 = 20, height : Int32 = 10)
        list_items = items.map { |i| DefaultItem.new(i[0], i[1]).as(Item) }
        new(list_items, width, height)
      end

      def items=(items : Array(Item))
        @items = items
        update_pagination
      end

      def selected_item : Item?
        @items[@index]?
      end

      def update(msg : Message) : {List, Cmd}
        case msg
        when KeyMsg
          handle_key(msg)
        end
        {self, Cmd.none}
      end

      def handle_key(msg : KeyMsg)
        case
        when @key_map.cursor_up.matches?(msg)
          cursor_up
        when @key_map.cursor_down.matches?(msg)
          cursor_down
        when @key_map.prev_page.matches?(msg)
          cursor_prev_page
        when @key_map.next_page.matches?(msg)
          cursor_next_page
        end
      end

      def cursor_up
        @index = (@index - 1).clamp(0, @items.size - 1)
        update_pagination
      end

      def cursor_down
        @index = (@index + 1).clamp(0, @items.size - 1)
        update_pagination
      end

      def cursor_prev_page
        @paginator.prev_page
        # Update index to be in the new page range?
        # Or just move index by per_page?
        @index = (@index - @paginator.per_page).clamp(0, @items.size - 1)
        update_pagination
      end

      def cursor_next_page
        @paginator.next_page
        @index = (@index + @paginator.per_page).clamp(0, @items.size - 1)
        update_pagination
      end

      def update_pagination
        # Calculate items per page based on height and delegate height
        item_height = @delegate.height + @delegate.spacing
        available_height = @height - 2 # Reserve space for header/footer?

        per_page = [1, available_height // item_height].max
        @paginator.per_page = per_page
        @paginator.total_pages = @items.size

        # Sync paginator page with index
        @paginator.page = @index // per_page
      end

      def view : String
        String.build do |io|
          # Render items for current page
          range = @paginator.items_on_page(@items.size)

          range.each do |i|
            item = @items[i]
            @delegate.render(io, item, i, i == @index)
            io << "\n" * @delegate.spacing
          end

          # Fill empty space?

          # Paginator
          io << "\n" << @paginator.view
        end
      end
    end
  end
end
