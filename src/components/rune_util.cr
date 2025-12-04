require "../term2"

module Term2
  module Components
    module RuneUtil
      # Returns the display width of the string.
      # Currently wraps Term2::Style.width (naive implementation).
      # TODO: Implement proper East Asian Width calculation.
      def self.term_width(s : String) : Int32
        Term2::Text.width(s)
      end

      # Sanitizer options (mirroring bubbles API)
      alias Option = Proc(Sanitizer, Sanitizer)

      # Sanitizer removes control characters from rune arrays and optionally
      # replaces newlines/tabs.
      struct Sanitizer
        getter replace_new_line : Array(Char)
        getter replace_tab : Array(Char)

        def initialize(@replace_new_line : Array(Char) = ['\n'], @replace_tab : Array(Char) = Array.new(4, ' '))
        end

        def sanitize(runes : Array(Char)) : Array(Char)
          dest = [] of Char
          runes.each do |r|
            case r
            when '\r', '\n'
              dest.concat(@replace_new_line)
            when '\t'
              dest.concat(@replace_tab)
            else
              code = r.ord
              # Skip other control characters
              next if code < 0x20 || code == 0x7f
              dest << r
            end
          end
          dest
        end
      end

      def self.new_sanitizer(*opts : Option) : Sanitizer
        sanitizer = Sanitizer.new
        opts.each do |opt|
          sanitizer = opt.call(sanitizer)
        end
        sanitizer
      end

      def self.replace_tabs(tab_repl : String) : Option
        ->(s : Sanitizer) { Sanitizer.new(s.replace_new_line, tab_repl.chars) }
      end

      def self.replace_newlines(nl_repl : String) : Option
        ->(s : Sanitizer) { Sanitizer.new(nl_repl.chars, s.replace_tab) }
      end

      # Convenience to sanitize a String into another String
      def self.sanitize(s : String, *opts : Option) : String
        sanitizer = new_sanitizer(*opts)
        String.build do |io|
          sanitizer.sanitize(s.chars).each { |c| io << c }
        end
      end
    end
  end
end
