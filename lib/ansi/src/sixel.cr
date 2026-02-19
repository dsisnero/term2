require "colorful"

module Ansi
  module Sixel
    LineBreak        = '-'.ord.to_u8
    CarriageReturn   = '$'.ord.to_u8
    RepeatIntroducer = '!'.ord.to_u8
    ColorIntroducer  = '#'.ord.to_u8
    RasterAttribute  = '"'.ord.to_u8

    MaxColors =     256
    ST        = 0x9C_u8
    ESC       = 0x1B_u8
    BEL       = 0x07_u8

    class ErrInvalidRaster < Exception
    end

    class ErrInvalidColor < Exception
    end

    class ErrInvalidRepeat < Exception
    end

    def self.write_raster(io : IO, pan : Int32, pad : Int32, ph : Int32, pv : Int32) : Int32
      if pad == 0
        return write_raster(io, 1, 1, ph, pv)
      end
      if ph <= 0 && pv <= 0
        io.write_byte(RasterAttribute)
        io << pan << ';' << pad
        return 0
      end
      io.write_byte(RasterAttribute)
      io << pan << ';' << pad << ';' << ph << ';' << pv
      0
    end

    struct Raster
      getter pan : Int32
      getter pad : Int32
      getter ph : Int32
      getter pv : Int32

      def initialize(@pan : Int32, @pad : Int32, @ph : Int32 = 0, @pv : Int32 = 0)
      end

      def to_s : String
        String.build { |io| Sixel.write_raster(io, @pan, @pad, @ph, @pv) }
      end
    end

    def self.write_repeat(io : IO, count : Int32, char : Char) : Int32
      io.write_byte(RepeatIntroducer)
      io << count << char
      0
    end

    struct Repeat
      getter count : Int32
      getter char : Char

      def initialize(@count : Int32, @char : Char)
      end

      def to_s : String
        String.build { |io| Sixel.write_repeat(io, @count, @char) }
      end
    end

    def self.write_color(io : IO, pc : Int32, pu : Int32, px : Int32, py : Int32, pz : Int32) : Int32
      if pu <= 0 || pu > 2
        io.write_byte(ColorIntroducer)
        io << pc
        return 0
      end
      io.write_byte(ColorIntroducer)
      io << pc << ';' << pu << ';' << px << ';' << py << ';' << pz
      0
    end

    # FromColor returns a Sixel color from a color. It converts the color
    # channels to the 0-100 range.
    def self.from_color(color : Ansi::Color) : Color
      r16, g16, b16, _ = color.rgba
      Color.new(
        pc: 0,
        pu: 2,
        px: convert_channel(r16).to_i32,
        py: convert_channel(g16).to_i32,
        pz: convert_channel(b16).to_i32
      )
    end

    # ameba:disable Metrics/CyclomaticComplexity
    def self.decode_color(data : Bytes) : {Color, Int32}
      n = 0
      return {Color.new, n} if data.empty? || data[0] != ColorIntroducer
      if data.size < 2
        return {Color.new, n}
      end

      pc = 0
      pu = 0
      px = 0
      py = 0
      pz = 0

      n = 1
      # Parse pc and possibly pu
      parsing_pc = true
      while n < data.size
        ch = data[n]
        if ch == ';'.ord
          if parsing_pc
            parsing_pc = false
          else
            n += 1
            break
          end
        elsif ch >= '0'.ord && ch <= '9'.ord
          if parsing_pc
            pc = pc * 10 + (ch - '0'.ord).to_i32
          else
            pu = pu * 10 + (ch - '0'.ord).to_i32
          end
        else
          break
        end
        n += 1
      end

      # Parse px, py, pz
      component = 0
      parsing_px = true
      while n < data.size
        ch = data[n]
        if ch == ';'.ord
          if parsing_px
            parsing_px = false
            component = 1
          elsif component == 1
            component = 2
          else
            n += 1
            break
          end
        elsif ch >= '0'.ord && ch <= '9'.ord
          case component
          when 0
            px = px * 10 + (ch - '0'.ord).to_i32
          when 1
            py = py * 10 + (ch - '0'.ord).to_i32
          when 2
            pz = pz * 10 + (ch - '0'.ord).to_i32
          end
        else
          break
        end
        n += 1
      end

      {Color.new(pc, pu, px, py, pz), n}
    end

    def self.decode_raster(data : Bytes) : {Raster, Int32}
      n = 0
      return {Raster.new(0, 0, 0, 0), n} if data.empty? || data[0] != RasterAttribute

      pan = 0
      pad = 0
      ph = 0
      pv = 0

      n = 1
      component = 0
      while n < data.size
        ch = data[n]
        if ch == ';'.ord
          component += 1
        elsif ch >= '0'.ord && ch <= '9'.ord
          case component
          when 0
            pan = pan * 10 + (ch - '0'.ord).to_i32
          when 1
            pad = pad * 10 + (ch - '0'.ord).to_i32
          when 2
            ph = ph * 10 + (ch - '0'.ord).to_i32
          when 3
            pv = pv * 10 + (ch - '0'.ord).to_i32
          end
        else
          break
        end
        n += 1
      end

      {Raster.new(pan, pad, ph, pv), n}
    end

    def self.decode_repeat(data : Bytes) : {Repeat, Int32}
      r = Repeat.new(0, '\0')
      n = 0
      return {r, n} if data.empty? || data[0] != RepeatIntroducer

      # Minimum length is 3: introducer, at least one digit, and a character
      if data.size < 3
        return {r, n}
      end

      n = 1
      count = 0
      while n < data.size && data[n] >= '0'.ord && data[n] <= '9'.ord
        count = count * 10 + (data[n] - '0'.ord).to_i32
        n += 1
      end

      # If we reached end of data without finding a non-digit character
      if n >= data.size
        return {r, 0}
      end

      r = Repeat.new(count, data[n].chr)
      n += 1
      {r, n}
    end

    private def self.palval(n : Int32, a : Int32, m : Int32) : Int32
      (n * a + m // 2) // m
    end

    def self.sixel_rgb(r : Int32, g : Int32, b : Int32) : Ansi::Color
      Ansi::Color.new(
        palval(r, 0xff, 100).to_u8,
        palval(g, 0xff, 100).to_u8,
        palval(b, 0xff, 100).to_u8,
        0xFF_u8
      )
    end

    def self.sixel_hls(h : Int32, l : Int32, s : Int32) : Ansi::Color
      # Use Colorful library for HSL to RGB conversion (matches Go's colorful.Hsl)
      hue = h.to_f64
      saturation = s.to_f64 / 100.0
      lightness = l.to_f64 / 100.0
      colorful_color = Colorful::Color.hsl(hue, saturation, lightness).clamped
      # Handle floating point precision errors by rounding with tolerance
      # Values very close to 0 should be 0, values very close to 1 should be 1
      r_f = colorful_color.r
      g_f = colorful_color.g
      b_f = colorful_color.b

      # Tolerance for floating point errors in HSL conversion
      tolerance = 0.004

      # Adjust values very close to 0 or 1
      r_f = 0.0 if r_f.abs < tolerance
      g_f = 0.0 if g_f.abs < tolerance
      b_f = 0.0 if b_f.abs < tolerance
      r_f = 1.0 if (r_f - 1.0).abs < tolerance
      g_f = 1.0 if (g_f - 1.0).abs < tolerance
      b_f = 1.0 if (b_f - 1.0).abs < tolerance

      # Clamp to valid range
      r_f = r_f.clamp(0.0, 1.0)
      g_f = g_f.clamp(0.0, 1.0)
      b_f = b_f.clamp(0.0, 1.0)

      # Convert from Float64 0-1 to UInt8 0-255
      r = (r_f * 255.0 + 0.5).to_i.clamp(0, 255)
      g = (g_f * 255.0 + 0.5).to_i.clamp(0, 255)
      b = (b_f * 255.0 + 0.5).to_i.clamp(0, 255)
      Ansi::Color.new(r.to_u8, g.to_u8, b.to_u8, 0xFF_u8)
    end

    def self.convert_channel(c16 : UInt32) : UInt32
      (((c16 + 328_u32) * 100_u32) / 0xffff_u32).to_u32
    end

    # Default palette for Sixel images. This is a combination of the Sixel
    # default colors and the xterm colors.
    private DEFAULT_PALETTE = [
      Ansi::Color.new(0_u8, 0_u8, 0_u8, 255_u8),
      Ansi::Color.new(51_u8, 51_u8, 204_u8, 255_u8),
      Ansi::Color.new(204_u8, 36_u8, 36_u8, 255_u8),
      Ansi::Color.new(51_u8, 204_u8, 51_u8, 255_u8),
      Ansi::Color.new(204_u8, 51_u8, 204_u8, 255_u8),
      Ansi::Color.new(51_u8, 204_u8, 204_u8, 255_u8),
      Ansi::Color.new(204_u8, 204_u8, 51_u8, 255_u8),
      Ansi::Color.new(120_u8, 120_u8, 120_u8, 255_u8),
      Ansi::Color.new(69_u8, 69_u8, 69_u8, 255_u8),
      Ansi::Color.new(87_u8, 87_u8, 153_u8, 255_u8),
      Ansi::Color.new(153_u8, 69_u8, 69_u8, 255_u8),
      Ansi::Color.new(87_u8, 153_u8, 87_u8, 255_u8),
      Ansi::Color.new(153_u8, 87_u8, 153_u8, 255_u8),
      Ansi::Color.new(87_u8, 153_u8, 153_u8, 255_u8),
      Ansi::Color.new(153_u8, 153_u8, 87_u8, 255_u8),
      Ansi::Color.new(204_u8, 204_u8, 204_u8, 255_u8),
      Ansi::Color.new(0_u8, 0_u8, 0_u8, 255_u8),
      Ansi::Color.new(0_u8, 0_u8, 95_u8, 255_u8),
      Ansi::Color.new(0_u8, 0_u8, 135_u8, 255_u8),
      Ansi::Color.new(0_u8, 0_u8, 175_u8, 255_u8),
      Ansi::Color.new(0_u8, 0_u8, 215_u8, 255_u8),
      Ansi::Color.new(0_u8, 0_u8, 255_u8, 255_u8),
      Ansi::Color.new(0_u8, 95_u8, 0_u8, 255_u8),
      Ansi::Color.new(0_u8, 95_u8, 95_u8, 255_u8),
      Ansi::Color.new(0_u8, 95_u8, 135_u8, 255_u8),
      Ansi::Color.new(0_u8, 95_u8, 175_u8, 255_u8),
      Ansi::Color.new(0_u8, 95_u8, 215_u8, 255_u8),
      Ansi::Color.new(0_u8, 95_u8, 255_u8, 255_u8),
      Ansi::Color.new(0_u8, 135_u8, 0_u8, 255_u8),
      Ansi::Color.new(0_u8, 135_u8, 95_u8, 255_u8),
      Ansi::Color.new(0_u8, 135_u8, 0_u8, 255_u8),
      Ansi::Color.new(0_u8, 135_u8, 175_u8, 255_u8),
      Ansi::Color.new(0_u8, 125_u8, 215_u8, 255_u8),
      Ansi::Color.new(0_u8, 135_u8, 255_u8, 255_u8),
      Ansi::Color.new(0_u8, 175_u8, 0_u8, 255_u8),
      Ansi::Color.new(0_u8, 175_u8, 95_u8, 255_u8),
      Ansi::Color.new(0_u8, 175_u8, 135_u8, 255_u8),
      Ansi::Color.new(0_u8, 175_u8, 175_u8, 255_u8),
      Ansi::Color.new(0_u8, 175_u8, 215_u8, 255_u8),
      Ansi::Color.new(0_u8, 175_u8, 255_u8, 255_u8),
      Ansi::Color.new(0_u8, 215_u8, 0_u8, 255_u8),
      Ansi::Color.new(0_u8, 215_u8, 95_u8, 255_u8),
      Ansi::Color.new(0_u8, 215_u8, 135_u8, 255_u8),
      Ansi::Color.new(0_u8, 215_u8, 175_u8, 255_u8),
      Ansi::Color.new(0_u8, 215_u8, 215_u8, 255_u8),
      Ansi::Color.new(0_u8, 215_u8, 255_u8, 255_u8),
      Ansi::Color.new(0_u8, 255_u8, 0_u8, 255_u8),
      Ansi::Color.new(0_u8, 255_u8, 95_u8, 255_u8),
      Ansi::Color.new(0_u8, 255_u8, 135_u8, 255_u8),
      Ansi::Color.new(0_u8, 255_u8, 175_u8, 255_u8),
      Ansi::Color.new(0_u8, 255_u8, 215_u8, 255_u8),
      Ansi::Color.new(0_u8, 255_u8, 255_u8, 255_u8),
      Ansi::Color.new(95_u8, 0_u8, 0_u8, 255_u8),
      Ansi::Color.new(95_u8, 0_u8, 95_u8, 255_u8),
      Ansi::Color.new(95_u8, 0_u8, 135_u8, 255_u8),
      Ansi::Color.new(95_u8, 0_u8, 175_u8, 255_u8),
      Ansi::Color.new(95_u8, 0_u8, 215_u8, 255_u8),
      Ansi::Color.new(95_u8, 0_u8, 255_u8, 255_u8),
      Ansi::Color.new(95_u8, 95_u8, 0_u8, 255_u8),
      Ansi::Color.new(95_u8, 95_u8, 95_u8, 255_u8),
      Ansi::Color.new(95_u8, 95_u8, 135_u8, 255_u8),
      Ansi::Color.new(95_u8, 95_u8, 175_u8, 255_u8),
      Ansi::Color.new(95_u8, 95_u8, 215_u8, 255_u8),
      Ansi::Color.new(95_u8, 95_u8, 255_u8, 255_u8),
      Ansi::Color.new(95_u8, 135_u8, 0_u8, 255_u8),
      Ansi::Color.new(95_u8, 135_u8, 95_u8, 255_u8),
      Ansi::Color.new(95_u8, 135_u8, 135_u8, 255_u8),
      Ansi::Color.new(95_u8, 135_u8, 175_u8, 255_u8),
      Ansi::Color.new(95_u8, 135_u8, 215_u8, 255_u8),
      Ansi::Color.new(95_u8, 135_u8, 255_u8, 255_u8),
      Ansi::Color.new(95_u8, 175_u8, 0_u8, 255_u8),
      Ansi::Color.new(95_u8, 175_u8, 95_u8, 255_u8),
      Ansi::Color.new(95_u8, 175_u8, 135_u8, 255_u8),
      Ansi::Color.new(95_u8, 175_u8, 175_u8, 255_u8),
      Ansi::Color.new(95_u8, 175_u8, 215_u8, 255_u8),
      Ansi::Color.new(95_u8, 175_u8, 255_u8, 255_u8),
      Ansi::Color.new(95_u8, 215_u8, 0_u8, 255_u8),
      Ansi::Color.new(95_u8, 215_u8, 95_u8, 255_u8),
      Ansi::Color.new(95_u8, 215_u8, 135_u8, 255_u8),
      Ansi::Color.new(95_u8, 215_u8, 175_u8, 255_u8),
      Ansi::Color.new(95_u8, 215_u8, 215_u8, 255_u8),
      Ansi::Color.new(95_u8, 215_u8, 255_u8, 255_u8),
      Ansi::Color.new(95_u8, 255_u8, 0_u8, 255_u8),
      Ansi::Color.new(95_u8, 255_u8, 95_u8, 255_u8),
      Ansi::Color.new(95_u8, 255_u8, 135_u8, 255_u8),
      Ansi::Color.new(95_u8, 255_u8, 175_u8, 255_u8),
      Ansi::Color.new(95_u8, 255_u8, 215_u8, 255_u8),
      Ansi::Color.new(95_u8, 255_u8, 255_u8, 255_u8),
      Ansi::Color.new(135_u8, 0_u8, 0_u8, 255_u8),
      Ansi::Color.new(135_u8, 0_u8, 95_u8, 255_u8),
      Ansi::Color.new(135_u8, 0_u8, 135_u8, 255_u8),
      Ansi::Color.new(135_u8, 0_u8, 175_u8, 255_u8),
      Ansi::Color.new(135_u8, 0_u8, 215_u8, 255_u8),
      Ansi::Color.new(135_u8, 0_u8, 255_u8, 255_u8),
      Ansi::Color.new(135_u8, 95_u8, 0_u8, 255_u8),
      Ansi::Color.new(135_u8, 95_u8, 95_u8, 255_u8),
      Ansi::Color.new(135_u8, 95_u8, 135_u8, 255_u8),
      Ansi::Color.new(135_u8, 95_u8, 175_u8, 255_u8),
      Ansi::Color.new(135_u8, 95_u8, 215_u8, 255_u8),
      Ansi::Color.new(135_u8, 95_u8, 255_u8, 255_u8),
      Ansi::Color.new(135_u8, 135_u8, 0_u8, 255_u8),
      Ansi::Color.new(135_u8, 135_u8, 95_u8, 255_u8),
      Ansi::Color.new(135_u8, 135_u8, 135_u8, 255_u8),
      Ansi::Color.new(135_u8, 135_u8, 175_u8, 255_u8),
      Ansi::Color.new(135_u8, 135_u8, 215_u8, 255_u8),
      Ansi::Color.new(135_u8, 135_u8, 255_u8, 255_u8),
      Ansi::Color.new(135_u8, 175_u8, 0_u8, 255_u8),
      Ansi::Color.new(135_u8, 175_u8, 95_u8, 255_u8),
      Ansi::Color.new(135_u8, 175_u8, 135_u8, 255_u8),
      Ansi::Color.new(135_u8, 175_u8, 175_u8, 255_u8),
      Ansi::Color.new(135_u8, 175_u8, 215_u8, 255_u8),
      Ansi::Color.new(135_u8, 175_u8, 255_u8, 255_u8),
      Ansi::Color.new(135_u8, 215_u8, 0_u8, 255_u8),
      Ansi::Color.new(135_u8, 215_u8, 95_u8, 255_u8),
      Ansi::Color.new(135_u8, 215_u8, 135_u8, 255_u8),
      Ansi::Color.new(135_u8, 215_u8, 175_u8, 255_u8),
      Ansi::Color.new(135_u8, 215_u8, 215_u8, 255_u8),
      Ansi::Color.new(135_u8, 215_u8, 255_u8, 255_u8),
      Ansi::Color.new(135_u8, 255_u8, 0_u8, 255_u8),
      Ansi::Color.new(135_u8, 255_u8, 95_u8, 255_u8),
      Ansi::Color.new(135_u8, 255_u8, 135_u8, 255_u8),
      Ansi::Color.new(135_u8, 255_u8, 175_u8, 255_u8),
      Ansi::Color.new(135_u8, 255_u8, 215_u8, 255_u8),
      Ansi::Color.new(135_u8, 255_u8, 255_u8, 255_u8),
      Ansi::Color.new(175_u8, 0_u8, 0_u8, 255_u8),
      Ansi::Color.new(175_u8, 0_u8, 95_u8, 255_u8),
      Ansi::Color.new(175_u8, 0_u8, 135_u8, 255_u8),
      Ansi::Color.new(175_u8, 0_u8, 175_u8, 255_u8),
      Ansi::Color.new(175_u8, 0_u8, 215_u8, 255_u8),
      Ansi::Color.new(175_u8, 0_u8, 255_u8, 255_u8),
      Ansi::Color.new(175_u8, 95_u8, 0_u8, 255_u8),
      Ansi::Color.new(175_u8, 95_u8, 95_u8, 255_u8),
      Ansi::Color.new(175_u8, 95_u8, 135_u8, 255_u8),
      Ansi::Color.new(175_u8, 95_u8, 175_u8, 255_u8),
      Ansi::Color.new(175_u8, 95_u8, 215_u8, 255_u8),
      Ansi::Color.new(175_u8, 95_u8, 255_u8, 255_u8),
      Ansi::Color.new(175_u8, 135_u8, 0_u8, 255_u8),
      Ansi::Color.new(175_u8, 135_u8, 95_u8, 255_u8),
      Ansi::Color.new(175_u8, 135_u8, 135_u8, 255_u8),
      Ansi::Color.new(175_u8, 135_u8, 175_u8, 255_u8),
      Ansi::Color.new(175_u8, 135_u8, 215_u8, 255_u8),
      Ansi::Color.new(175_u8, 135_u8, 255_u8, 255_u8),
      Ansi::Color.new(175_u8, 175_u8, 0_u8, 255_u8),
      Ansi::Color.new(175_u8, 175_u8, 95_u8, 255_u8),
      Ansi::Color.new(175_u8, 175_u8, 135_u8, 255_u8),
      Ansi::Color.new(175_u8, 175_u8, 175_u8, 255_u8),
      Ansi::Color.new(175_u8, 175_u8, 215_u8, 255_u8),
      Ansi::Color.new(175_u8, 175_u8, 255_u8, 255_u8),
      Ansi::Color.new(175_u8, 215_u8, 0_u8, 255_u8),
      Ansi::Color.new(175_u8, 215_u8, 95_u8, 255_u8),
      Ansi::Color.new(175_u8, 215_u8, 135_u8, 255_u8),
      Ansi::Color.new(175_u8, 215_u8, 175_u8, 255_u8),
      Ansi::Color.new(175_u8, 215_u8, 215_u8, 255_u8),
      Ansi::Color.new(175_u8, 215_u8, 255_u8, 255_u8),
      Ansi::Color.new(175_u8, 255_u8, 0_u8, 255_u8),
      Ansi::Color.new(175_u8, 255_u8, 95_u8, 255_u8),
      Ansi::Color.new(175_u8, 255_u8, 135_u8, 255_u8),
      Ansi::Color.new(175_u8, 255_u8, 215_u8, 255_u8),
      Ansi::Color.new(175_u8, 255_u8, 215_u8, 255_u8),
      Ansi::Color.new(175_u8, 255_u8, 255_u8, 255_u8),
      Ansi::Color.new(215_u8, 0_u8, 0_u8, 255_u8),
      Ansi::Color.new(215_u8, 0_u8, 95_u8, 255_u8),
      Ansi::Color.new(215_u8, 0_u8, 135_u8, 255_u8),
      Ansi::Color.new(215_u8, 0_u8, 175_u8, 255_u8),
      Ansi::Color.new(215_u8, 0_u8, 215_u8, 255_u8),
      Ansi::Color.new(215_u8, 0_u8, 255_u8, 255_u8),
      Ansi::Color.new(215_u8, 95_u8, 0_u8, 255_u8),
      Ansi::Color.new(215_u8, 95_u8, 95_u8, 255_u8),
      Ansi::Color.new(215_u8, 95_u8, 135_u8, 255_u8),
      Ansi::Color.new(215_u8, 95_u8, 175_u8, 255_u8),
      Ansi::Color.new(215_u8, 95_u8, 215_u8, 255_u8),
      Ansi::Color.new(215_u8, 95_u8, 255_u8, 255_u8),
      Ansi::Color.new(215_u8, 135_u8, 0_u8, 255_u8),
      Ansi::Color.new(215_u8, 135_u8, 95_u8, 255_u8),
      Ansi::Color.new(215_u8, 135_u8, 135_u8, 255_u8),
      Ansi::Color.new(215_u8, 135_u8, 175_u8, 255_u8),
      Ansi::Color.new(215_u8, 135_u8, 215_u8, 255_u8),
      Ansi::Color.new(215_u8, 135_u8, 255_u8, 255_u8),
      Ansi::Color.new(215_u8, 175_u8, 0_u8, 255_u8),
      Ansi::Color.new(215_u8, 175_u8, 95_u8, 255_u8),
      Ansi::Color.new(215_u8, 175_u8, 135_u8, 255_u8),
      Ansi::Color.new(215_u8, 175_u8, 175_u8, 255_u8),
      Ansi::Color.new(215_u8, 175_u8, 215_u8, 255_u8),
      Ansi::Color.new(215_u8, 175_u8, 255_u8, 255_u8),
      Ansi::Color.new(215_u8, 215_u8, 0_u8, 255_u8),
      Ansi::Color.new(215_u8, 215_u8, 95_u8, 255_u8),
      Ansi::Color.new(215_u8, 215_u8, 135_u8, 255_u8),
      Ansi::Color.new(215_u8, 215_u8, 175_u8, 255_u8),
      Ansi::Color.new(215_u8, 215_u8, 215_u8, 255_u8),
      Ansi::Color.new(215_u8, 215_u8, 255_u8, 255_u8),
      Ansi::Color.new(215_u8, 255_u8, 0_u8, 255_u8),
      Ansi::Color.new(215_u8, 255_u8, 95_u8, 255_u8),
      Ansi::Color.new(215_u8, 255_u8, 135_u8, 255_u8),
      Ansi::Color.new(215_u8, 255_u8, 175_u8, 255_u8),
      Ansi::Color.new(215_u8, 255_u8, 215_u8, 255_u8),
      Ansi::Color.new(215_u8, 255_u8, 255_u8, 255_u8),
      Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8),
      Ansi::Color.new(255_u8, 0_u8, 95_u8, 255_u8),
      Ansi::Color.new(255_u8, 0_u8, 135_u8, 255_u8),
      Ansi::Color.new(255_u8, 0_u8, 175_u8, 255_u8),
      Ansi::Color.new(255_u8, 0_u8, 215_u8, 255_u8),
      Ansi::Color.new(255_u8, 0_u8, 255_u8, 255_u8),
      Ansi::Color.new(255_u8, 95_u8, 0_u8, 255_u8),
      Ansi::Color.new(255_u8, 95_u8, 95_u8, 255_u8),
      Ansi::Color.new(255_u8, 95_u8, 135_u8, 255_u8),
      Ansi::Color.new(255_u8, 95_u8, 175_u8, 255_u8),
      Ansi::Color.new(255_u8, 95_u8, 215_u8, 255_u8),
      Ansi::Color.new(255_u8, 95_u8, 255_u8, 255_u8),
      Ansi::Color.new(255_u8, 135_u8, 0_u8, 255_u8),
      Ansi::Color.new(255_u8, 135_u8, 95_u8, 255_u8),
      Ansi::Color.new(255_u8, 135_u8, 135_u8, 255_u8),
      Ansi::Color.new(255_u8, 135_u8, 175_u8, 255_u8),
      Ansi::Color.new(255_u8, 135_u8, 215_u8, 255_u8),
      Ansi::Color.new(255_u8, 135_u8, 255_u8, 255_u8),
      Ansi::Color.new(255_u8, 175_u8, 0_u8, 255_u8),
      Ansi::Color.new(255_u8, 175_u8, 95_u8, 255_u8),
      Ansi::Color.new(255_u8, 175_u8, 135_u8, 255_u8),
      Ansi::Color.new(255_u8, 175_u8, 175_u8, 255_u8),
      Ansi::Color.new(255_u8, 175_u8, 215_u8, 255_u8),
      Ansi::Color.new(255_u8, 175_u8, 255_u8, 255_u8),
      Ansi::Color.new(255_u8, 215_u8, 0_u8, 255_u8),
      Ansi::Color.new(255_u8, 215_u8, 95_u8, 255_u8),
      Ansi::Color.new(255_u8, 215_u8, 135_u8, 255_u8),
      Ansi::Color.new(255_u8, 215_u8, 175_u8, 255_u8),
      Ansi::Color.new(255_u8, 215_u8, 215_u8, 255_u8),
      Ansi::Color.new(255_u8, 215_u8, 255_u8, 255_u8),
      Ansi::Color.new(255_u8, 255_u8, 0_u8, 255_u8),
      Ansi::Color.new(255_u8, 255_u8, 95_u8, 255_u8),
      Ansi::Color.new(255_u8, 255_u8, 135_u8, 255_u8),
      Ansi::Color.new(255_u8, 255_u8, 175_u8, 255_u8),
      Ansi::Color.new(255_u8, 255_u8, 215_u8, 255_u8),
      Ansi::Color.new(255_u8, 255_u8, 255_u8, 255_u8),
      Ansi::Color.new(8_u8, 8_u8, 8_u8, 255_u8),
      Ansi::Color.new(18_u8, 18_u8, 18_u8, 255_u8),
      Ansi::Color.new(28_u8, 28_u8, 28_u8, 255_u8),
      Ansi::Color.new(38_u8, 38_u8, 38_u8, 255_u8),
      Ansi::Color.new(48_u8, 48_u8, 48_u8, 255_u8),
      Ansi::Color.new(58_u8, 58_u8, 58_u8, 255_u8),
      Ansi::Color.new(68_u8, 68_u8, 68_u8, 255_u8),
      Ansi::Color.new(78_u8, 78_u8, 78_u8, 255_u8),
      Ansi::Color.new(88_u8, 88_u8, 88_u8, 255_u8),
      Ansi::Color.new(98_u8, 98_u8, 98_u8, 255_u8),
      Ansi::Color.new(108_u8, 108_u8, 108_u8, 255_u8),
      Ansi::Color.new(118_u8, 118_u8, 118_u8, 255_u8),
      Ansi::Color.new(128_u8, 128_u8, 128_u8, 255_u8),
      Ansi::Color.new(138_u8, 138_u8, 138_u8, 255_u8),
      Ansi::Color.new(148_u8, 148_u8, 148_u8, 255_u8),
      Ansi::Color.new(158_u8, 158_u8, 158_u8, 255_u8),
      Ansi::Color.new(168_u8, 168_u8, 168_u8, 255_u8),
      Ansi::Color.new(178_u8, 178_u8, 178_u8, 255_u8),
      Ansi::Color.new(188_u8, 188_u8, 188_u8, 255_u8),
      Ansi::Color.new(198_u8, 198_u8, 198_u8, 255_u8),
      Ansi::Color.new(208_u8, 208_u8, 208_u8, 255_u8),
      Ansi::Color.new(218_u8, 218_u8, 218_u8, 255_u8),
      Ansi::Color.new(228_u8, 228_u8, 228_u8, 255_u8),
      Ansi::Color.new(238_u8, 238_u8, 238_u8, 255_u8),
    ]

    # DefaultPalette returns the default palette used when decoding a Sixel image.
    # It contains the 256 colors defined by the xterm 256-color palette.
    def self.default_palette : Array(Ansi::Color)
      DEFAULT_PALETTE.dup
    end

    struct Color
      getter pc : Int32
      getter pu : Int32
      getter px : Int32
      getter py : Int32
      getter pz : Int32

      def initialize(@pc : Int32 = 0, @pu : Int32 = 0, @px : Int32 = 0, @py : Int32 = 0, @pz : Int32 = 0)
      end

      def to_s : String
        String.build { |io| Sixel.write_color(io, @pc, @pu, @px, @py, @pz) }
      end

      def rgba : {UInt32, UInt32, UInt32, UInt32}
        case @pu
        when 1
          color = Sixel.sixel_hls(@px, @py, @pz)
        when 2
          color = Sixel.sixel_rgb(@px, @py, @pz)
        else
          if @pc >= 0 && @pc < DEFAULT_PALETTE.size
            return DEFAULT_PALETTE[@pc].rgba
          else
            return {0x0000_u32, 0x0000_u32, 0x0000_u32, 0xFFFF_u32}
          end
        end
        {color.r.to_u32 * 0x101_u32, color.g.to_u32 * 0x101_u32, color.b.to_u32 * 0x101_u32, color.a.to_u32 * 0x101_u32}
      end
    end

    struct SixelColor
      getter red : UInt32
      getter green : UInt32
      getter blue : UInt32
      getter alpha : UInt32

      def initialize(@red : UInt32, @green : UInt32, @blue : UInt32, @alpha : UInt32)
      end
    end

    def self.to_16bit(channel : UInt8) : UInt32
      (channel.to_u32 * 0x101_u32)
    end

    def self.sixel_convert_color(color : Ansi::Color) : SixelColor
      SixelColor.new(
        convert_channel(to_16bit(color.r)),
        convert_channel(to_16bit(color.g)),
        convert_channel(to_16bit(color.b)),
        convert_channel(to_16bit(color.a))
      )
    end

    def self.color_to_ansi(color : Color) : Ansi::Color
      r16, g16, b16, a16 = color.rgba
      Ansi::Color.new(
        (r16 // 0x101_u32).to_u8,
        (g16 // 0x101_u32).to_u8,
        (b16 // 0x101_u32).to_u8,
        (a16 // 0x101_u32).to_u8
      )
    end

    struct Palette
      getter palette_colors : Array(SixelColor)

      def initialize(@palette_colors : Array(SixelColor), @palette_indexes : Hash(SixelColor, Int32))
      end

      def color_index(color : SixelColor) : Int32
        @palette_indexes[color]
      end
    end

    def self.new_palette(image : Ansi::Image, max_colors : Int32) : Palette
      pixel_counts = Hash(SixelColor, UInt64).new(0_u64)
      image.each_pixel do |_x, _y, color|
        converted = sixel_convert_color(color)
        pixel_counts[converted] += 1_u64
      end

      unique_colors = pixel_counts.keys
      palette_colors = quantize(unique_colors, pixel_counts, max_colors)
      palette_indexes = Hash(SixelColor, Int32).new

      unique_colors.each do |color|
        best_index = 0
        best_score = UInt32::MAX
        palette_colors.each_with_index do |palette_color, idx|
          dr = (color.red.to_i32 - palette_color.red.to_i32)
          dg = (color.green.to_i32 - palette_color.green.to_i32)
          db = (color.blue.to_i32 - palette_color.blue.to_i32)
          da = (color.alpha.to_i32 - palette_color.alpha.to_i32)
          score = (dr * dr + dg * dg + db * db + da * da).to_u32
          if score < best_score
            best_score = score
            best_index = idx
          end
        end
        palette_indexes[color] = best_index
      end

      Palette.new(palette_colors, palette_indexes)
    end

    private enum QuantizationChannel
      Red
      Green
      Blue
      Alpha
    end

    private struct QuantizationCube
      getter start_index : Int32
      getter length : Int32
      getter slice_channel : QuantizationChannel
      getter score : UInt64
      getter pixel_count : UInt64

      def initialize(@start_index : Int32, @length : Int32, @slice_channel : QuantizationChannel, @score : UInt64, @pixel_count : UInt64)
      end
    end

    # ameba:disable Metrics/CyclomaticComplexity
    private def self.create_cube(unique_colors : Array(SixelColor), pixel_counts : Hash(SixelColor, UInt64), start_index : Int32, length : Int32) : QuantizationCube
      min_red = 0xffff_u32
      min_green = 0xffff_u32
      min_blue = 0xffff_u32
      min_alpha = 0xffff_u32
      max_red = 0_u32
      max_green = 0_u32
      max_blue = 0_u32
      max_alpha = 0_u32
      total_weight = 0_u64

      (start_index...(start_index + length)).each do |i|
        color = unique_colors[i]
        total_weight += pixel_counts[color]
        min_red = color.red if color.red < min_red
        max_red = color.red if color.red > max_red
        min_green = color.green if color.green < min_green
        max_green = color.green if color.green > max_green
        min_blue = color.blue if color.blue < min_blue
        max_blue = color.blue if color.blue > max_blue
        min_alpha = color.alpha if color.alpha < min_alpha
        max_alpha = color.alpha if color.alpha > max_alpha
      end

      d_red = max_red - min_red
      d_green = max_green - min_green
      d_blue = max_blue - min_blue
      d_alpha = max_alpha - min_alpha

      slice_channel = if d_red >= d_green && d_red >= d_blue && d_red >= d_alpha
                        QuantizationChannel::Red
                      elsif d_green >= d_blue && d_green >= d_alpha
                        QuantizationChannel::Green
                      elsif d_blue >= d_alpha
                        QuantizationChannel::Blue
                      else
                        QuantizationChannel::Alpha
                      end

      score = case slice_channel
              when QuantizationChannel::Red   then d_red
              when QuantizationChannel::Green then d_green
              when QuantizationChannel::Blue  then d_blue
              else                                 d_alpha
              end

      QuantizationCube.new(start_index, length, slice_channel, score.to_u64 * total_weight, total_weight)
    end

    private def self.quantize(unique_colors : Array(SixelColor), pixel_counts : Hash(SixelColor, UInt64), max_colors : Int32) : Array(SixelColor)
      return unique_colors if unique_colors.size <= max_colors

      cubes = [] of QuantizationCube
      cubes << create_cube(unique_colors, pixel_counts, 0, unique_colors.size)

      while cubes.size < max_colors
        cubes.sort_by!(&.score)
        cubes.reverse!
        cube = cubes.shift
        break unless cube

        segment = unique_colors[cube.start_index, cube.length]
        case cube.slice_channel
        when QuantizationChannel::Red
          segment.sort_by!(&.red)
        when QuantizationChannel::Green
          segment.sort_by!(&.green)
        when QuantizationChannel::Blue
          segment.sort_by!(&.blue)
        when QuantizationChannel::Alpha
          segment.sort_by!(&.alpha)
        end
        unique_colors[cube.start_index, cube.length] = segment

        count_so_far = pixel_counts[segment[0]]
        target = cube.pixel_count / 2
        left_length = 1
        (1...segment.size).each do |idx|
          color = segment[idx]
          weight = pixel_counts[color]
          break if count_so_far + weight > target
          count_so_far += weight
          left_length += 1
        end

        right_length = cube.length - left_length
        right_index = cube.start_index + left_length
        cubes << create_cube(unique_colors, pixel_counts, cube.start_index, left_length)
        cubes << create_cube(unique_colors, pixel_counts, right_index, right_length)
      end

      palette = [] of SixelColor
      cubes.each do |quant_cube|
        total_red = 0_u64
        total_green = 0_u64
        total_blue = 0_u64
        total_alpha = 0_u64
        total_count = 0_u64
        (quant_cube.start_index...(quant_cube.start_index + quant_cube.length)).each do |i|
          color = unique_colors[i]
          count = pixel_counts[color]
          total_red += color.red.to_u64 * count
          total_green += color.green.to_u64 * count
          total_blue += color.blue.to_u64 * count
          total_alpha += color.alpha.to_u64 * count
          total_count += count
        end
        palette << SixelColor.new(
          (total_red / total_count).to_u32,
          (total_green / total_count).to_u32,
          (total_blue / total_count).to_u32,
          (total_alpha / total_count).to_u32
        )
      end

      palette
    end

    class BitSet
      def initialize
        @words = [] of UInt64
      end

      def set(bit : Int32) : Nil
        return if bit < 0
        word_index = bit // 64
        bit_index = bit % 64
        ensure_capacity(word_index)
        @words[word_index] |= (1_u64 << bit_index)
      end

      def next_set(start_bit : Int32) : {Int32, Bool}
        return {0, false} if start_bit < 0
        word_index = start_bit // 64
        bit_index = start_bit % 64
        return {0, false} if word_index >= @words.size

        mask = @words[word_index] & (~0_u64 << bit_index)
        if mask != 0
          return {(word_index * 64 + mask.trailing_zeros_count).to_i, true}
        end

        (word_index + 1...@words.size).each do |idx|
          word = @words[idx]
          next if word == 0
          return {(idx * 64 + word.trailing_zeros_count).to_i, true}
        end

        {0, false}
      end

      def get_word64_at_bit(bit : Int32) : UInt64
        return 0_u64 if bit < 0
        word_index = bit // 64
        shift = bit % 64
        low = word_index < @words.size ? @words[word_index] : 0_u64
        return low if shift == 0
        high = (word_index + 1) < @words.size ? @words[word_index + 1] : 0_u64
        (low >> shift) | (high << (64 - shift))
      end

      private def ensure_capacity(word_index : Int32) : Nil
        while @words.size <= word_index
          @words << 0_u64
        end
      end
    end

    class Decoder
      private def read_raster_bounds(data : Bytes, idx : Int32) : {Tuple(Int32, Int32, Int32, Int32)?, Int32}
        return {nil, idx} unless idx < data.size && data[idx] == RasterAttribute

        n = 16
        loop do
          slice = data[idx, Math.min(n, data.size - idx)]
          raster, read = Sixel.decode_raster(slice)
          raise ErrInvalidRaster.new("invalid raster") if read == 0
          if read >= n && idx + n < data.size
            n *= 2
            next
          end
          idx += read
          return { {0, 0, raster.ph, raster.pv}, idx }
        end
      end

      private def resolve_bounds(data : Bytes, idx : Int32, bounds : Tuple(Int32, Int32, Int32, Int32)?) : Tuple(Int32, Int32, Int32, Int32)
        # ameba:disable Lint/NotNil
        return bounds.not_nil! if bounds && bounds[2] > 0 && bounds[3] > 0

        width, height = scan_size(data[idx..])
        {0, 0, width, height}
      end

      private def parse_color(data : Bytes, idx : Int32) : {Color, Int32}
        color_start = idx - 1
        while idx < data.size
          b2 = data[idx]
          break if (b2 < '0'.ord || b2 > '9'.ord) && b2 != ';'.ord
          idx += 1
        end
        color_slice = data[color_start...idx]
        color, n = Sixel.decode_color(color_slice)
        raise ErrInvalidColor.new("invalid color") if n == 0
        {color, idx}
      end

      private def parse_repeat(data : Bytes, idx : Int32) : {Repeat, Int32}
        repeat, n = Sixel.decode_repeat(data[idx - 1..])
        raise ErrInvalidRepeat.new("invalid repeat") if n == 0
        idx += n - 1
        {repeat, idx}
      end

      private def sixel_pixel?(b : UInt8) : Bool
        b >= '?'.ord.to_u8 && b <= '~'.ord.to_u8
      end

      private def draw_sixel_run(count : Int32, sixel : UInt8, color : Ansi::Color, current_x : Int32, band_y : Int32, img : Ansi::RGBAImage) : Int32
        return current_x unless sixel_pixel?(sixel)

        x = current_x
        count.times do
          write_pixel(x, band_y, sixel, color, img)
          x += 1
        end
        x
      end

      def scan_size(data : Bytes) : {Int32, Int32}
        max_width = 0
        band_count = 0
        current_width = 0
        new_band = true

        i = 0
        while i < data.size
          b = data[i]
          case b
          when LineBreak
            # LF
            current_width = 0
            # The image may end with an LF, so we shouldn't increment the band
            # count until we encounter a pixel
            new_band = true
          when CarriageReturn
            # CR
            current_width = 0
          when RepeatIntroducer, '?'.ord.to_u8..'~'.ord.to_u8
            count = 1
            if b == RepeatIntroducer
              # Get the run length for the RLE operation
              repeat, n = Sixel.decode_repeat(data[i..])
              if n == 0
                return {max_width, band_count * 6}
              end

              # 1 is added in the loop
              i += n - 1
              count = repeat.count
            end

            current_width += count
            if new_band
              new_band = false
              band_count += 1
            end

            max_width = Math.max(max_width, current_width)
          end
          i += 1
        end

        {max_width, band_count * 6}
      end

      def decode(io : IO) : Ansi::RGBAImage
        # Read all data from IO
        data = io.gets_to_end.to_slice
        idx = 0

        bounds, idx = read_raster_bounds(data, idx)
        bounds = resolve_bounds(data, idx, bounds)

        img = Ansi::RGBAImage.new(bounds[2], bounds[3], Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8))
        palette = Sixel.default_palette
        current_x = 0
        current_band_y = 0
        current_palette_index = 0

        while idx < data.size
          b = data[idx]
          idx += 1
          case b
          when LineBreak
            current_band_y += 1
            current_x = 0
          when CarriageReturn
            current_x = 0
          when ColorIntroducer
            color, idx = parse_color(data, idx)
            current_palette_index = color.pc
            if color.pu > 0
              palette[current_palette_index] = Sixel.color_to_ansi(color)
            end
          when RepeatIntroducer
            repeat, idx = parse_repeat(data, idx)
            current_x = draw_sixel_run(repeat.count, repeat.char.ord.to_u8, palette[current_palette_index], current_x, current_band_y, img)
          else
            current_x = draw_sixel_run(1, b, palette[current_palette_index], current_x, current_band_y, img)
          end
        end

        img
      end

      private def write_pixel(x : Int32, band_y : Int32, sixel : UInt8, color : Ansi::Color, img : Ansi::RGBAImage) : Nil
        masked_sixel = (sixel - '?'.ord) & 63
        y_offset = 0
        while masked_sixel != 0
          if masked_sixel & 1 != 0
            img.set(x, band_y * 6 + y_offset, color)
          end
          y_offset += 1
          masked_sixel >>= 1
        end
      end

      private def read_error(err : Exception) : Exception?
        if err.is_a?(IO::EOFError)
          nil
        else
          Exception.new("failed to read sixel data: #{err.message}", cause: err)
        end
      end
    end

    class Encoder
      def encode(io : IO, image : Ansi::Image) : Nil
        return if image.width == 0 || image.height == 0

        Sixel.write_raster(io, 1, 1, image.width, image.height)
        palette = Sixel.new_palette(image, MaxColors)

        palette.palette_colors.each_with_index do |color, idx|
          io.write_byte(ColorIntroducer)
          io << idx << ";2;" << color.red << ';' << color.green << ';' << color.blue
        end

        builder = SixelBuilder.new(image.width, image.height, palette)
        image.each_pixel do |x, y, color|
          builder.set_color(x, y, color)
        end
        io << builder.generate_pixels
      end
    end

    class SixelBuilder
      def initialize(@width : Int32, @height : Int32, @palette : Palette)
        @pixel_bands = BitSet.new
        @image_data = String::Builder.new
        @repeat_count = 0
        @repeat_byte = '\0'
      end

      def band_height : Int32
        bands = @height // 6
        bands += 1 if (@height % 6) != 0
        bands
      end

      def set_color(x : Int32, y : Int32, color : Ansi::Color) : Nil
        band_y = y // 6
        palette_index = @palette.color_index(Sixel.sixel_convert_color(color))
        bit = band_height * @width * 6 * palette_index + band_y * @width * 6 + (x * 6) + (y % 6)
        @pixel_bands.set(bit)
      end

      def generate_pixels : String
        @image_data = String::Builder.new
        band_count = band_height

        band_count.times do |band_y|
          write_control_rune(LineBreak.chr) if band_y > 0
          has_written_color = false

          @palette.palette_colors.size.times do |palette_index|
            next if @palette.palette_colors[palette_index].alpha < 1

            first_color_bit = band_height * @width * 6 * palette_index + band_y * @width * 6
            next_color_bit = first_color_bit + @width * 6
            first_set_bit, any_set = @pixel_bands.next_set(first_color_bit)
            next if !any_set || first_set_bit >= next_color_bit

            if has_written_color
              write_control_rune(CarriageReturn.chr)
            end
            has_written_color = true

            write_control_rune(ColorIntroducer.chr)
            @image_data << palette_index

            x = 0
            while x < @width
              bit = first_color_bit + (x * 6)
              word = @pixel_bands.get_word64_at_bit(bit)
              pixel1 = ((word & 63) + '?'.ord).to_u8.chr
              pixel2 = (((word >> 6) & 63) + '?'.ord).to_u8.chr
              pixel3 = (((word >> 12) & 63) + '?'.ord).to_u8.chr
              pixel4 = (((word >> 18) & 63) + '?'.ord).to_u8.chr

              write_image_rune(pixel1)
              break if x + 1 >= @width
              write_image_rune(pixel2)
              break if x + 2 >= @width
              write_image_rune(pixel3)
              break if x + 3 >= @width
              write_image_rune(pixel4)
              x += 4
            end

            end_repeat
          end
        end

        write_control_rune(LineBreak.chr)
        @image_data.to_s
      end

      private def write_control_rune(char : Char) : Nil
        end_repeat
        @image_data << char
      end

      private def write_image_rune(char : Char) : Nil
        if @repeat_byte == '\0'
          @repeat_byte = char
          @repeat_count = 1
          return
        end

        if @repeat_byte == char
          @repeat_count += 1
          return
        end

        end_repeat
        @repeat_byte = char
        @repeat_count = 1
      end

      private def end_repeat : Nil
        return if @repeat_count == 0
        if @repeat_count > 3
          Sixel.write_repeat(@image_data, @repeat_count, @repeat_byte)
        else
          @repeat_count.times { @image_data << @repeat_byte }
        end
        @repeat_count = 0
        @repeat_byte = '\0'
      end
    end
  end
end
