module Term2
  module LipGloss
    class List
      enum Enumerator
        Bullet
        Arabic
        Alphabet
      end

      property items : Array(String | List)
      property enumerator : Enumerator
      property item_style : Style
      property enumerator_style : Style
      property item_style_func : Proc(Int32, String, Style)?
      property enumerator_style_func : Proc(Int32, Style)?
      property enumerator_func : Proc(Int32, String)?

      def initialize
        @items = [] of String | List
        @enumerator = Enumerator::Bullet
        @item_style = Style.new
        @enumerator_style = Style.new
      end

      def items(*items : String | List)
        @items = items.to_a.map(&.as(String | List))
        self
      end

      def items(items : Array(String | List))
        @items = items
        self
      end

      def item(item : String | List)
        @items << item
        self
      end

      def enumerator(e : Enumerator)
        @enumerator = e
        self
      end

      def item_style(s : Style)
        @item_style = s
        self
      end

      def enumerator_style(s : Style)
        @enumerator_style = s
        self
      end

      def render : String
        @items.map_with_index do |item, i|
          enum_str = get_enumerator(i)
          enum_rendered = @enumerator_style.render(enum_str)

          content = if item.is_a?(List)
                      item.render
                    else
                      @item_style.render(item.to_s)
                    end

          lines = content.split('\n')
          if lines.empty?
            "#{enum_rendered} "
          else
            first_line = lines[0]
            prefix = "#{enum_rendered} "
            indent = " " * Term2::LipGloss.width(prefix)

            res = ["#{prefix}#{first_line}"]
            lines[1..-1].each do |line|
              res << "#{indent}#{line}"
            end
            res.join("\n")
          end
        end.join("\n")
      end

      private def get_enumerator(index : Int32) : String
        case @enumerator
        when Enumerator::Bullet
          "•"
        when Enumerator::Arabic
          "#{index + 1}."
        when Enumerator::Alphabet
          "#{(('A'.ord) + (index % 26)).chr}."
        else
          ""
        end
      end
    end
  end
end
