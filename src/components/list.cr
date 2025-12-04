require "../term2"
require "./paginator"
require "./help"
require "./key"

module Term2
  module Components
    class List
      include Model

      # Enumerator generates the prefix for list items (bullets, numbers, etc.)
      # Takes the list items and current index, returns the prefix string.
      #
      # Example:
      # ```
      # list.enumerator = ->(items : Array(Item), i : Int32) { "#{i + 1}." }
      # ```
      alias Enumerator = Proc(Array(Item), Int32, String)

      # Predefined enumerators (matching Go Lipgloss)
      module Enumerators
        # Bullet enumeration: • Foo, • Bar, • Baz
        Bullet = ->(_items : Array(Item), _i : Int32) { "•" }

        # Dash enumeration: - Foo, - Bar, - Baz
        Dash = ->(_items : Array(Item), _i : Int32) { "-" }

        # Asterisk enumeration: * Foo, * Bar, * Baz
        Asterisk = ->(_items : Array(Item), _i : Int32) { "*" }

        # Arabic numeral enumeration: 1. Foo, 2. Bar, 3. Baz
        Arabic = ->(_items : Array(Item), i : Int32) { "#{i + 1}." }

        # Alphabet enumeration: A. Foo, B. Bar, C. Baz
        Alphabet = ->(_items : Array(Item), i : Int32) {
          abc_len = 26
          if i >= abc_len * abc_len + abc_len
            "#{('A'.ord + i // abc_len // abc_len - 1).chr}#{('A'.ord + (i // abc_len) % abc_len - 1).chr}#{('A'.ord + i % abc_len).chr}."
          elsif i >= abc_len
            "#{('A'.ord + i // abc_len - 1).chr}#{('A'.ord + i % abc_len).chr}."
          else
            "#{('A'.ord + i % abc_len).chr}."
          end
        }

        # Roman numeral enumeration: I. Foo, II. Bar, III. Baz
        Roman = ->(_items : Array(Item), idx : Int32) {
          roman = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
          arabic = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
          result = String.build do |s|
            n = idx + 1 # Roman numerals are 1-indexed
            roman.each_with_index do |r, j|
              while n >= arabic[j]
                n -= arabic[j]
                s << r
              end
            end
          end
          "#{result}."
        }

        # No enumeration (empty prefix)
        None = ->(_items : Array(Item), _i : Int32) { "" }
      end

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
        abstract def render(io : IO, item : Item, index : Int32, selected : Bool, enumerator : String)
        abstract def height : Int32
        abstract def spacing : Int32
        # abstract def update(msg : Message, model : List) : Cmd
      end

      class DefaultDelegate
        include ItemDelegate

        property selected_style : Style = Style.new.foreground(Color::MAGENTA)
        property normal_style : Style = Style.new
        property desc_style : Style = Style.new.faint(true)
        property enumerator_style : Style = Style.new

        def height : Int32
          2
        end

        def spacing : Int32
          1
        end

        def render(io : IO, item : Item, index : Int32, selected : Bool, enumerator : String)
          title_style = selected ? selected_style : normal_style
          cursor = selected ? "> " : "  "

          # Render enumerator with its style
          enum_str = enumerator.empty? ? "" : "#{@enumerator_style.render(enumerator)} "

          io << title_style.render("#{cursor}#{enum_str}#{item.title}")
          io << "\n"
          # Indent description to match enumerator width
          indent = "    " + (" " * enumerator.size)
          io << desc_style.render("#{indent}#{item.description}")
        end
      end

      property items : Array(Item)
      property index : Int32 = 0
      property width : Int32 = 20
      property height : Int32 = 10
      property id : String = "" # Zone ID for focus management
      property title : String = ""

      property paginator : Paginator
      property delegate : ItemDelegate

      property? show_title : Bool = true
      property? show_filter : Bool = true
      property? show_status_bar : Bool = true
      property? show_pagination : Bool = true
      property? show_help : Bool = true
      property? filtering_enabled : Bool = true
      property additional_full_help_keys : Proc(Array(Key::Binding))? = nil
      enum FilterState
        Unfiltered
        Filtering
        FilterApplied
      end

      property filter_state : FilterState = FilterState::Unfiltered
      property item_name_singular : String = "item"
      property item_name_plural : String = "items"
      property status_message : String = ""

      # Enumerator for list item prefixes (bullet, number, etc.)
      property enumerator : Enumerator = Enumerators::None

      # Key bindings
      property key_map : KeyMap

      struct KeyMap
        getter cursor_up : Key::Binding
        getter cursor_down : Key::Binding
        getter next_page : Key::Binding
        getter prev_page : Key::Binding
        getter toggle_filter : Key::Binding

        def initialize
          @cursor_up = Key::Binding.new(["up", "k"], "up", "up")
          @cursor_down = Key::Binding.new(["down", "j"], "down", "down")
          @next_page = Key::Binding.new(["right", "l", "pgdn"], "right", "next page")
          @prev_page = Key::Binding.new(["left", "h", "pgup"], "left", "prev page")
          @toggle_filter = Key::Binding.new(["/", "ctrl+f"], "/", "filter")
        end
      end

      def initialize(items : Array(Item) = [] of Item, width : Int32 = 20, height : Int32 = 10, id : String = "")
        @items = items
        @width = width
        @height = height
        @id = id
        @paginator = Paginator.new
        @delegate = DefaultDelegate.new
        @key_map = KeyMap.new
        update_pagination
      end

      # Overload for simple string lists
      def self.new(items : Array(String), width : Int32 = 20, height : Int32 = 10, id : String = "")
        list_items = items.map { |i| DefaultItem.new(i).as(Item) }
        new(list_items, width, height, id)
      end

      # Overload for title + description lists
      def self.new(items : Array({String, String}), width : Int32 = 20, height : Int32 = 10, id : String = "")
        list_items = items.map { |i| DefaultItem.new(i[0], i[1]).as(Item) }
        new(list_items, width, height, id)
      end

      # Fluent setter for enumerator
      def enumerator(enumerator_func : Enumerator) : self
        @enumerator = enumerator_func
        self
      end

      def items=(items : Array(Item))
        @items = items
        update_pagination
      end

      def selected_item : Item?
        @items[@index]?
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

      def update(msg : Msg) : {List, Cmd}
        case msg
        when ZoneClickMsg
          if msg.id == @id
            focus
            # Calculate which item was clicked based on y position
            item_height = @delegate.height + @delegate.spacing
            clicked_item_offset = msg.y // item_height
            start_idx, _ = @paginator.get_slice_bounds(@items.size)
            clicked_index = start_idx + clicked_item_offset
            if clicked_index < @items.size
              @index = clicked_index
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
        when @key_map.cursor_up.matches?(msg)
          cursor_up
        when @key_map.cursor_down.matches?(msg)
          cursor_down
        when @key_map.prev_page.matches?(msg)
          cursor_prev_page
        when @key_map.next_page.matches?(msg)
          cursor_next_page
        when @key_map.toggle_filter.matches?(msg)
          if @filtering_enabled
            toggle_filter
          end
        end
      end

      def toggle_filter
        @filter_state = case @filter_state
                        when FilterState::Unfiltered
                          FilterState::Filtering
                        when FilterState::Filtering
                          FilterState::FilterApplied
                        else
                          FilterState::Unfiltered
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
        @paginator.set_total_pages(@items.size)

        # Sync paginator page with index
        @paginator.page = @index // per_page
      end

      def view : String
        content = String.build do |io|
          if @show_title && !@title.empty?
            io << @title << "\n\n"
          end

          # Render items for current page
          start_idx, end_idx = @paginator.get_slice_bounds(@items.size)

          (start_idx...end_idx).each do |i|
            item = @items[i]
            # Generate enumerator prefix for this item
            enum_prefix = @enumerator.call(@items, i)
            @delegate.render(io, item, i, i == @index, enum_prefix)
            io << "\n" * @delegate.spacing
          end

          # Fill empty space?

          if @show_status_bar
            io << "\n" << status_view
          end

          # Paginator
          io << "\n" << @paginator.view
        end

        # Wrap with zone marker if we have an ID
        @id.empty? ? content : Zone.mark(@id, content)
      end

      def status_view : String
        count = @items.size
        label = if count == 1
                  @item_name_singular
                else
                  @item_name_plural
                end

        msg = if !@status_message.empty?
                @status_message
              elsif count == 0
                "No #{label}"
              else
                "#{count} #{label}"
              end
        msg
      end
    end
  end
end
