require "../style"

module Term2
  module Components
    struct TableStyles
      property header : Style
      property cell : Style
      property selected : Style

      def initialize(@header : Style = Style.new, @cell : Style = Style.new, @selected : Style = Style.new)
      end

      def self.default : TableStyles
        TableStyles.new(
          Style.new.padding(0, 1),
          Style.new.padding(0, 1),
          Style.new,
        )
      end
    end
  end
end
