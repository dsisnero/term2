require "../term2"
require "./paginator"
require "./help"
require "./key"
require "./text_input"
require "./spinner"
require "nucleoc"

module Term2
  module Components
    class List
      include Term2::Model

      # Item interface
      module Item
        abstract def filter_value : String
      end

      # Default Item implementation
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

      def self.items(ar : Array(Tuple(String, String))) : Array(Item)
        ar.map { |_, _| item(ar[0], ar[1]) }
      end

      # Helper to create a DefaultItem easily
      def self.item(title : String, description : String = "")
        DefaultItem.new(title, description).as(Item)
      end

      # Compatibility helper for older examples.
      def self.items(ar : Array(Tuple(String, String))) : Array(Item)
        ar.map { |(title, desc)| DefaultItem.new(title, desc).as(Item) }
      end

      # Delegate interface for rendering list items
      module ItemDelegate
        abstract def render(io : IO, model : List, index : Int32, item : Item)
        abstract def height : Int32
        abstract def spacing : Int32
        abstract def update(msg : Msg, model : List) : Cmd
      end

      # Default delegate implementation
      class DefaultDelegate
        include ItemDelegate

        property styles : DefaultItemStyles = DefaultItemStyles.new
        @enumerator_style : Style = Style.new

        # Compatibility with ports that expose delegate styles directly.
        def selected_style : Style
          @styles.selected_title
        end

        def selected_style=(s : Style)
          @styles.selected_title = s
        end

        def desc_style : Style
          @styles.normal_desc
        end

        def desc_style=(s : Style)
          @styles.normal_desc = s
          @styles.selected_desc = s
        end

        def enumerator_style : Style
          @enumerator_style
        end

        def enumerator_style=(s : Style)
          @enumerator_style = s
        end

        struct DefaultItemStyles
          property selected_title : Style = Style.new.border(Border.new(left: "│ "), false, false, false, true).border_foreground(Color::MAGENTA).foreground(Color::MAGENTA).bold(true)
          property selected_desc : Style = Style.new.border(Border.new(left: "│ "), false, false, false, true).border_foreground(Color::MAGENTA).foreground(Color::MAGENTA).faint(true)
          property normal_title : Style = Style.new.padding_left(2)
          property normal_desc : Style = Style.new.padding_left(2).faint(true)
        end

        def height : Int32
          2
        end

        def spacing : Int32
          0
        end

        def update(msg : Msg, model : List) : Cmd
          nil
        end

        def render(io : IO, model : List, index : Int32, item : Item)
          title = ""
          desc = ""

          if item.is_a?(DefaultItem)
            title = item.title
            desc = item.description
          else
            title = item.filter_value
          end

          if model.debug_mode?
            if score = model.score_for_item(index)
              title = "#{title} [score=#{score}]"
            end
          end

          if index == model.index
            io << styles.selected_title.render(title) << "\n"
            io << styles.selected_desc.render(desc)
          else
            io << styles.normal_title.render(title) << "\n"
            io << styles.normal_desc.render(desc)
          end
        end
      end

      # Filter rank result
      struct Rank
        property index : Int32
        property score : UInt16
        property matched_indexes : Array(Int32)

        def initialize(@index, @score, @matched_indexes)
        end
      end

      # Filter function type
      alias FilterFunc = Proc(String, Array(String), Array(Rank))

      # Fuzzy filter implementation using nucleoc library
      def self.default_filter(term : String, targets : Array(String)) : Array(Rank)
        return [] of Rank if term.empty?

        ranks = [] of Rank

        targets.each_with_index do |target, i|
          # Use nucleoc's fuzzy_match_indices to get both score and match indices
          if result = Nucleoc.fuzzy_match_indices(target, term)
            score, indices = result
            # Convert UInt32 indices to Int32 for compatibility
            int_indices = indices.map(&.to_i32)
            ranks << Rank.new(i, score, int_indices)
          end
        end

        # Sort by nucleoc score (higher is better), with tie-breaking by original index
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

      enum FilterState
        Unfiltered
        Filtering
        FilterApplied
      end

      # Styles for the list component
      class Styles
        property title : Style = Style.new.background(Color::MAGENTA).foreground(Color::WHITE).padding(0, 1)
        property title_bar : Style = Style.new.padding(0, 0, 1, 2)
        property status_bar : Style = Style.new.foreground(Color.indexed(240))
        property status_empty : Style = Style.new.foreground(Color.indexed(240))
        property status_bar_filter_count : Style = Style.new.foreground(Color.indexed(240))
        property pagination_style : Style = Style.new.padding_left(2)
        property help_style : Style = Style.new.padding(1, 0, 0, 2)
        property no_items : Style = Style.new.foreground(Color.indexed(240)).padding_left(2)

        # Filter input styles
        property filter_prompt : Style = Style.new.bold(true)
        property filter_cursor : Style = Style.new
        property default_filter_character_match : Style = Style.new.underline(true)
      end

      # KeyMap for the list
      class KeyMap
        property cursor_up : Key::Binding
        property cursor_down : Key::Binding
        property next_page : Key::Binding
        property prev_page : Key::Binding
        property go_to_start : Key::Binding
        property go_to_end : Key::Binding
        property filter : Key::Binding
        property clear_filter : Key::Binding
        property cancel_while_filtering : Key::Binding
        property accept_while_filtering : Key::Binding
        property show_full_help : Key::Binding
        property close_full_help : Key::Binding
        property quit : Key::Binding
        property force_quit : Key::Binding

        def initialize
          @cursor_up = Key::Binding.new(["up", "k"], "up", "up")
          @cursor_down = Key::Binding.new(["down", "j"], "down", "down")
          @next_page = Key::Binding.new(["right", "l", "pgdn"], "right", "next page")
          @prev_page = Key::Binding.new(["left", "h", "pgup"], "left", "prev page")
          @go_to_start = Key::Binding.new(["home", "g"], "g", "go to start")
          @go_to_end = Key::Binding.new(["end", "G"], "G", "go to end")
          @filter = Key::Binding.new(["/"], "/", "filter")
          @clear_filter = Key::Binding.new(["esc"], "esc", "clear filter")
          @cancel_while_filtering = Key::Binding.new(["esc"], "esc", "cancel")
          @accept_while_filtering = Key::Binding.new(["enter", "tab", "shift+tab", "ctrl+k", "up", "ctrl+j", "down"], "enter", "apply filter")
          @show_full_help = Key::Binding.new(["?"], "?", "more")
          @close_full_help = Key::Binding.new(["?"], "?", "close help")
          @quit = Key::Binding.new(["q"], "q", "quit")
          @force_quit = Key::Binding.new(["ctrl+c"], "ctrl+c", "quit")
        end
      end

      # --- Model State ---
      property? show_title : Bool = true
      property? show_filter : Bool = true
      property? show_status_bar : Bool = true
      property? show_pagination : Bool = true
      property? show_help : Bool = true
      property? filtering_enabled : Bool = true

      # [NEW] Status bar item naming
      property item_name_singular : String = "item"
      property item_name_plural : String = "items"

      property title : String = "List"
      property styles : Styles = Styles.new
      property key_map : KeyMap = KeyMap.new

      property width : Int32
      property height : Int32

      property items : Array(Item)

      # Stores filter results (index in original items, item, score, matches)
      struct FilteredItem
        property index : Int32
        property item : Item
        property score : UInt16
        property matches : Array(Int32)

        def initialize(@index, @item, @score, @matches); end
      end

      @filtered_items : Array(FilteredItem) = [] of FilteredItem

      property delegate : ItemDelegate
      property paginator : Paginator
      property help : Help
      property filter_input : TextInput
      property spinner : Spinner
      property status_message : String = ""
      property additional_full_help_keys : Proc(Array(Key::Binding)) = -> { [] of Key::Binding }

      getter filter_state : FilterState = FilterState::Unfiltered
      getter index : Int32 = 0 # Cursor index relative to current view (paginated)

      @[Deprecated("Use `filter_state=` instead")]
      def set_filter_state(state : FilterState)
        self.filter_state = state
      end

      def filter_state=(state : FilterState)
        @filter_state = state
        if @filter_state == FilterState::Unfiltered
          @filtered_items.clear
        else
          filter_items
        end
        update_keybindings
      end

      property filter_func : FilterFunc = ->List.default_filter(String, Array(String))
      property? infinite_scrolling : Bool = false

      def filtering_enabled=(enabled : Bool)
        @filtering_enabled = enabled
        if !enabled
          reset_filtering
        else
          update_pagination
          update_keybindings
        end
      end

      module Enumerators
        abstract struct Base
          abstract def value(index : Int32) : String
        end

        struct None < Base
          def value(index : Int32) : String
            ""
          end
        end

        struct Arabic < Base
          def value(index : Int32) : String
            "#{index + 1}."
          end
        end

        struct Bullet < Base
          def value(index : Int32) : String
            "•"
          end
        end

        struct Alphabet < Base
          ALPHABET = ("a".."z").to_a

          def value(index : Int32) : String
            idx = index % ALPHABET.size
            "#{ALPHABET[idx]}."
          end
        end

        struct Roman < Base
          def value(index : Int32) : String
            "#{to_roman(index + 1)}."
          end

          private def to_roman(num : Int32) : String
            vals = {1000 => "M", 900 => "CM", 500 => "D", 400 => "CD", 100 => "C", 90 => "XC", 50 => "L", 40 => "XL", 10 => "X", 9 => "IX", 5 => "V", 4 => "IV", 1 => "I"}
            n = num
            String.build do |io|
              vals.each do |val, sym|
                while n >= val
                  io << sym
                  n -= val
                end
              end
            end
          end
        end

        struct Dash < Base
          def value(index : Int32) : String
            "-"
          end
        end
      end

      property enumerator : Enumerators::Base = Enumerators::None.new

      # Allow setting enumerators by type (e.g. `List::Enumerators::Bullet`),
      # which matches how some ports express the Go API.
      def enumerator=(enumerator_type : T.class) forall T
        @enumerator = enumerator_type.new.as(Enumerators::Base)
      end

      @spinner_enabled : Bool = false

      def initialize(items : Array(Item) | Array(String) | Array(Tuple(String, String)), @width : Int32 = 0, @height : Int32 = 0)
        @items = items.map do |item|
          case item
          when Item
            item
          when Tuple(String, String)
            DefaultItem.new(item[0], item[1]).as(Item)
          else
            DefaultItem.new(item, "").as(Item)
          end
        end
        @delegate = DefaultDelegate.new
        @paginator = Paginator.new
        @paginator.type = Paginator::Type::Dots
        @help = Help.new
        @spinner = Spinner.new
        @status_message = ""
        @additional_full_help_keys = -> { [] of Key::Binding }
        @enumerator = Enumerators::None.new

        @filter_input = TextInput.new
        @filter_input.prompt = "Filter: "
        @filter_input.prompt_style = @styles.filter_prompt
        @filter_input.cursor_style = @styles.filter_cursor
        @filter_input.char_limit = 64
        @filter_input.focus

        update_pagination
        update_keybindings
      end

      # Adapter for Help component
      class HelpMap
        include Help::KeyMap

        def initialize(@key_map : KeyMap, @filter_state : FilterState, @extra : Array(Key::Binding))
        end

        def short_help : Array(Key::Binding)
          case @filter_state
          when FilterState::Filtering
            [
              @key_map.accept_while_filtering,
              @key_map.cancel_while_filtering,
              @key_map.force_quit,
            ]
          when FilterState::FilterApplied
            [
              @key_map.cursor_up,
              @key_map.cursor_down,
              @key_map.prev_page,
              @key_map.next_page,
              @key_map.clear_filter,
              @key_map.quit,
            ]
          else
            [
              @key_map.cursor_up,
              @key_map.cursor_down,
              @key_map.prev_page,
              @key_map.next_page,
              @key_map.filter,
              @key_map.quit,
            ]
          end
        end

        def full_help : Array(Array(Key::Binding))
          [
            [@key_map.cursor_up, @key_map.cursor_down, @key_map.prev_page, @key_map.next_page],
            [@key_map.filter, @key_map.clear_filter, @key_map.accept_while_filtering, @key_map.cancel_while_filtering],
            [@key_map.show_full_help, @key_map.close_full_help],
            [@key_map.quit, @key_map.force_quit],
            @extra,
          ]
        end
      end

      # Convenience constructor for string items
      def self.new(items : Array(String), width : Int32, height : Int32)
        list_items = items.map { |i| DefaultItem.new(i).as(Item) }
        new(list_items, width, height)
      end

      def init : Cmd
        nil
      end

      # Insert an item at the front of the list (Go: InsertItem(0, item)).
      def add_item_front(item : Item) : Nil
        @items.unshift(item)
        if @filter_state != FilterState::Unfiltered
          filter_items
        end
        update_pagination
        update_keybindings
      end

      @[Deprecated("Use `items=` instead")]
      def set_items(items : Array(Item))
        self.items = items
      end

      def items=(items : Array(Item))
        @items = items
        if @filter_state != FilterState::Unfiltered
          filter_items
        end
        update_pagination
        update_keybindings
      end

      def visible_items : Array(Item)
        if @filter_state != FilterState::Unfiltered
          @filtered_items.map(&.item)
        else
          @items
        end
      end

      # [NEW] Helper to set filter text programmatically
      def filter_text=(text : String)
        @filter_input.set_value(text)
        @filter_state = FilterState::FilterApplied
        filter_items
      end

      # [NEW] Alias for filter_input.value=
      def filter_value=(text : String)
        @filter_input.set_value(text)
        # Note: This doesn't auto-apply state like filter_text= does, usually used in setup
      end

      # [NEW] Helper to get matches for an item index (visual index)
      def matches_for_item(index : Int32) : Array(Int32)
        return [] of Int32 if @filter_state == FilterState::Unfiltered

        if filtered_index = filtered_index_for(index)
          @filtered_items[filtered_index].matches
        else
          [] of Int32
        end
      end

      def score_for_item(index : Int32) : UInt16?
        return nil if @filter_state == FilterState::Unfiltered

        if filtered_index = filtered_index_for(index)
          @filtered_items[filtered_index].score
        end
      end

      def debug_mode? : Bool
        !!ENV["TERM2_DEBUG"]?
      end

      # [NEW] Helper to toggle filter state (for testing/shortcuts)
      def toggle_filter
        case @filter_state
        when FilterState::Unfiltered
          @filter_state = FilterState::Filtering
        when FilterState::Filtering
          @filter_state = FilterState::FilterApplied
        when FilterState::FilterApplied
          @filter_state = FilterState::Unfiltered
          @filter_input.reset
          @filtered_items.clear
        end
        update_keybindings
      end

      # [NEW] Expose status view for testing
      def status_view : String
        # Generate status string similar to view()
        count = visible_items.size
        name = count == 1 ? @item_name_singular : @item_name_plural
        "#{count} #{name}"
      end

      # Current selected item
      def selected_item : Item?
        i = global_index
        return if i < 0 || i >= @items.size
        @items[i]
      end

      # Index in the unfiltered list
      def global_index : Int32
        # Calculate visual index across all pages
        visual_index = @paginator.page * @paginator.per_page + @index

        if @filter_state != FilterState::Unfiltered
          return -1 if visual_index >= @filtered_items.size
          @filtered_items[visual_index].index
        else
          visual_index
        end
      end

      def update(msg : Msg) : {List, Cmd}
        cmds = [] of Cmd

        # Handle spinner ticks
        if msg.is_a?(Spinner::TickMsg)
          new_spinner, spin_cmd = @spinner.update(msg)
          @spinner = new_spinner
          if @spinner_enabled
            cmds << spin_cmd
          end
          return {self, Cmds.batch(cmds)}
        end

        # Handle key bindings
        if msg.is_a?(KeyMsg)
          if @key_map.force_quit.matches?(msg)
            return {self, Term2.quit}
          end
        end

        if @filter_state == FilterState::Filtering
          cmd = handle_filtering(msg)
          cmds << cmd if cmd
        else
          cmd = handle_browsing(msg)
          cmds << cmd if cmd
        end

        # FIX: Use Term2::Cmds.batch to properly handle Array(Cmd)
        {self, Term2::Cmds.batch(cmds)}
      end

      def toggle_spinner : Cmd
        @spinner_enabled = !@spinner_enabled
        if @spinner_enabled
          @spinner.frame_index = 0
          @spinner.tick
        else
          Cmds.none
        end
      end

      private def handle_browsing(msg : Msg) : Cmd
        cmd : Cmd = nil

        if msg.is_a?(KeyMsg)
          case true
          when @key_map.cursor_up.matches?(msg)
            cursor_up_internal
          when @key_map.cursor_down.matches?(msg)
            cursor_down_internal
          when @key_map.prev_page.matches?(msg)
            @paginator.prev_page
            # Clamp cursor to new page items
            @index = @index.clamp(0, items_on_current_page - 1)
          when @key_map.next_page.matches?(msg)
            @paginator.next_page
            @index = @index.clamp(0, items_on_current_page - 1)
          when @key_map.filter.matches?(msg)
            @filter_state = FilterState::Filtering
            @filter_input.focus
            @filter_input.cursor_end
            update_keybindings
            return TextInput.blink
          when @key_map.clear_filter.matches?(msg)
            reset_filtering
          when @key_map.quit.matches?(msg)
            return Term2.quit
          end
        end

        cmd
      end

      private def handle_filtering(msg : Msg) : Cmd
        if msg.is_a?(KeyMsg)
          case true
          when @key_map.cancel_while_filtering.matches?(msg)
            reset_filtering
            return
          when @key_map.accept_while_filtering.matches?(msg)
            @filter_input.blur
            @filter_state = FilterState::FilterApplied
            update_keybindings
            if @filter_input.value.empty?
              reset_filtering
            end
            return
          end
        end

        previous_value = @filter_input.value
        new_input, cmd = @filter_input.update(msg)
        @filter_input = new_input.as(TextInput)
        input_changed = previous_value != @filter_input.value

        if input_changed
          filter_items
        end

        cmd
      end

      # Move the cursor up by one item.
      # Public for Bubble Tea parity (Go: `CursorUp()`).
      def cursor_up : Nil
        cursor_up_internal
      end

      # Move the cursor down by one item.
      # Public for Bubble Tea parity (Go: `CursorDown()`).
      def cursor_down : Nil
        cursor_down_internal
      end

      # Select an item in the currently visible page by its index.
      # Public for Bubble Tea parity (Go: `Select(i)` where `i` is in `VisibleItems()`).
      def select(i : Int32) : Nil
        count = items_on_current_page
        return if count <= 0
        @index = i.clamp(0, count - 1)
      end

      private def cursor_up_internal
        @index -= 1
        if @index < 0
          if @paginator.on_first_page?
            if @infinite_scrolling
              @paginator.page = @paginator.total_pages - 1
              @index = items_on_current_page - 1
            else
              @index = 0
            end
          else
            @paginator.prev_page
            @index = items_on_current_page - 1
          end
        end
      end

      private def cursor_down_internal
        items_on_page = items_on_current_page
        @index += 1
        if @index >= items_on_page
          if @paginator.on_last_page?
            if @infinite_scrolling
              @paginator.page = 0
              @index = 0
            else
              @index = items_on_page - 1
            end
          else
            @paginator.next_page
            @index = 0
          end
        end
      end

      private def items_on_current_page
        len = visible_items.size
        return 0 if len == 0
        @paginator.items_on_page(len)
      end

      private def filtered_index_for(index : Int32) : Int32?
        return nil if index < 0
        return nil if @filter_state == FilterState::Unfiltered

        offset = @paginator.page * @paginator.per_page
        filtered_index = offset + index
        return nil if filtered_index < 0 || filtered_index >= @filtered_items.size

        filtered_index
      end

      def disable_quit_keybindings
        @key_map.quit.set_enabled(false)
        @key_map.force_quit.set_enabled(false)
      end

      def reset_selected
        @index = 0
        @paginator.page = 0
        update_pagination
      end

      @[Deprecated("Use `show_help=` instead")]
      def set_show_help(show : Bool)
        self.show_help = show
      end

      def show_help=(show : Bool)
        @show_help = show
        update_pagination
      end

      private def filter_items
        val = @filter_input.value
        if val.empty?
          @filtered_items = [] of FilteredItem
          return
        end

        targets = @items.map(&.filter_value)
        ranks = @filter_func.call(val, targets)

        @filtered_items = ranks.map do |rank|
          FilteredItem.new(rank.index, @items[rank.index], rank.score, rank.matched_indexes)
        end

        @paginator.page = 0
        @index = 0
        update_pagination
      end

      private def reset_filtering
        @filter_state = FilterState::Unfiltered
        @filter_input.reset
        @filtered_items.clear
        update_pagination
        update_keybindings
      end

      private def update_keybindings
        is_filtering = @filter_state == FilterState::Filtering
        filtering_allowed = @filtering_enabled && @show_filter

        @key_map.cursor_up.set_enabled(!is_filtering)
        @key_map.cursor_down.set_enabled(!is_filtering)
        @key_map.filter.set_enabled(!is_filtering && filtering_allowed)
        @key_map.quit.set_enabled(!is_filtering)

        @key_map.clear_filter.set_enabled(filtering_allowed && @filter_state == FilterState::FilterApplied)
        @key_map.cancel_while_filtering.set_enabled(is_filtering && filtering_allowed)
        @key_map.accept_while_filtering.set_enabled(is_filtering && filtering_allowed)
      end

      def height=(h : Int32)
        @height = h
        update_pagination
      end

      private def update_pagination
        avail_height = @height

        if @show_title || (@show_filter && @filtering_enabled)
          avail_height -= 2
        end
        if @show_status_bar
          avail_height -= 1
        end
        if @show_pagination
          avail_height -= 1
        end
        if @show_help
          avail_height -= 1
        end

        item_height = @delegate.height + @delegate.spacing
        per_page =
          if @height <= 0
            # When height is not set, default to showing all items (no pagination).
            [1, visible_items.size].max
          else
            [1, avail_height // item_height].max
          end

        @paginator.per_page = per_page
        @paginator.set_total_pages(visible_items.size)

        if @index >= per_page
          @index = per_page - 1
        end
      end

      def view : String
        return "" if @width == 0

        sections = [] of String

        if @show_title || (@show_filter && @filtering_enabled)
          if @filter_state == FilterState::Filtering || (@show_filter && !@filter_input.value.empty?)
            sections << @styles.title_bar.render(@filter_input.view)
          else
            sections << @styles.title_bar.render(@styles.title.render(@title))
          end
        end

        # Status Bar
        if @show_status_bar
          count = visible_items.size
          name = count == 1 ? @item_name_singular : @item_name_plural
          status =
            if !@status_message.empty?
              @status_message
            elsif count == 0
              "No #{@item_name_plural}"
            else
              "#{count} #{name}"
            end
          spinner_str = @spinner_enabled ? @spinner.view : ""
          status_out = spinner_str.empty? ? status : "#{spinner_str} #{status}"
          style = count == 0 ? @styles.status_empty : @styles.status_bar
          sections << style.render(status_out)
        end

        content = String.build do |io|
          items = visible_items
          if items.empty?
            io << @styles.no_items.render("No items.")
          else
            start_idx, end_idx = @paginator.get_slice_bounds(items.size)
            page_items = items[start_idx...end_idx]

            page_items.each_with_index do |item, i|
              @delegate.render(io, self, i, item)
              if i < page_items.size - 1
                io << "\n" * (@delegate.spacing + 1)
              end
            end
          end
        end
        sections << content

        if @show_pagination
          sections << @styles.pagination_style.render(@paginator.view)
        end

        if @show_help
          help_map = HelpMap.new(@key_map, @filter_state, @additional_full_help_keys.call)
          help_keys = @help.view(help_map)
          sections << @styles.help_style.render(help_keys)
        end

        Style.join_vertical(Position::Left, sections)
      end
    end
  end
end
