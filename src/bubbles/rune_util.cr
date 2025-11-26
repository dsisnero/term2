require "../term2"

module Term2
  module Bubbles
    module RuneUtil
      # Returns the display width of the string.
      # Currently wraps Term2::Style.width (naive implementation).
      # TODO: Implement proper East Asian Width calculation.
      def self.term_width(s : String) : Int32
        Term2::Text.width(s)
      end

      # Sanitize string (replace tabs, newlines, etc. if needed)
      # Replaces tabs with 4 spaces and newlines with space.
      def self.sanitize(s : String) : String
        s.gsub("\t", "    ").gsub(/[\r\n]/, " ")
      end
    end
  end
end
