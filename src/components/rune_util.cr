require "../term2"

module Term2
  module Components
    module RuneUtil
      alias Sanitizer = Proc(String, String)

      # Returns the display width of the string.
      # Currently wraps Term2::Style.width (naive implementation).
      # TODO: Implement proper East Asian Width calculation.
      def self.term_width(s : String) : Int32
        Term2::Text.width(s)
      end

      # Sanitize string (replace tabs, newlines, etc. if needed)
      # Replaces tabs with 4 spaces and newlines with space.
      # Also removes escape characters (\x1b).
      def self.sanitize(s : String) : String
        sanitize(s, replace_newlines(" "))
      end

      def self.sanitize(s : String, *mods : Sanitizer) : String
        result = s.gsub("\t", "    ").gsub("\x1b", "")
        mods.each do |mod|
          result = mod.call(result)
        end
        result
      end

      def self.replace_newlines(replacement : String) : Sanitizer
        ->(str : String) { str.gsub(/[\r\n]/, replacement) }
      end
    end
  end
end
