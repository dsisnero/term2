require "../../../src/term2"
require "../../../src/components/text_input"

module QueryTermExample
  include Term2::Prelude

  class Model
    include Term2::Model

    property input : Term2::Components::TextInput
    property error : String?

    def initialize
      @input = Term2::Components::TextInput.new
      @input.char_limit = 156
      @input.width = 20
      @input.virtual_cursor = false
      @input.focus
    end

    def init : Term2::Cmd
      Term2::Cmds.none
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      cmds = [] of Term2::Cmd

      case msg
      when Term2::KeyMsg
        @error = nil
        case msg.string
        when "ctrl+c"
          return {self, Term2.quit}
        when "enter"
          val = @input.value
          val = "\"" + val + "\""
          begin
            seq = unescape_sequence(val)
          rescue ex
            @error = ex.message
            return {self, Term2::Cmds.none}
          end

          unless seq.starts_with?("\e")
            @error = "sequence is not an ANSI escape sequence"
            return {self, Term2::Cmds.none}
          end

          @input.set_value("")
          return {self, -> : Term2::Msg? do
            STDOUT << seq
            nil
          end}
        end
      else
        type_name = msg.class.name
        if type_name.size > 0 && type_name[0].ascii_uppercase?
          cmds << Term2::Cmds.printf("Received message: %s %s", msg.class.name, msg.inspect)
        end
      end

      @input, cmd = @input.update(msg)
      cmds << cmd
      {self, Term2::Cmds.batch(cmds)}
    end

    def view : Term2::View
      input_view = @input.view
      input_content = input_view.is_a?(String) ? input_view : input_view.content

      content = String.build do |io|
        io << input_content
        if err = @error
          io << "\n\nError: " << err
        end
        io << "\n\nPress ctrl+c to quit, enter to write the sequence to terminal"
      end

      Term2::View.new(content: content)
    end

    private def unescape_sequence(input : String) : String
      str = input
      if str.starts_with?('"') && str.ends_with?('"') && str.size >= 2
        str = str[1...-1]
      end

      String.build do |io|
        i = 0
        while i < str.size
          ch = str.byte_at(i)
          if ch == '\\'.ord && i + 1 < str.size
            i += 1
            esc = str.byte_at(i).chr
            case esc
            when "e"
              io << '\e'
            when "n"
              io << '\n'
            when "r"
              io << '\r'
            when "t"
              io << '\t'
            when "\\"
              io << '\\'
            when "\""
              io << '"'
            when "x"
              if i + 2 < str.size
                hex = str[(i + 1)..(i + 2)]
                io << hex.to_i(16).chr
                i += 2
              else
                raise ArgumentError.new("invalid escape sequence")
              end
            else
              io << esc
            end
          else
            io << ch.chr
          end
          i += 1
        end
      end
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(QueryTermExample::Model.new)
end
