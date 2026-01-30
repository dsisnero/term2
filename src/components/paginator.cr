require "../term2"

module Term2
  module Components
    class Paginator
      include Term2::Model

      enum Type
        Arabic # 1/10
        Dots   # ••••••••••
      end

      property type : Type = Type::Arabic
      property page : Int32 = 0
      property per_page : Int32 = 1
      property total_pages : Int32 = 1

      # Styles for Dots
      property active_dot : String = "•"
      property inactive_dot : String = "○"

      # Styles for Arabic
      property arabic_format : String = "%d/%d"

      # Default constructor
      def initialize
      end

      # [FIX] Constructor with named arguments for testing/convenience
      def initialize(*, @per_page : Int32 = 1, @total_pages : Int32 = 1, @page : Int32 = 0)
      end

      def init : Cmd
        nil
      end

      def update(msg : Msg) : {Paginator, Cmd}
        if msg.is_a?(KeyMsg)
          key = msg.key.to_s
          case key
          when "left", "h", "pgup"
            prev_page
          when "right", "l", "pgdn"
            next_page
          end
        end

        {self, nil}
      end

      # Set total pages based on items count and items per page
      def set_total_pages(items_count : Int32)
        n = items_count
        if n < 1
          @total_pages = 1
        else
          @total_pages = (n + @per_page - 1) // @per_page
        end
      end

      def total_pages=(val : Int32)
        @total_pages = val
      end

      # Calculate the slice bounds for the current page
      # Returns {start, end} indices for slicing an array
      def get_slice_bounds(total_items : Int32) : {Int32, Int32}
        start_index = @page * @per_page
        end_index = Math.min(start_index + @per_page, total_items)
        {start_index, end_index}
      end

      # Returns the number of items on the current page
      def items_on_page(total_items : Int32) : Int32
        if total_items < 1
          return 0
        end
        start_index, end_index = get_slice_bounds(total_items)
        end_index - start_index
      end

      def on_first_page? : Bool
        @page == 0
      end

      def on_last_page? : Bool
        @page >= @total_pages - 1
      end

      def prev_page
        if @page > 0
          @page -= 1
        end
      end

      def next_page
        if !on_last_page?
          @page += 1
        end
      end

      def view : View
        content = case @type
        when Type::Arabic
          sprintf(@arabic_format, @page + 1, @total_pages)
        when Type::Dots
          String.build do |s|
            @total_pages.times do |i|
              if i == @page
                s << @active_dot
              else
                s << @inactive_dot
              end
            end
          end
        else
          ""
        end
        View.new(content: content)
      end
    end
  end
end
