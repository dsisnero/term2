require "../term2"
require "./key"
require "file_utils"

module Term2
  module Bubbles
    class FilePicker < Model
      property current_directory : String
      property allowed_types : Array(String) = [] of String
      property? show_hidden : Bool = false
      property? dir_allowed : Bool = false
      property? file_allowed : Bool = true

      property files : Array(String) = [] of String
      property selected_index : Int32 = 0
      property height : Int32 = 10

      # Styles
      property cursor_style : Style = Style.new(foreground: Color::MAGENTA)
      property dir_style : Style = Style.new(foreground: Color::BLUE, bold: true)
      property file_style : Style = Style.new
      property selected_style : Style = Style.new(reverse: true)
      property error_style : Style = Style.new(foreground: Color::RED)

      property error : String?
      property selected_file : String?

      def did_select_file?
        !@selected_file.nil?
      end

      # Key bindings
      property key_map : KeyMap

      struct KeyMap
        getter up : Key::Binding
        getter down : Key::Binding
        getter open : Key::Binding
        getter back : Key::Binding
        getter select : Key::Binding

        def initialize
          @up = Key::Binding.new(["up", "k"], "up", "up")
          @down = Key::Binding.new(["down", "j"], "down", "down")
          @open = Key::Binding.new(["right", "l", "enter"], "enter", "open")
          @back = Key::Binding.new(["left", "h", "backspace"], "backspace", "back")
          @select = Key::Binding.new(["enter", "space"], "enter", "select")
        end
      end

      def initialize(path : String = ".")
        @current_directory = File.expand_path(path)
        @key_map = KeyMap.new
        read_dir
      end

      class ReadDirMsg < Message
        getter files : Array(String)
        getter error : String?

        def initialize(@files, @error = nil)
        end
      end

      class FileSelectedMsg < Message
        getter path : String

        def initialize(@path)
        end
      end

      def update(msg : Message) : {FilePicker, Cmd}
        case msg
        when ReadDirMsg
          if err = msg.error
            @error = err
            @files = [] of String
          else
            @files = msg.files
            @error = nil
            @selected_index = 0
          end
        when KeyMsg
          handle_key(msg)
        end
        {self, Cmd.none}
      end

      def handle_key(msg : KeyMsg)
        case
        when @key_map.up.matches?(msg)
          move_cursor(-1)
        when @key_map.down.matches?(msg)
          move_cursor(1)
        when @key_map.back.matches?(msg)
          navigate_up
        when @key_map.open.matches?(msg)
          open_selected
        end
      end

      def move_cursor(delta : Int32)
        @selected_index = (@selected_index + delta).clamp(0, [@files.size - 1, 0].max)
      end

      def navigate_up
        parent = File.dirname(@current_directory)
        if parent != @current_directory
          @current_directory = parent
          read_dir
        end
      end

      def open_selected
        return if @files.empty?

        file = @files[@selected_index]
        path = File.join(@current_directory, file)

        if File.directory?(path)
          @current_directory = path
          read_dir
        elsif @file_allowed
          @selected_file = path
          # Emit selection message?
          # For now just set state.
        end
      end

      def read_dir
        entries = Dir.children(@current_directory).sort

        if !@show_hidden
          entries = entries.reject(&.starts_with?("."))
        end

        if !@allowed_types.empty?
          entries = entries.select do |filename|
            path = File.join(@current_directory, filename)
            File.directory?(path) || @allowed_types.includes?(File.extname(filename))
          end
        end

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

        @files = entries
        @error = nil
        @selected_index = 0
      rescue ex
        @error = ex.message
        @files = [] of String
      end

      def view : String
        if @error
          return @error_style.apply("Error: #{@error}")
        end

        String.build do |io|
          io << @dir_style.apply(@current_directory) << "\n\n"

          start_idx = 0
          end_idx = [@files.size, @height].min

          # Simple scrolling
          if @selected_index >= @height
            start_idx = @selected_index - @height + 1
            end_idx = start_idx + @height
          end

          visible_files = @files[start_idx...end_idx]

          visible_files.each_with_index do |file, i|
            real_idx = start_idx + i
            selected = real_idx == @selected_index

            cursor = selected ? "> " : "  "

            path = File.join(@current_directory, file)
            is_dir = File.directory?(path)

            style = is_dir ? @dir_style : @file_style
            if selected
              style = style.merge(@selected_style)
            end

            io << @cursor_style.apply(cursor)
            io << style.apply(file)
            io << "/" if is_dir
            io << "\n"
          end

          if @files.empty?
            io << "  (empty)"
          end
        end
      end
    end
  end
end
