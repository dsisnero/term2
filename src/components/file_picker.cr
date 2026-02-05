require "file_utils"
require "nucleoc"
require "../term2"
require "../zone"
require "./key"

module Term2
  module Components
    class FilePicker
      include Model

      property id : String = ""
      property current_directory : String
      property allowed_types : Array(String) = [] of String
      property? show_hidden : Bool = false
      property? dir_allowed : Bool = false
      property? file_allowed : Bool = true

      property files : Array(String) = [] of String
      property selected_index : Int32 = 0
      property height : Int32 = 10
      property filter_text : String = ""

      # Styles
      property cursor_style : Lipgloss::Style = Lipgloss::Style.new.foreground(Lipgloss::Color::MAGENTA)
      property dir_style : Lipgloss::Style = Lipgloss::Style.new.foreground(Lipgloss::Color::BLUE).bold(true)
      property file_style : Lipgloss::Style = Lipgloss::Style.new
      property selected_style : Lipgloss::Style = Lipgloss::Style.new.reverse(true)
      property error_style : Lipgloss::Style = Lipgloss::Style.new.foreground(Lipgloss::Color::RED)

      property error : String?
      property selected_file : String?

      struct Rank
        property index : Int32
        property score : UInt16

        def initialize(@index, @score)
        end
      end

      alias FilterFunc = Proc(String, Array(String), Array(Rank))

      property filter_func : FilterFunc = ->FilePicker.default_filter(String, Array(String))
      @filtered_files : Array(Rank) = [] of Rank

      def did_select_file?
        !@selected_file.nil?
      end

      def focused?
        return true if @id.empty?
        Zone.focused?(@id)
      end

      def focus
        Zone.focus(@id) unless @id.empty?
      end

      def blur
        Zone.blur(@id) unless @id.empty?
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

      def initialize(path : String = ".", @id : String = "")
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

      def update(msg : Msg) : {FilePicker, Cmd}
        case msg
        when ReadDirMsg
          if err = msg.error
            @error = err
            @files = [] of String
          else
            @files = msg.files
            @error = nil
            apply_filter
          end
        when ZoneClickMsg
          if !@id.empty? && msg.id == @id
            focus
            # Could calculate which item was clicked based on y position
          end
        when KeyMsg
          handle_key(msg) if focused?
        end
        {self, Cmds.none}
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
        count = visible_files.size
        @selected_index = (@selected_index + delta).clamp(0, [count - 1, 0].max)
      end

      def navigate_up
        parent = File.dirname(@current_directory)
        if parent != @current_directory
          @current_directory = parent
          read_dir
        end
      end

      def open_selected
        files = visible_files
        return if files.empty?

        file = files[@selected_index]
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
        apply_filter
      rescue ex
        @error = ex.message
        @files = [] of String
      end

      def filter_text=(text : String)
        @filter_text = text
        apply_filter
      end

      def visible_files : Array(String)
        return @files if @filter_text.empty?
        @filtered_files.map { |rank| @files[rank.index] }
      end

      def self.default_filter(term : String, targets : Array(String)) : Array(Rank)
        return [] of Rank if term.empty?

        config = Nucleoc::Config::DEFAULT.match_paths
        ranks = [] of Rank

        targets.each_with_index do |target, i|
          if score = Nucleoc.fuzzy_match(target, term, config)
            ranks << Rank.new(i, score)
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
          @filtered_files.clear
        else
          @filtered_files = @filter_func.call(@filter_text, @files)
        end
        @selected_index = 0
      end

      def view : View
        content = if @error
                    @error_style.render("Error: #{@error}")
                  else
                    String.build do |io|
                      io << @dir_style.render(@current_directory) << "\n\n"

                      files = visible_files
                      start_idx = 0
                      end_idx = [files.size, @height].min

                      # Simple scrolling
                      if @selected_index >= @height
                        start_idx = @selected_index - @height + 1
                        end_idx = start_idx + @height
                      end

                      visible_entries = files[start_idx...end_idx]

                      visible_entries.each_with_index do |file, i|
                        real_idx = start_idx + i
                        selected = real_idx == @selected_index

                        cursor = selected ? "> " : "  "

                        path = File.join(@current_directory, file)
                        is_dir = File.directory?(path)

                        style = is_dir ? @dir_style : @file_style
                        if selected && focused?
                          style = style.merge(@selected_style)
                        end

                        io << @cursor_style.render(cursor)
                        io << style.render(file)
                        io << "/" if is_dir
                        io << "\n"
                      end

                      if files.empty?
                        io << "  (empty)"
                      end
                    end
                  end

        unless @id.empty?
          Zone.mark(@id, content)
        end
        View.new(content: content)
      end
    end
  end
end
