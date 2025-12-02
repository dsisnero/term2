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

      def initialize
      end

      def update(msg : Msg) : {Paginator, Cmd}
        {self, Cmds.none}
      end

      def total_pages=(items : Int32)
        if items <= 0
          @total_pages = 1
          return
        end

        n = items // @per_page
        if items % @per_page > 0
          n += 1
        end
        @total_pages = n
      end

      def items_on_page(items : Int32) : ::Range(Int32, Int32)
        start = @page * @per_page
        end_idx = {start + @per_page, items}.min
        start...end_idx
      end

      def on_first_page?
        @page == 0
      end

      def on_last_page?
        @page == @total_pages - 1
      end

      def prev_page
        @page = (@page - 1).clamp(0, @total_pages - 1)
      end

      def next_page
        @page = (@page + 1).clamp(0, @total_pages - 1)
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
