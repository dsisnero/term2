require "../term2"

module Term2
  module Components
    class Paginator
      include Model

      enum Type
        Arabic
        Dots
      end

      property type : Type = Type::Arabic
      property page : Int32 = 0
      property per_page : Int32 = 1
      property total_pages : Int32 = 1
      property active_dot : String = "•"
      property inactive_dot : String = "○"
      property arabic_format : String = "%d/%d"
      property style : Style = Style.new.faint(true)
      property key_map : KeyMap = KeyMap.new

      # Key bindings (parity with bubbles defaults)
      struct KeyMap
        getter prev_page : Key::Binding
        getter next_page : Key::Binding

        def initialize
          @prev_page = Key::Binding.new(
            ["pgup", "left", "h"],
            "pgup/left/h",
            "prev page"
          )
          @next_page = Key::Binding.new(
            ["pgdown", "right", "l"],
            "pgdown/right/l",
            "next page"
          )
        end
      end

      def initialize(@type : Type = Type::Arabic, @page : Int32 = 0, @per_page : Int32 = 1, @total_pages : Int32 = 1)
        # ensure sensible defaults
        @total_pages = 1 if @total_pages < 1
      end

      def update(msg : Msg) : {Paginator, Cmd}
        case msg
        when KeyMsg
          if @key_map.next_page.matches?(msg)
            next_page
          elsif @key_map.prev_page.matches?(msg)
            prev_page
          end
        end
        {self, Cmds.none}
      end

      def set_total_pages(items : Int32) : Int32
        return @total_pages if items < 1
        pages = items // @per_page
        pages += 1 if items % @per_page > 0
        @total_pages = pages
        @page = 0 if @page >= @total_pages
        pages
      end

      def total_pages=(pages : Int32)
        @total_pages = pages < 1 ? 1 : pages
        @page = @total_pages - 1 if @page >= @total_pages
      end

      def get_slice_bounds(length : Int32) : {Int32, Int32}
        start_idx = @page * @per_page
        end_idx = {start_idx + @per_page, length}.min
        {start_idx, end_idx}
      end

      def items_on_page(total_items : Int32) : Int32
        return 0 if total_items < 1
        start_idx, end_idx = get_slice_bounds(total_items)
        end_idx - start_idx
      end

      def on_first_page?
        @page == 0
      end

      def on_last_page?
        @page == @total_pages - 1
      end

      def prev_page
        @page -= 1 if @page > 0
      end

      def next_page
        @page += 1 unless on_last_page?
        @page = @total_pages - 1 if @page >= @total_pages
      end

      def view : String
        text = case @type
               when Type::Arabic
                 sprintf(@arabic_format, @page + 1, @total_pages)
               when Type::Dots
                 String.build do |str|
                   @total_pages.times do |i|
                     str << (i == @page ? @active_dot : @inactive_dot)
                   end
                 end
               else
                 ""
               end

        @style.render(text)
      end
    end
  end
end
