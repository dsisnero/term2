module Lipgloss
  class WrapWriter
    @io : IO
    @active_style : String?
    @active_link : String?

    def initialize(@io : IO)
      @active_style = nil
      @active_link = nil
    end

    def write(input : Bytes) : Int32
      i = 0
      while i < input.size
        byte = input[i]

        if byte == 0x1b_u8
          sequence, consumed = read_escape(input, i)
          @io << sequence
          consume_escape(sequence)
          i += consumed
          next
        end

        if byte == '\n'.ord.to_u8
          @io << "\e[0m" if @active_style
          @io << "\e]8;;\a" if @active_link
          @io << '\n'
          @io << @active_link if @active_link
          @io << @active_style if @active_style
          i += 1
          next
        end

        @io.write_byte(byte)
        i += 1
      end

      input.size
    end

    def write(input : String) : Int32
      write(input.to_slice)
    end

    def close : Nil
      @io << "\e[0m" if @active_style
      @io << "\e]8;;\a" if @active_link
    end

    private def read_escape(input : Bytes, start_idx : Int32) : {String, Int32}
      return {"\e", 1} if start_idx + 1 >= input.size

      if input[start_idx + 1] == '['.ord.to_u8
        j = start_idx + 2
        while j < input.size
          final = input[j]
          j += 1
          break if final >= 0x40_u8 && final <= 0x7e_u8
        end
        return {String.new(input[start_idx, j - start_idx]), j - start_idx}
      end

      if input[start_idx + 1] == ']'.ord.to_u8
        j = start_idx + 2
        while j < input.size
          b = input[j]
          j += 1
          break if b == 0x07_u8
          if b == 0x1b_u8 && j < input.size && input[j] == '\\'.ord.to_u8
            j += 1
            break
          end
        end
        return {String.new(input[start_idx, j - start_idx]), j - start_idx}
      end

      {String.new(input[start_idx, 2]), 2}
    end

    private def consume_escape(sequence : String) : Nil
      if sequence.starts_with?("\e[") && sequence.ends_with?('m')
        if sequence == "\e[m" || sequence == "\e[0m"
          @active_style = nil
        else
          @active_style = sequence
        end
        return
      end

      return unless sequence.starts_with?("\e]8;")

      payload = sequence[3...-1]? || ""
      parts = payload.split(';', 3)
      if parts.size >= 3 && !parts[2].empty?
        @active_link = sequence
      else
        @active_link = nil
      end
    end
  end

  def self.wrap(str : String, width : Int32, _breakpoints : String = "") : String
    wrapped = Cellwrap.wrap(str, width)
    io = IO::Memory.new
    writer = WrapWriter.new(io)
    writer.write(wrapped)
    writer.close
    io.to_s
  end
end
