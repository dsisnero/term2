# OSC (Operating System Command) parsing for terminal escape sequences
#
# Handles OSC sequences introduced by ESC ] (0x1B 0x5D) or the C1 OSC character (0x9D).
# Sequences are terminated by BEL (0x07), ST (0x9C), or ESC \ (0x1B 0x5C).
#
# Supported OSC commands:
# - 10: Foreground color report
# - 11: Background color report
# - 12: Cursor color report
# - 52: Clipboard read/write
#
# Based on charmbracelet/x/input/parse.go.

require "./base_types"
require "lipgloss"
require "base64"

module Term2
  # C1 control characters (ISO 6429)
  private BEL    = 0x07_u8
  private ST     = 0x9C_u8
  private C1_OSC = 0x9D_u8
  private ESC    = 0x1B_u8
  private CAN    = 0x18_u8
  private SUB    = 0x1A_u8

  # OSC parsing utilities
  module OSC
    extend self

    # Parses an OSC sequence from the given buffer.
    # Returns a tuple of {Message?, consumed_bytes} where consumed_bytes is the number of
    # bytes parsed (0 if not an OSC sequence or incomplete).
    def parse(buffer : String) : {Message?, Int32}
      return {nil, 0} if buffer.empty?
      bytes = buffer.to_slice
      i = 0
      # Check for 8-bit OSC or ESC prefix
      if bytes[i] == C1_OSC
        i += 1
      elsif bytes[i] == ESC && i + 1 < bytes.size && bytes[i + 1] == ']'.ord
        i += 2
      else
        return {nil, 0}
      end

      # Parse command number
      cmd = 0
      while i < bytes.size && bytes[i] >= '0'.ord && bytes[i] <= '9'.ord
        cmd = cmd * 10 + (bytes[i] - '0'.ord)
        i += 1
      end

      # If we have no semicolon yet, sequence is incomplete
      return {nil, 0} if i >= bytes.size || bytes[i] != ';'.ord
      i += 1

      start = i
      # Scan until terminator
      while i < bytes.size
        b = bytes[i]
        if b == BEL || b == ST || b == CAN || b == SUB
          break
        elsif b == ESC && i + 1 < bytes.size && bytes[i + 1] == '\\'.ord
          # ST terminator (ESC \)
          break
        end
        i += 1
      end
      # No terminator found -> incomplete sequence
      return {nil, 0} if i >= bytes.size

      # Determine terminator length
      term_len = 1
      if bytes[i] == ESC
        term_len = 2
      end

      data = String.new(bytes[start...i])
      consumed = i + term_len

      # Dispatch based on command number
      msg = case cmd
            when 10
              if color = parse_color(data)
                ForegroundColorMsg.new(color)
              end
            when 11
              if color = parse_color(data)
                BackgroundColorMsg.new(color)
              end
            when 12
              if color = parse_color(data)
                CursorColorMsg.new(color)
              end
            when 52
              parse_clipboard(data)
            else
              nil # Unknown OSC command, ignore
            end
      {msg, consumed}
    end

    private def parse_color(data : String) : Lipgloss::Color?
      # OSC color format: "rgb:RRRR/GGGG/BBBB" where each component is 4 hex digits (0-65535)
      # Also supports "#RRGGBB", "rgb:RR/GG/BB", "rgba:RR/GG/BB/AA", etc.
      # Simplified: assume rgb:RRRR/GGGG/BBBB
      return unless data.starts_with?("rgb:")
      parts = data[4..].split('/')
      return unless parts.size == 3
      begin
        r = parts[0].to_i(16)
        g = parts[1].to_i(16)
        b = parts[2].to_i(16)
        # Convert 16-bit to 8-bit (most significant byte)
        r = (r >> 8) & 0xFF
        g = (g >> 8) & 0xFF
        b = (b >> 8) & 0xFF
        Lipgloss::Color.new(Lipgloss::Color::Type::RGB, {r, g, b})
      rescue
        nil
      end
    end

    private def parse_clipboard(data : String) : Message?
      # OSC 52 format: "<selection>;<base64>"
      parts = data.split(';', 2)
      return unless parts.size == 2
      selection = parts[0]
      return if selection.empty?
      b64 = parts[1]
      begin
        content = Base64.decode_string(b64)
        ClipboardMsg.new(content, selection[0].ord.to_u8)
      rescue
        nil
      end
    end
  end

  # OSCReader handles parsing OSC events from terminal input.
  class OSCReader
    @buffer : String = ""

    # Check if the given buffer contains a complete OSC event.
    # Returns a tuple of {Message?, consumed_bytes} where consumed_bytes is the number of
    # bytes that belong to the OSC sequence (0 if not an OSC sequence or incomplete).
    def check_osc_event(buffer : String) : {Message?, Int32}
      OSC.parse(buffer)
    end

    # Read an OSC event from the given IO.
    # Returns nil if no complete OSC event is available.
    def read_osc_event(io : IO) : Message?
      char = io.read_char
      return unless char
      @buffer += char.to_s
      msg, consumed = OSC.parse(@buffer)
      if msg && consumed > 0
        @buffer = @buffer[consumed..] || ""
        msg
      end
    rescue IO::EOFError
      nil
    end
  end
end
