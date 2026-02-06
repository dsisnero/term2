require "file_utils"
require "../term2"
require "./key"
require "atomic"

module Term2
  module Components
    class FilePicker
      include Model

      @@last_id = Atomic(Int64).new(0)

      def self.next_id : Int32
        @@last_id.add(1).to_i32
      end

      MARGIN_BOTTOM   = 5
      FILE_SIZE_WIDTH = 7
      PADDING_LEFT    = 2

      # Internal instance ID for matching async messages
      getter id : Int32

      # Path is the path which the user has selected with the file picker.
      property path : String = ""

      # CurrentDirectory is the directory that the user is currently in.
      property current_directory : String

      # AllowedTypes specifies which file types the user may select.
      # If empty the user may select any file.
      property allowed_types : Array(String) = [] of String

      property key_map : KeyMap
      property files : Array(String) = [] of String
      property? show_permissions : Bool = true
      property? show_size : Bool = true
      property? show_hidden : Bool = false
      property? dir_allowed : Bool = false
      property? file_allowed : Bool = true
      property? auto_height : Bool = true
      property? focus : Bool = false

      property selected_file : String = ""
      property selected : Int32 = 0
      property selected_stack : Array(Int32) = [] of Int32

      property min : Int32 = 0
      property max : Int32 = 0
      property max_stack : Array(Int32) = [] of Int32
      property min_stack : Array(Int32) = [] of Int32

      # Height of the picker.
      property height : Int32 = 0

      property cursor : String = ">"
      property styles : Styles

      # Backward compatibility styles
      def cursor_style : Lipgloss::Style
        @styles.cursor
      end

      def dir_style : Lipgloss::Style
        @styles.directory
      end

      def file_style : Lipgloss::Style
        @styles.file
      end

      def selected_style : Lipgloss::Style
        @styles.selected
      end

      def error_style : Lipgloss::Style
        Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(196)) # red
      end

      class Styles
        property disabled_cursor : Lipgloss::Style
        property cursor : Lipgloss::Style
        property symlink : Lipgloss::Style
        property directory : Lipgloss::Style
        property file : Lipgloss::Style
        property disabled_file : Lipgloss::Style
        property permission : Lipgloss::Style
        property selected : Lipgloss::Style
        property disabled_selected : Lipgloss::Style
        property file_size : Lipgloss::Style
        property empty_directory : Lipgloss::Style

        def initialize(
          @disabled_cursor = Lipgloss::Style.new,
          @cursor = Lipgloss::Style.new,
          @symlink = Lipgloss::Style.new,
          @directory = Lipgloss::Style.new,
          @file = Lipgloss::Style.new,
          @disabled_file = Lipgloss::Style.new,
          @permission = Lipgloss::Style.new,
          @selected = Lipgloss::Style.new,
          @disabled_selected = Lipgloss::Style.new,
          @file_size = Lipgloss::Style.new,
          @empty_directory = Lipgloss::Style.new,
        )
        end
      end

      def self.default_styles : Styles
        Styles.new(
          disabled_cursor: Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(247)),
          cursor: Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(212)),
          symlink: Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(36)),
          directory: Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(99)),
          file: Lipgloss::Style.new,
          disabled_file: Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(243)),
          disabled_selected: Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(247)),
          permission: Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(244)),
          selected: Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(212)).bold(true),
          file_size: Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(240)).width(FILE_SIZE_WIDTH),
          empty_directory: Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(240)).padding_left(PADDING_LEFT).string=("Bummer. No Files Found.")
        )
      end

      def self.default_styles_with_renderer(renderer : Lipgloss::Renderer) : Styles
        default_styles
      end

      struct KeyMap
        getter go_to_top : Key::Binding
        getter go_to_last : Key::Binding
        getter down : Key::Binding
        getter up : Key::Binding
        getter page_up : Key::Binding
        getter page_down : Key::Binding
        getter back : Key::Binding
        getter open : Key::Binding
        getter select : Key::Binding

        def initialize
          @go_to_top = Key::Binding.new(["g"], "g", "first")
          @go_to_last = Key::Binding.new(["G"], "G", "last")
          @down = Key::Binding.new(["j", "down", "ctrl+n"], "j", "down")
          @up = Key::Binding.new(["k", "up", "ctrl+p"], "k", "up")
          @page_up = Key::Binding.new(["K", "pgup"], "pgup", "page up")
          @page_down = Key::Binding.new(["J", "pgdown"], "pgdn", "page down")
          @back = Key::Binding.new(["h", "backspace", "left", "esc"], "h", "back")
          @open = Key::Binding.new(["l", "right", "enter"], "l", "open")
          @select = Key::Binding.new(["enter"], "enter", "select")
        end
      end

      def self.default_key_map : KeyMap
        KeyMap.new
      end

      def self.new(path : String = ".")
        instance = allocate
        instance.initialize(path)
        instance
      end

      def initialize(path : String = ".")
        @id = self.class.next_id
        @current_directory = File.expand_path(path)
        @cursor = ">"
        @allowed_types = [] of String
        @selected = 0
        @show_permissions = true
        @show_size = true
        @show_hidden = false
        @dir_allowed = false
        @file_allowed = true
        @auto_height = true
        @height = 0
        @max = 0
        @min = 0
        @selected_stack = [] of Int32
        @min_stack = [] of Int32
        @max_stack = [] of Int32
        @key_map = KeyMap.new
        @styles = self.class.default_styles
        read_dir
      end

      class ErrorMsg < Message
        getter error : Exception

        def initialize(@error)
        end
      end

      class ReadDirMsg < Message
        getter id : Int32
        getter entries : Array(String)

        def initialize(@id, @entries)
        end
      end

      # SetHeight sets the height of the filepicker.
      def set_height(height : Int32)
        @height = height
        if @max > @height - 1
          @max = @min + @height - 1
        end
      end

      def push_view(selected : Int32, minimum : Int32, maximum : Int32)
        @selected_stack << selected
        @min_stack << minimum
        @max_stack << maximum
      end

      def pop_view : {Int32, Int32, Int32}
        {
          @selected_stack.pop,
          @min_stack.pop,
          @max_stack.pop,
        }
      end

      def read_dir
        entries = Dir.children(@current_directory).sort

        # Sort directories first
        entries.sort! do |file_a, file_b|
          path_a = File.join(@current_directory, file_a)
          path_b = File.join(@current_directory, file_b)
          dir_a = File.directory?(path_a)
          dir_b = File.directory?(path_b)

          if dir_a == dir_b
            file_a <=> file_b
          elsif dir_a
            -1
          else
            1
          end
        end

        unless @show_hidden
          entries = entries.reject(&.starts_with?("."))
        end

        @files = entries
        @max = Math.max(@max, @height - 1)
        nil
      rescue ex
        # Store error for view
        @error = ex.message
      end

      def init : Cmd
        Cmds.none # read_dir is called in initialize
      end

      def update(msg : Msg) : {FilePicker, Cmd}
        case msg
        when ReadDirMsg
          if msg.id == @id
            @files = msg.entries
            @max = Math.max(@max, @height - 1)
          end
        when WindowSizeMsg
          if @auto_height
            @height = msg.height - MARGIN_BOTTOM
          end
          @max = @height - 1
        when KeyMsg
          if @focus
            handle_key(msg)
          end
        end
        {self, Cmds.none}
      end

      def handle_key(msg : KeyMsg)
        case
        when @key_map.go_to_top.matches?(msg)
          @selected = 0
          @min = 0
          @max = @height - 1
        when @key_map.go_to_last.matches?(msg)
          @selected = @files.size - 1
          @min = @files.size - @height
          @max = @files.size - 1
        when @key_map.down.matches?(msg)
          @selected += 1
          if @selected >= @files.size
            @selected = @files.size - 1
          end
          if @selected > @max
            @min += 1
            @max += 1
          end
        when @key_map.up.matches?(msg)
          @selected -= 1
          if @selected < 0
            @selected = 0
          end
          if @selected < @min
            @min -= 1
            @max -= 1
          end
        when @key_map.page_down.matches?(msg)
          @selected += @height
          if @selected >= @files.size
            @selected = @files.size - 1
          end
          @min += @height
          @max += @height

          if @max >= @files.size
            @max = @files.size - 1
            @min = @max - @height
          end
        when @key_map.page_up.matches?(msg)
          @selected -= @height
          if @selected < 0
            @selected = 0
          end
          @min -= @height
          @max -= @height

          if @min < 0
            @min = 0
            @max = @min + @height
          end
        when @key_map.back.matches?(msg)
          parent = File.dirname(@current_directory)
          if parent != @current_directory
            @current_directory = parent
            if @selected_stack.size > 0
              @selected, @min, @max = pop_view
            else
              @selected = 0
              @min = 0
              @max = @height - 1
            end
            read_dir
          end
        when @key_map.open.matches?(msg)
          if @files.empty?
            return
          end

          file = @files[@selected]
          path = File.join(@current_directory, file)

          is_dir = File.directory?(path)
          # TODO: Handle symlinks

          if (!is_dir && @file_allowed) || (is_dir && @dir_allowed)
            if @key_map.select.matches?(msg)
              # Select the current path as the selection
              @path = path
            end
          end

          unless is_dir
            return
          end

          @current_directory = path
          push_view(@selected, @min, @max)
          @selected = 0
          @min = 0
          @max = @height - 1
          read_dir
        end
      end

      def view : View
        if @files.empty?
          content = @styles.empty_directory.height(@height).max_height(@height).to_s
          return View.new(content: content)
        end

        io = IO::Memory.new

        @files.each_with_index do |file, i|
          if i < @min || i > @max
            next
          end

          path = File.join(@current_directory, file)
          is_dir = File.directory?(path)
          # TODO: Get file info for permissions, size, symlinks
          disabled = !can_select(file) && !is_dir

          if @selected == i
            selected = ""
            if @show_permissions
              # TODO: Add permissions
              selected += " -rw-r--r--"
            end
            if @show_size
              # TODO: Add file size
              selected += sprintf("%#{FILE_SIZE_WIDTH}d", 0)
            end
            selected += " " + file
            # TODO: Add symlink arrow

            if disabled
              io << @styles.disabled_cursor.render(@cursor)
              io << @styles.disabled_selected.render(selected)
            else
              io << @styles.cursor.render(@cursor)
              io << @styles.selected.render(selected)
            end
            io << "\n"
            next
          end

          style = @styles.file
          if is_dir
            style = @styles.directory
            # TODO: else if symlink
          elsif disabled
            style = @styles.disabled_file
          end

          file_name = style.render(file)
          io << @styles.cursor.render(" ")
          # TODO: Add symlink arrow
          if @show_permissions
            # TODO: Add permissions
            io << " " + @styles.permission.render("-rw-r--r--")
          end
          if @show_size
            # TODO: Add file size
            io << @styles.file_size.render("0")
          end
          io << " " + file_name
          io << "\n"
        end

        # Pad to height
        lines = io.to_s.split("\n", remove_empty: false)
        while lines.size < @height
          io << "\n"
          lines = io.to_s.split("\n", remove_empty: false)
        end

        View.new(content: io.to_s)
      end

      # DidSelectFile returns whether a user has selected a file (on this msg).
      def did_select_file(msg : Msg) : {Bool, String}
        did_select, path = did_select_file_internal(msg)
        if did_select && can_select(path)
          return {true, path}
        end
        return {false, ""}
      end

      # DidSelectDisabledFile returns whether a user tried to select a disabled file
      def did_select_disabled_file(msg : Msg) : {Bool, String}
        did_select, path = did_select_file_internal(msg)
        if did_select && !can_select(path)
          return {true, path}
        end
        return {false, ""}
      end

      private def did_select_file_internal(msg : Msg) : {Bool, String}
        if @files.empty?
          return {false, ""}
        end

        case msg
        when KeyMsg
          # If the msg does not match the Select keymap then this could not have been a selection.
          unless @key_map.select.matches?(msg)
            return {false, ""}
          end

          file = @files[@selected]
          path = File.join(@current_directory, file)
          is_dir = File.directory?(path)
          # TODO: Handle symlinks

          if (!is_dir && @file_allowed) || (is_dir && @dir_allowed) && !@path.empty?
            return {true, @path}
          end
        end

        {false, ""}
      end

      def can_select(file : String) : Bool
        return true if @allowed_types.empty?

        @allowed_types.any? do |ext|
          file.ends_with?(ext)
        end
      end

      # Backward compatibility aliases
      def focused? : Bool
        @focus
      end

      def focus
        @focus = true
      end

      def blur
        @focus = false
      end

      def selected_file : String?
        @path unless @path.empty?
      end

      def selected_file=(path : String)
        @path = path
      end

      def did_select_file?
        !selected_file.nil?
      end

      property error : String?
    end
  end
end
