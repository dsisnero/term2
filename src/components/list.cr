require "../term2"
require "./paginator"
require "./help"
require "./key"
require "./text_input"
require "./spinner"

module Term2
  module Components
    class List
      include Model
      include Help::KeyMap

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

      # Ranking result for filters (parity with Bubble Tea's Rank struct)
      struct Rank
        getter index : Int32
        getter matched_indexes : Array(Int32)

        def initialize(@index : Int32, @matched_indexes : Array(Int32))
        end
      end

      alias FilterFunc = Proc(String, Array(String), Array(Rank))

      # Internal filtered item record for preserving original index and matches
      struct FilteredItem
        getter index : Int32
        getter item : Item
        getter matches : Array(Int32)

        def initialize(@index, @item, @matches = [] of Int32)
        end
      end

      # Message used to clear status message after a timeout
      class StatusMessageTimeoutMsg < Message
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

        # Optional method to render with filter match metadata; defaults to render.
        def render_with_matches(io : IO, item : Item, index : Int32, selected : Bool, enumerator : String, matches : Array(Int32))
          render(io, item, index, selected, enumerator)
        end

        # Optional update hook; defaults to no-op.
        def update(_msg : Msg, _model : List) : Cmd
          Cmds.none
        end
      end

      # Example custom delegate for single-line rows with icons.
      #
      # ```
      # class IconDelegate
      #   include Term2::Components::List::ItemDelegate
      #
      #   def initialize(@icons : Array(String)); end
      #
      #   def height : Int32; 1; end
      #   def spacing : Int32; 0; end
      #
      #   def render(io : IO, item : Item, index : Int32, selected : Bool, enumerator : String)
      #     icon = @icons[index % @icons.size]?
      #     style = selected ? Style.new.bold(true).cyan : Style.new
      #     enum = enumerator.empty? ? "" : "#{enumerator} "
      #     io << style.render("#{icon} #{enum}#{item.title}")
      #   end
      # end
      #
      # list = Term2::Components::List.new(["Alpha", "Bravo", "Charlie"])
      # list.delegate = IconDelegate.new(["🌟", "📦", "🎯"])
      # ```

      class DefaultDelegate
        include ItemDelegate

        property selected_style : Style = Style.new.foreground(Color::MAGENTA)
        property normal_style : Style = Style.new
        property desc_style : Style = Style.new.faint(true)
        property enumerator_style : Style = Style.new
        property match_style : Style = Style.new.underline(true)

        def height : Int32
          2
        end

        def spacing : Int32
          1
        end

        def render_with_matches(io : IO, item : Item, index : Int32, selected : Bool, enumerator : String, matches : Array(Int32))
          title_style = selected ? selected_style : normal_style
          cursor = selected ? "> " : "  "

          # Render enumerator with its style
          enum_str = enumerator.empty? ? "" : "#{@enumerator_style.render(enumerator)} "

          highlighted = highlight(item.title, matches)
          io << title_style.render("#{cursor}#{enum_str}#{highlighted}")
          io << "\n"
          # Indent description to match enumerator width
          indent = "    " + (" " * enumerator.size)
          io << desc_style.render("#{indent}#{item.description}")
        end

        def render(io : IO, item : Item, index : Int32, selected : Bool, enumerator : String)
          render_with_matches(io, item, index, selected, enumerator, [] of Int32)
        end

        private def highlight(text : String, matches : Array(Int32)) : String
          return text if matches.empty?
          String.build do |s|
            text.chars.each_with_index do |ch, idx|
              if matches.includes?(idx)
                s << match_style.render(ch.to_s)
              else
                s << ch
              end
            end
          end
        end
      end

      # Visual styles for the list component (mirrors Bubble Tea's style struct)
      struct Styles
        property title_bar : Style
        property title : Style
        property spinner : Style
        property filter_prompt : Style
        property filter_cursor : Style
        property status_bar : Style
        property status_empty : Style
        property status_bar_filter_count : Style
        property no_items : Style
        property pagination_style : Style
        property help_style : Style
        property active_pagination_dot : Style
        property inactive_pagination_dot : Style
        property arabic_pagination : Style
        property divider_dot : Style
        property default_filter_character_match : Style

        def initialize(@title_bar, @title, @spinner, @filter_prompt, @filter_cursor,
                       @status_bar, @status_empty, @status_bar_filter_count, @no_items,
                       @pagination_style, @help_style, @active_pagination_dot,
                       @inactive_pagination_dot, @arabic_pagination, @divider_dot,
                       @default_filter_character_match)
        end

        def self.default : Styles
          subdued = Style.new.foreground(Color::BRIGHT_BLACK)
          very_subdued = Style.new.foreground(Color::BRIGHT_BLACK).faint(true)

          title_bar = Style.new.padding(0, 0, 1, 2)
          title = Style.new.background(Color::BLUE).foreground(Color::WHITE).padding(0, 1)
          spinner = Style.new.foreground(Color::BRIGHT_BLACK)
          filter_prompt = Style.new.foreground(Color::GREEN)
          filter_cursor = Style.new.foreground(Color::MAGENTA)

          status_bar = Style.new.foreground(Color::BRIGHT_BLACK).padding(0, 0, 1, 2)
          status_empty = Style.new.foreground(Color::BRIGHT_BLACK)
          status_bar_filter_count = very_subdued

          no_items = Style.new.foreground(Color::BRIGHT_BLACK)
          pagination_style = Style.new.padding_left(2)
          help_style = Style.new.padding(1, 0, 0, 2)
          active_dot = Style.new.foreground(Color::BRIGHT_MAGENTA)
          inactive_dot = very_subdued
          arabic = Style.new.foreground(Color::BRIGHT_BLACK)
          divider = very_subdued
          filter_match = Style.new.underline(true)

          Styles.new(
            title_bar: title_bar,
            title: title,
            spinner: spinner,
            filter_prompt: filter_prompt,
            filter_cursor: filter_cursor,
            status_bar: status_bar,
            status_empty: status_empty,
            status_bar_filter_count: status_bar_filter_count,
            no_items: no_items,
            pagination_style: pagination_style,
            help_style: help_style,
            active_pagination_dot: active_dot,
            inactive_pagination_dot: inactive_dot,
            arabic_pagination: arabic,
            divider_dot: divider,
            default_filter_character_match: filter_match,
          )
        end
      end

      property items : Array(Item)
      property index : Int32 = 0
      property width : Int32 = 20
      property height : Int32 = 10
      property id : String = "" # Zone ID for focus management
      property title : String = ""
      @all_items : Array(Item)
      @filtered_items : Array(FilteredItem)

      property paginator : Paginator
      property delegate : ItemDelegate
      property filter_input : TextInput
      property spinner : Spinner
      property help : Help

      property? show_title : Bool = true
      property? show_filter : Bool = true
      property? show_status_bar : Bool = true
      property? show_pagination : Bool = true
      property? show_help : Bool = true
      property? filtering_enabled : Bool = true
      property additional_full_help_keys : Proc(Array(Key::Binding))? = nil
      property additional_short_help_keys : Proc(Array(Key::Binding))? = nil
      enum FilterState
        Unfiltered
        Filtering
        FilterApplied
      end

      property filter_state : FilterState = FilterState::Unfiltered
      property item_name_singular : String = "item"
      property item_name_plural : String = "items"
      property status_message : String = ""
      property status_message_lifetime : Time::Span = 1.second
      property? show_spinner : Bool = false
      property styles : Styles = Styles.default
      property? infinite_scrolling : Bool = false
      property? disable_quit_keybindings : Bool = false

      # Enumerator for list item prefixes (bullet, number, etc.)
      property enumerator : Enumerator = Enumerators::None

      # Filter text/value (case-insensitive match against Item#filter_value)
      property filter_value : String = ""

      # Key bindings
      property key_map : KeyMap
      property filter : FilterFunc = ->(term : String, targets : Array(String)) { List.default_filter(term, targets) }

      struct KeyMap
        getter cursor_up : Key::Binding
        getter cursor_down : Key::Binding
        getter next_page : Key::Binding
        getter prev_page : Key::Binding
        getter go_to_start : Key::Binding
        getter go_to_end : Key::Binding
        getter toggle_filter : Key::Binding
        getter clear_filter : Key::Binding
        getter accept_filter : Key::Binding
        getter cancel_filter : Key::Binding
        getter show_full_help : Key::Binding
        getter close_full_help : Key::Binding
        getter quit : Key::Binding
        getter force_quit : Key::Binding

        def initialize
          @cursor_up = Key::Binding.new(["up", "k"], "up", "up")
          @cursor_down = Key::Binding.new(["down", "j"], "down", "down")
          @next_page = Key::Binding.new(["right", "l", "pgdn"], "right", "next page")
          @prev_page = Key::Binding.new(["left", "h", "pgup"], "left", "prev page")
          @toggle_filter = Key::Binding.new(["/", "ctrl+f"], "/", "filter")
          @clear_filter = Key::Binding.new(["esc"], "esc", "clear filter")
          @accept_filter = Key::Binding.new(["enter", "tab"], "enter", "apply filter")
          @cancel_filter = Key::Binding.new(["esc"], "esc", "cancel")
          @go_to_start = Key::Binding.new(["home", "g"], "home/g", "go to start")
          @go_to_end = Key::Binding.new(["end", "G"], "end/G", "go to end")
          @show_full_help = Key::Binding.new(["?"], "?", "more")
          @close_full_help = Key::Binding.new(["?"], "?", "close help")
          @quit = Key::Binding.new(["q", "esc"], "q", "quit")
          @force_quit = Key::Binding.new(["ctrl+c"], "ctrl+c", "quit")
        end
      end

      def initialize(items : Array(Item) = [] of Item, width : Int32 = 20, height : Int32 = 10, id : String = "")
        @items = items
        @all_items = items.dup
        @filtered_items = items.each_with_index.map { |it, idx| FilteredItem.new(idx, it) }.to_a
        @width = width
        @height = height
        @id = id
        @paginator = Paginator.new
        @delegate = DefaultDelegate.new
        if default_delegate = @delegate.as?(DefaultDelegate)
          default_delegate.match_style = @styles.default_filter_character_match
        end
        @key_map = KeyMap.new
        @filter_value = ""
        @filter_input = TextInput.new("#{@id}-filter")
        @filter_input.placeholder = "Filter"
        @filter_input.width = [@width - 2, 1].max
        @spinner = Spinner.new
        @help = Help.new
        @help.width = @width
        update_keybindings
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
        @all_items = items.dup
        @filtered_items = items.each_with_index.map { |it, idx| FilteredItem.new(idx, it) }.to_a
        apply_filter_if_needed
      end

      def add_item_front(item : Item)
        @all_items.unshift(item)
        @items = @all_items.dup
        apply_filter_if_needed
      end

      def remove_visible_item(index : Int32)
        item = visible_items[index]?
        return unless item
        @all_items.delete(item)
        @items = @all_items.dup
        apply_filter_if_needed
      end

      def selected_item : Item?
        visible_items[@index]?
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
        cmds = [] of Cmd
        if @filter_state == FilterState::Filtering || @filter_state == FilterState::FilterApplied
          @filter_input.width = [@width - 2, 1].max
          @filter_input, filter_cmd = @filter_input.update(msg)
          cmds << filter_cmd
          @filter_value = @filter_input.value
        end

        case msg
        when ZoneClickMsg
          if msg.id == @id
            focus
            # Calculate which item was clicked based on y position
            item_height = @delegate.height + @delegate.spacing
            clicked_item_offset = msg.y // item_height
            start_idx, _ = @paginator.get_slice_bounds(visible_items.size)
            clicked_index = start_idx + clicked_item_offset
            if clicked_index < visible_items.size
              @index = clicked_index
            end
          end
        when KeyMsg
          if focused?
            if cmd = handle_key(msg)
              cmds << cmd
            end
          end
        when Spinner::TickMsg
          @spinner, spinner_cmd = @spinner.update(msg)
          cmds << spinner_cmd if @show_spinner
        when StatusMessageTimeoutMsg
          @status_message = ""
        end

        if (delegate_cmd = @delegate.update(msg, self))
          cmds << delegate_cmd
        end

        {self, Cmds.batch(cmds)}
      end

      def handle_key(msg : KeyMsg) : Cmd
        if @filter_state == FilterState::Filtering
          return handle_filter_keys(msg)
        end

        case
        when @key_map.cursor_up.matches?(msg)
          cursor_up
        when @key_map.cursor_down.matches?(msg)
          cursor_down
        when @key_map.prev_page.matches?(msg)
          cursor_prev_page
        when @key_map.next_page.matches?(msg)
          cursor_next_page
        when @key_map.go_to_start.matches?(msg)
          go_to_start
        when @key_map.go_to_end.matches?(msg)
          go_to_end
        when @key_map.toggle_filter.matches?(msg)
          if @filtering_enabled
            cmd = toggle_filter
            return cmd
          end
        when @key_map.clear_filter.matches?(msg)
          clear_filter
        when @key_map.show_full_help.matches?(msg) || @key_map.close_full_help.matches?(msg)
          @help.show_all = !@help.show_all
        when @key_map.quit.matches?(msg)
          return Cmds.quit unless @disable_quit_keybindings
        when @key_map.force_quit.matches?(msg)
          return Cmds.quit
        end
        Cmds.none
      end

      def toggle_filter : Cmd
        @filter_state = case @filter_state
                        when FilterState::Unfiltered
                          FilterState::Filtering
                        when FilterState::Filtering
                          FilterState::FilterApplied
                        else
                          FilterState::Unfiltered
                        end
        if @filter_state == FilterState::Filtering
          @filter_input.value = @filter_value
          @filter_input.cursor_pos = @filter_input.value.size
        end
        apply_filter_if_needed
        update_keybindings
        if @filter_state == FilterState::Filtering
          Cmds.batch(@filter_input.focus, @filter_input.blink)
        else
          Cmds.none
        end
      end

      def set_filter_text(text : String) : Nil
        @filter_state = FilterState::Filtering
        @filter_value = text
        @filter_input.value = text
        @filter_input.cursor_pos = text.size
        apply_filter_if_needed
        @filter_state = FilterState::FilterApplied
        go_to_start
        update_keybindings
      end

      def set_filter_state(state : FilterState) : Nil
        @filter_state = state
        apply_filter_if_needed
        update_keybindings
      end

      def set_filtering_enabled(enabled : Bool) : Nil
        @filtering_enabled = enabled
        clear_filter unless enabled
        update_keybindings
      end

      def filtering_enabled=(value : Bool)
        set_filtering_enabled(value)
      end

      def cursor_up
        if @infinite_scrolling && visible_items.any?
          @index = (@index - 1) % visible_items.size
        else
          @index = (@index - 1).clamp(0, visible_items.size - 1)
        end
        update_pagination
      end

      def cursor_down
        if @infinite_scrolling && visible_items.any?
          @index = (@index + 1) % visible_items.size
        else
          @index = (@index + 1).clamp(0, visible_items.size - 1)
        end
        update_pagination
      end

      def cursor_prev_page
        @paginator.prev_page
        # Update index to be in the new page range?
        # Or just move index by per_page?
        @index = (@index - @paginator.per_page).clamp(0, visible_items.size - 1)
        update_pagination
      end

      def cursor_next_page
        @paginator.next_page
        @index = (@index + @paginator.per_page).clamp(0, visible_items.size - 1)
        update_pagination
      end

      def go_to_start
        @index = 0
        @paginator.page = 0
        update_pagination
      end

      def go_to_end
        last = [visible_items.size - 1, 0].max
        @index = last
        @paginator.page = last // @paginator.per_page
        update_pagination
      end

      def visible_items : Array(Item)
        if @filter_state == FilterState::Unfiltered
          @all_items
        else
          @filtered_items.map(&.item)
        end
      end

      def matches_for_item(index : Int32) : Array(Int32)
        return [] of Int32 if @filter_state == FilterState::Unfiltered
        @filtered_items[index]?.try(&.matches) || [] of Int32
      end

      def update_pagination
        # Calculate items per page based on height and delegate height
        item_height = @delegate.height + @delegate.spacing
        available_height = @height

        if @show_title && (!@title.empty? || @show_spinner || (@show_filter && @filtering_enabled && @filter_state == FilterState::Filtering))
          available_height -= Term2::Text.height(title_view)
        end
        if @show_status_bar
          available_height -= Term2::Text.height(status_view)
        end
        if @show_pagination
          available_height -= Term2::Text.height(pagination_view)
        end
        if @show_help
          available_height -= Term2::Text.height(help_view)
        end

        per_page = [1, available_height // item_height].max
        @paginator.per_page = per_page
        @paginator.set_total_pages(visible_items.size)

        # Sync paginator page with index
        @paginator.page = @index // per_page
        @index = @index.clamp(0, [visible_items.size - 1, 0].max)
      end

      def view : String
        content = String.build do |io|
          if @show_title && (!@title.empty? || @show_spinner || (@show_filter && @filter_state == FilterState::Filtering))
            io << title_view << "\n"
          end

          # Render items for current page
          items_to_render = visible_items
          start_idx, end_idx = @paginator.get_slice_bounds(items_to_render.size)

          if items_to_render.empty?
            io << @styles.no_items.render("No #{@item_name_plural}.") << "\n"
          else
            (start_idx...end_idx).each do |i|
              item = items_to_render[i]
              # Generate enumerator prefix for this item
              enum_prefix = @enumerator.call(items_to_render, i)
              matches = matches_for_item(i)
              @delegate.render_with_matches(io, item, i, i == @index, enum_prefix, matches)
              io << "\n" * @delegate.spacing
            end
          end

          if @show_filter && @filtering_enabled && (@filter_state == FilterState::Filtering || @filter_state == FilterState::FilterApplied)
            filter_line = String.build do |s|
              s << @styles.filter_prompt.render("Filter: ")
              if @filter_state == FilterState::Filtering
                s << @filter_input.view
              else
                s << @filter_value
              end
            end
            io << filter_line << "\n"
          end

          if @show_status_bar
            io << status_view << "\n"
          end

          if @show_pagination
            io << pagination_view
            io << "\n" if @show_help
          end

          if @show_help
            io << help_view
          end
        end

        # Wrap with zone marker if we have an ID
        @id.empty? ? content : Zone.mark(@id, content)
      end

      def status_view : String
        total_items = @all_items.size
        visible = visible_items.size
        label = visible == 1 ? @item_name_singular : @item_name_plural

        return @status_message unless @status_message.empty?

        status = case @filter_state
                 when FilterState::Filtering
                   if visible == 0
                     "Nothing matched"
                   else
                     "#{visible} #{label}"
                   end
                 when FilterState::FilterApplied
                   filter_display = @filter_value.strip
                   if filter_display.size > 10
                     filter_display = filter_display[0, 10] + "…"
                   end
                   if filter_display.empty?
                     "#{visible} #{label}"
                   else
                     "“#{filter_display}” #{visible} #{label}"
                   end
                 else
                   if total_items == 0
                     "No #{@item_name_plural}"
                   else
                     "#{visible} #{label}"
                   end
                 end

        num_filtered = total_items - visible
        if num_filtered > 0
          status += " • #{num_filtered} filtered"
        end

        hint = case @filter_state
               when FilterState::Unfiltered
                 "up"
               when FilterState::Filtering
                 "filter"
               when FilterState::FilterApplied
                 "clear filter"
               else
                 ""
               end
        status += " • #{hint}" unless hint.empty?

        @styles.status_bar.render(status)
      end

      def clear_filter
        @filter_value = ""
        @filter_input.value = ""
        @filter_input.cursor_pos = 0
        @filter_state = FilterState::Unfiltered
        apply_filter_if_needed
        update_keybindings
      end

      def help_view : String
        return "" unless @show_help
        @help.width = @width
        @help.view(self)
      end

      def short_help : Array(Key::Binding)
        bindings = [@key_map.cursor_up, @key_map.cursor_down]
        unless @filter_state == FilterState::Filtering
          bindings << @key_map.toggle_filter
          if @delegate.responds_to?(:short_help)
            bindings.concat(@delegate.as(Help::KeyMap).short_help)
          end
        else
          bindings << @key_map.accept_filter
          bindings << @key_map.cancel_filter
        end
        bindings << @key_map.clear_filter
        if proc = @additional_short_help_keys
          bindings.concat(proc.call)
        end
        bindings << @key_map.quit unless @disable_quit_keybindings
        bindings
      end

      def full_help : Array(Array(Key::Binding))
        groups = [] of Array(Key::Binding)
        groups << [
          @key_map.cursor_up, @key_map.cursor_down,
          @key_map.next_page, @key_map.prev_page,
          @key_map.go_to_start, @key_map.go_to_end,
        ]

        filter_group = [
          @key_map.toggle_filter,
          @key_map.clear_filter,
          @key_map.accept_filter,
          @key_map.cancel_filter,
        ]
        groups << filter_group

        if @delegate.responds_to?(:full_help)
          groups.concat(@delegate.as(Help::KeyMap).full_help)
        end

        extra = [] of Key::Binding
        if proc = @additional_full_help_keys
          extra.concat(proc.call)
        end
        extra << @key_map.quit unless @disable_quit_keybindings
        extra << @key_map.force_quit
        groups << extra
        groups
      end

      def update_keybindings
        has_items = visible_items.any?

        if @filter_state == FilterState::Filtering
          @key_map.cursor_up.enabled = false
          @key_map.cursor_down.enabled = false
          @key_map.next_page.enabled = false
          @key_map.prev_page.enabled = false
          @key_map.go_to_start.enabled = false
          @key_map.go_to_end.enabled = false
          @key_map.toggle_filter.enabled = false
          @key_map.clear_filter.enabled = false
          @key_map.accept_filter.enabled = !@filter_input.value.empty?
          @key_map.cancel_filter.enabled = true
          @key_map.show_full_help.enabled = false
          @key_map.close_full_help.enabled = false
        else
          @key_map.cursor_up.enabled = has_items
          @key_map.cursor_down.enabled = has_items
          @key_map.next_page.enabled = has_items
          @key_map.prev_page.enabled = has_items
          @key_map.go_to_start.enabled = has_items
          @key_map.go_to_end.enabled = has_items
          @key_map.toggle_filter.enabled = has_items && @filtering_enabled
          @key_map.clear_filter.enabled = @filter_state == FilterState::FilterApplied
          @key_map.accept_filter.enabled = false
          @key_map.cancel_filter.enabled = false
          @key_map.show_full_help.enabled = true
          @key_map.close_full_help.enabled = true
        end

        quit_enabled = !@disable_quit_keybindings
        @key_map.quit.enabled = quit_enabled
        @key_map.force_quit.enabled = true
      end

      def pagination_view : String
        return "" if @paginator.total_pages < 2

        view = @paginator.view
        if @paginator.type == Paginator::Type::Dots && Term2::Text.width(view) > @width
          @paginator.type = Paginator::Type::Arabic
          view = @paginator.view
        elsif @paginator.type == Paginator::Type::Arabic && Term2::Text.width(view) < @width // 2
          # Prefer dots when we have room
          @paginator.type = Paginator::Type::Dots
          view = @paginator.view
        end

        @styles.pagination_style.render(view)
      end

      def title_view : String
        spinner_view = @show_spinner ? @styles.spinner.render(@spinner.view) : ""

        if @show_filter && @filtering_enabled && @filter_state == FilterState::Filtering
          return @styles.title_bar.render(@filter_input.view)
        end

        body = String.build do |s|
          unless spinner_view.empty?
            s << spinner_view << " "
          end
          s << @styles.title.render(@title)
          unless @status_message.empty?
            s << "  " << @status_message
          end
        end

        @styles.title_bar.render(body)
      end

      def new_status_message(text : String, lifetime : Time::Span = @status_message_lifetime) : Cmd
        @status_message = text
        Cmds.after(lifetime, StatusMessageTimeoutMsg.new)
      end

      def start_spinner : Cmd
        @show_spinner = true
        @spinner.tick
      end

      def stop_spinner
        @show_spinner = false
      end

      def toggle_spinner : Cmd
        if @show_spinner
          stop_spinner
          Cmds.none
        else
          start_spinner
        end
      end

      def set_size(width : Int32, height : Int32)
        @width = width
        @height = height
        @filter_input.width = [@width - 2, 1].max
        update_pagination
      end

      private def handle_filter_input(msg : KeyMsg)
        key_str = msg.key.to_s
        case key_str
        when "esc"
          clear_filter
          @status_message = ""
        when "enter"
          @filter_state = FilterState::FilterApplied
          apply_filter_if_needed
        else
          apply_filter_if_needed
        end
        update_keybindings
      end

      private def handle_filter_keys(msg : KeyMsg) : Cmd
        if @key_map.cancel_filter.matches?(msg)
          clear_filter
          return Cmds.none
        elsif @key_map.accept_filter.matches?(msg)
          @filter_state = FilterState::FilterApplied
          apply_filter_if_needed
          update_keybindings
          return Cmds.none
        end

        handle_filter_input(msg)
        Cmds.none
      end

      private def apply_filter_if_needed
        if @filter_state == FilterState::Unfiltered
          @filtered_items = @all_items.each_with_index.map { |it, idx| FilteredItem.new(idx, it) }.to_a
          update_pagination
          return
        end

        needle = @filter_value
        ranks = @filter.call(needle, @all_items.map(&.filter_value))
        if ranks.empty? && needle.strip.empty?
          @filtered_items = @all_items.each_with_index.map { |it, idx| FilteredItem.new(idx, it) }.to_a
        else
          @filtered_items = ranks.compact_map do |rank|
            item = @all_items[rank.index]?
            next unless item
            FilteredItem.new(rank.index, item, rank.matched_indexes)
          end
        end
        @index = @index.clamp(0, [@filtered_items.size - 1, 0].max)
        update_pagination
      end

      # Default fuzzy-ish filter: performs subsequence match and returns ranks with matched rune indexes.
      # Default fuzzy-ish filter: subsequence match with ranking (shorter spans first, then earlier start, then stable index).
      def self.default_filter(term : String, targets : Array(String)) : Array(Rank)
        return targets.each_index.map { |i| Rank.new(i, [] of Int32) }.to_a if term.empty?

        needle = term.downcase
        ranked = [] of {rank: Int32, start: Int32, index: Int32, matches: Array(Int32)}

        targets.each_with_index do |target, idx|
          hay = target.downcase
          matches = [] of Int32
          j = 0

          hay.each_char_with_index do |ch, i|
            if j < needle.size && ch == needle[j]
              matches << i
              j += 1
            end
          end

          next unless j == needle.size

          span = matches.empty? ? 0 : matches.last - matches.first
          start = matches.first? || 0
          ranked << {rank: span, start: start, index: idx, matches: matches}
        end

        ranked.sort_by! { |r| {r[:rank], r[:start], r[:index]} }
        ranked.map { |r| Rank.new(r[:index], r[:matches]) }
      end

      def set_status_bar_item_name(singular : String, plural : String)
        @item_name_singular = singular
        @item_name_plural = plural
      end
    end
  end
end
