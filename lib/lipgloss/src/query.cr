module Lipgloss
  OSC_BG_QUERY = "\e]11;?\a"

  def self.background_color(input : IO = STDIN, output : IO = STDOUT) : Color
    if response = query_background_response(input, output)
      if parsed = parse_background_response(response)
        return parsed
      end
    end

    # Fallback to renderer preference when a terminal query is unavailable.
    has_dark_background? ? Color.new(Color::Type::Named, 0) : Color.new(Color::Type::Named, 15)
  end

  def self.has_dark_background(input : IO = STDIN, output : IO = STDOUT) : Bool
    bg = background_color(input, output)
    r, g, b = bg.to_rgb
    ((0.299 * r) + (0.587 * g) + (0.114 * b)) < 128.0
  end

  private def self.query_background_response(input : IO, output : IO) : String?
    output << OSC_BG_QUERY
    output.flush

    if input.is_a?(IO::Memory)
      return input.gets_to_end
    end

    return nil unless input.is_a?(IO::FileDescriptor)

    fd = input.as(IO::FileDescriptor)
    previous_timeout = fd.read_timeout
    fd.read_timeout = 120.milliseconds

    response = String.build do |io|
      loop do
        begin
          byte = fd.read_byte
          break unless byte
          char = byte.unsafe_chr
          io << char
          break if char == '\a'
        rescue IO::TimeoutError
          break
        end
      end
    end
    fd.read_timeout = previous_timeout

    response.empty? ? nil : response
  rescue
    nil
  end

  private def self.parse_background_response(response : String) : Color?
    if match = /11;rgb:([0-9a-fA-F]+)\/([0-9a-fA-F]+)\/([0-9a-fA-F]+)/.match(response)
      r = hex_component_to_u8(match[1])
      g = hex_component_to_u8(match[2])
      b = hex_component_to_u8(match[3])
      return Color.rgb(r, g, b)
    end

    nil
  end

  private def self.hex_component_to_u8(hex : String) : Int32
    value = hex.to_i(16)
    max = ((1_i64 << (4 * hex.size)) - 1).to_f
    return 0 if max <= 0
    ((value.to_f / max) * 255.0).round.to_i.clamp(0, 255)
  end
end
