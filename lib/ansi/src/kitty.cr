require "base64"
require "compress/zlib"
require "stumpy_png"

module Ansi
  module Kitty
    class ErrMissingFile < Exception
    end

    MaxChunkSize = 1024 * 4
    Placeholder  = '\u{10EEEE}'

    RGBA =  32
    RGB  =  24
    PNG  = 100

    Zlib = 'z'.ord.to_u8

    Direct       = 'd'.ord.to_u8
    File         = 'f'.ord.to_u8
    TempFile     = 't'.ord.to_u8
    SharedMemory = 's'.ord.to_u8

    Transmit       = 't'.ord.to_u8
    TransmitAndPut = 'T'.ord.to_u8
    Query          = 'q'.ord.to_u8
    Put            = 'p'.ord.to_u8
    Delete         = 'd'.ord.to_u8
    Frame          = 'f'.ord.to_u8
    Animate        = 'a'.ord.to_u8
    Compose        = 'c'.ord.to_u8

    DeleteAll    = 'a'.ord.to_u8
    DeleteID     = 'i'.ord.to_u8
    DeleteNumber = 'n'.ord.to_u8
    DeleteCursor = 'c'.ord.to_u8
    DeleteFrames = 'f'.ord.to_u8
    DeleteCell   = 'p'.ord.to_u8
    DeleteCellZ  = 'q'.ord.to_u8
    DeleteRange  = 'r'.ord.to_u8
    DeleteColumn = 'x'.ord.to_u8
    DeleteRow    = 'y'.ord.to_u8
    DeleteZ      = 'z'.ord.to_u8

    GraphicsTempDir     = ""
    GraphicsTempPattern = "tty-graphics-protocol-*"

    def self.diacritic(index : Int32) : Char
      return DIACRITICS[0] if index < 0 || index >= DIACRITICS.size
      DIACRITICS[index]
    end

    struct Options
      property action : UInt8
      property quite : UInt8
      property id : Int32
      property placement_id : Int32
      property number : Int32
      property format : Int32
      property image_width : Int32
      property image_height : Int32
      property compression : UInt8
      property transmission : UInt8
      property file : String
      property size : Int32
      property offset : Int32
      property? chunk : Bool
      property chunk_formatter : (String -> String)?
      property x : Int32
      property y : Int32
      property z : Int32
      property width : Int32
      property height : Int32
      property offset_x : Int32
      property offset_y : Int32
      property columns : Int32
      property rows : Int32
      property? virtual_placement : Bool
      property? do_not_move_cursor : Bool
      property parent_id : Int32
      property parent_placement_id : Int32
      property delete : UInt8
      property? delete_resources : Bool

      def initialize
        @action = 0_u8
        @quite = 0_u8
        @id = 0
        @placement_id = 0
        @number = 0
        @format = 0
        @image_width = 0
        @image_height = 0
        @compression = 0_u8
        @transmission = 0_u8
        @file = ""
        @size = 0
        @offset = 0
        @chunk = false
        @chunk_formatter = nil
        @x = 0
        @y = 0
        @z = 0
        @width = 0
        @height = 0
        @offset_x = 0
        @offset_y = 0
        @columns = 0
        @rows = 0
        @virtual_placement = false
        @do_not_move_cursor = false
        @parent_id = 0
        @parent_placement_id = 0
        @delete = 0_u8
        @delete_resources = false
      end

      # ameba:disable Metrics/CyclomaticComplexity
      def options : Array(String)
        opts = [] of String
        @format = RGBA if @format == 0
        @action = Transmit if @action == 0
        @delete = DeleteAll if @delete == 0

        if @transmission == 0
          @transmission = @file.empty? ? Direct : File
        end

        opts << "f=#{@format}" if @format != RGBA
        opts << "q=#{@quite}" if @quite > 0
        opts << "i=#{@id}" if @id > 0
        opts << "p=#{@placement_id}" if @placement_id > 0
        opts << "I=#{@number}" if @number > 0
        opts << "s=#{@image_width}" if @image_width > 0
        opts << "v=#{@image_height}" if @image_height > 0
        opts << "t=#{@transmission.chr}" if @transmission != Direct
        opts << "S=#{@size}" if @size > 0
        opts << "O=#{@offset}" if @offset > 0
        opts << "o=#{@compression.chr}" if @compression == Zlib
        opts << "U=1" if @virtual_placement
        opts << "C=1" if @do_not_move_cursor
        opts << "P=#{@parent_id}" if @parent_id > 0
        opts << "Q=#{@parent_placement_id}" if @parent_placement_id > 0
        opts << "x=#{@x}" if @x > 0
        opts << "y=#{@y}" if @y > 0
        opts << "z=#{@z}" if @z > 0
        opts << "w=#{@width}" if @width > 0
        opts << "h=#{@height}" if @height > 0
        opts << "X=#{@offset_x}" if @offset_x > 0
        opts << "Y=#{@offset_y}" if @offset_y > 0
        opts << "c=#{@columns}" if @columns > 0
        opts << "r=#{@rows}" if @rows > 0

        if @delete != DeleteAll || @delete_resources
          delete_action = @delete_resources ? (@delete - 32).chr : @delete.chr
          opts << "d=#{delete_action}"
        end

        opts << "a=#{@action.chr}" if @action != Transmit
        opts
      end

      def to_s : String
        options.join(",")
      end

      def marshal_text : Bytes
        to_s.to_slice
      end

      def unmarshal_text(text : Bytes) : Nil
        unmarshal_text(String.new(text))
      end

      # ameba:disable Metrics/CyclomaticComplexity
      def unmarshal_text(text : String) : Nil
        text.split(",").each do |opt|
          parts = opt.split("=", 2)
          next unless parts.size == 2
          key = parts[0]
          value = parts[1]
          next if value.empty?

          case key
          when "a"
            @action = value[0].ord.to_u8
          when "o"
            @compression = value[0].ord.to_u8
          when "t"
            @transmission = value[0].ord.to_u8
          when "d"
            d = value[0].ord.to_u8
            if d >= 'A'.ord.to_u8 && d <= 'Z'.ord.to_u8
              @delete_resources = true
              d = (d + 32).to_u8
            end
            @delete = d
          when "i", "q", "p", "I", "f", "s", "v", "S", "O", "m", "x", "y", "z", "w", "h", "X", "Y", "c", "r", "U", "P", "Q"
            v = value.to_i?
            next unless v

            case key
            when "i"
              @id = v
            when "q"
              @quite = v.to_u8
            when "p"
              @placement_id = v
            when "I"
              @number = v
            when "f"
              @format = v
            when "s"
              @image_width = v
            when "v"
              @image_height = v
            when "S"
              @size = v
            when "O"
              @offset = v
            when "m"
              @chunk = (v == 0 || v == 1)
            when "x"
              @x = v
            when "y"
              @y = v
            when "z"
              @z = v
            when "w"
              @width = v
            when "h"
              @height = v
            when "X"
              @offset_x = v
            when "Y"
              @offset_y = v
            when "c"
              @columns = v
            when "r"
              @rows = v
            when "U"
              @virtual_placement = (v == 1)
            when "P"
              @parent_id = v
            when "Q"
              @parent_placement_id = v
            end
          end
        end
      end
    end

    class Encoder
      property? compress : Bool
      property format : Int32

      def initialize(@compress : Bool = false, @format : Int32 = 0)
      end

      def encode(io : IO, image : Ansi::Image?) : Nil
        if image
          if @compress
            Compress::Zlib::Writer.open(io) do |writer|
              encode_inner(writer, image)
            end
          else
            encode_inner(io, image)
          end
        end
      end

      private def encode_inner(io : IO, image : Ansi::Image) : Nil
        @format = RGBA if @format == 0

        case @format
        when RGBA, RGB
          image.each_pixel do |_x, _y, color|
            io.write_byte(color.r)
            io.write_byte(color.g)
            io.write_byte(color.b)
            io.write_byte(color.a) if @format == RGBA
          end
        when PNG
          canvas = StumpyPNG::Canvas.new(image.width, image.height)
          image.each_pixel do |x, y, color|
            canvas[x, y] = StumpyPNG::RGBA.new(color.r, color.g, color.b, color.a)
          end
          StumpyPNG.write(canvas, io)
        else
          raise "unsupported format: #{@format}"
        end
      end
    end

    class Decoder
      property? decompress : Bool
      property format : Int32
      property width : Int32
      property height : Int32

      def initialize(@decompress : Bool = false, @format : Int32 = 0, @width : Int32 = 0, @height : Int32 = 0)
      end

      def decode(io : IO) : Ansi::Image
        if @decompress
          Compress::Zlib::Reader.open(io) do |reader|
            decode_inner(reader)
          end
        else
          decode_inner(io)
        end
      end

      private def decode_inner(io : IO) : Ansi::Image
        @format = RGBA if @format == 0

        case @format
        when RGBA, RGB
          decode_rgba(io, @format == RGBA)
        when PNG
          decode_png(io)
        else
          raise "unsupported format: #{@format}"
        end
      end

      private def decode_rgba(io : IO, alpha : Bool) : Ansi::Image
        raise "width and height must be specified for RGBA/RGB decoding" if @width <= 0 || @height <= 0
        image = Ansi::RGBAImage.new(@width, @height)
        pixel_size = alpha ? 4 : 3
        buffer = Bytes.new(pixel_size)

        @height.times do |y|
          @width.times do |x|
            bytes_read = io.read_fully(buffer)
            raise "failed to read pixel data" if bytes_read != pixel_size
            if alpha
              image.set(x, y, Ansi::Color.new(buffer[0], buffer[1], buffer[2], buffer[3]))
            else
              image.set(x, y, Ansi::Color.new(buffer[0], buffer[1], buffer[2], 0xff_u8))
            end
          end
        end
        image
      end

      private def decode_png(io : IO) : Ansi::Image
        canvas = StumpyPNG.read(io)
        image = Ansi::RGBAImage.new(canvas.width, canvas.height)
        canvas.width.times do |x|
          canvas.height.times do |y|
            color = canvas[x, y]
            image.set(x, y, Ansi::Color.new(color.r.to_u8, color.g.to_u8, color.b.to_u8, color.a.to_u8))
          end
        end
        image
      end
    end

    # ameba:disable Metrics/CyclomaticComplexity
    def self.encode_graphics(io : IO, image : Ansi::Image?, options : Options?) : Nil
      opts = options || Options.new

      if opts.transmission == 0 && !opts.file.empty?
        opts.transmission = File
      end

      data = IO::Memory.new
      encoder = Encoder.new(compress: opts.compression == Zlib, format: opts.format)

      case opts.transmission
      when Direct
        encoder.encode(data, image) if image
      when SharedMemory
        raise "shared memory transmission is not yet implemented"
      when File
        raise ErrMissingFile.new("missing file path") if opts.file.empty?
        ::File.open(opts.file) do |file|
          stat = file.info
          raise "file is not a regular file" unless stat.type.file?
          data.write(file.path.to_slice)
        end
      when TempFile
        temp_path = ""
        if GraphicsTempDir.empty?
          ::File.tempfile(GraphicsTempPattern) do |file|
            encoder.encode(file, image) if image
            temp_path = file.path
          end
        else
          ::File.tempfile(GraphicsTempPattern, dir: GraphicsTempDir) do |file|
            encoder.encode(file, image) if image
            temp_path = file.path
          end
        end
        data.write(temp_path.to_slice)
      else
        encoder.encode(data, image) if image
      end

      payload_str = Base64.strict_encode(data.to_slice)
      payload = payload_str.to_slice

      unless opts.chunk?
        io << Ansi.kitty_graphics(payload, opts.options)
        return
      end

      chunk_formatter = opts.chunk_formatter || ->(s : String) { s }
      payload_io = IO::Memory.new(payload)
      chunk = Bytes.new(MaxChunkSize)
      is_first = true

      loop do
        read = payload_io.read(chunk)
        break if read == 0
        is_last = payload_io.pos == payload_io.size
        chunk_opts = build_chunk_options(opts, is_first, is_last)
        io << chunk_formatter.call(Ansi.kitty_graphics(chunk[0, read], chunk_opts))
        is_first = false
      end
    end

    private def self.build_chunk_options(opts : Options, is_first : Bool, is_last : Bool) : Array(String)
      chunk_opts = [] of String
      if is_first
        chunk_opts = opts.options
      else
        chunk_opts << "q=#{opts.quite}" if opts.quite > 0
        chunk_opts << "a=f" if opts.action == Frame
      end

      unless is_first && is_last
        chunk_opts << (is_last ? "m=0" : "m=1")
      end
      chunk_opts
    end

    DIACRITICS = [
      '\u0305', '\u030D', '\u030E', '\u0310', '\u0312', '\u033D', '\u033E', '\u033F',
      '\u0346', '\u034A', '\u034B', '\u034C', '\u0350', '\u0351', '\u0352', '\u0357',
      '\u035B', '\u0363', '\u0364', '\u0365', '\u0366', '\u0367', '\u0368', '\u0369',
      '\u036A', '\u036B', '\u036C', '\u036D', '\u036E', '\u036F', '\u0483', '\u0484',
      '\u0485', '\u0486', '\u0487', '\u0592', '\u0593', '\u0594', '\u0595', '\u0597',
      '\u0598', '\u0599', '\u059C', '\u059D', '\u059E', '\u059F', '\u05A0', '\u05A1',
      '\u05A8', '\u05A9', '\u05AB', '\u05AC', '\u05AF', '\u05C4', '\u0610', '\u0611',
      '\u0612', '\u0613', '\u0614', '\u0615', '\u0616', '\u0617', '\u0657', '\u0658',
      '\u0659', '\u065A', '\u065B', '\u065D', '\u065E', '\u06D6', '\u06D7', '\u06D8',
      '\u06D9', '\u06DA', '\u06DB', '\u06DC', '\u06DF', '\u06E0', '\u06E1', '\u06E2',
      '\u06E4', '\u06E7', '\u06E8', '\u06EB', '\u06EC', '\u0730', '\u0732', '\u0733',
      '\u0735', '\u0736', '\u073A', '\u073D', '\u073F', '\u0740', '\u0741', '\u0743',
      '\u0745', '\u0747', '\u0749', '\u074A', '\u07EB', '\u07EC', '\u07ED', '\u07EE',
      '\u07EF', '\u07F0', '\u07F1', '\u07F3', '\u0816', '\u0817', '\u0818', '\u0819',
      '\u081B', '\u081C', '\u081D', '\u081E', '\u081F', '\u0820', '\u0821', '\u0822',
      '\u0823', '\u0825', '\u0826', '\u0827', '\u0829', '\u082A', '\u082B', '\u082C',
      '\u082D', '\u0951', '\u0953', '\u0954', '\u0F82', '\u0F83', '\u0F86', '\u0F87',
      '\u135D', '\u135E', '\u135F', '\u17DD', '\u193A', '\u1A17', '\u1A75', '\u1A76',
      '\u1A77', '\u1A78', '\u1A79', '\u1A7A', '\u1A7B', '\u1A7C', '\u1B6B', '\u1B6D',
      '\u1B6E', '\u1B6F', '\u1B70', '\u1B71', '\u1B72', '\u1B73', '\u1CD0', '\u1CD1',
      '\u1CD2', '\u1CDA', '\u1CDB', '\u1CE0', '\u1DC0', '\u1DC1', '\u1DC3', '\u1DC4',
      '\u1DC5', '\u1DC6', '\u1DC7', '\u1DC8', '\u1DC9', '\u1DCB', '\u1DCC', '\u1DD1',
      '\u1DD2', '\u1DD3', '\u1DD4', '\u1DD5', '\u1DD6', '\u1DD7', '\u1DD8', '\u1DD9',
      '\u1DDA', '\u1DDB', '\u1DDC', '\u1DDD', '\u1DDE', '\u1DDF', '\u1DE0', '\u1DE1',
      '\u1DE2', '\u1DE3', '\u1DE4', '\u1DE5', '\u1DE6', '\u1DFE', '\u20D0', '\u20D1',
      '\u20D4', '\u20D5', '\u20D6', '\u20D7', '\u20DB', '\u20DC', '\u20E1', '\u20E7',
      '\u20E9', '\u20F0', '\u2CEF', '\u2CF0', '\u2CF1', '\u2DE0', '\u2DE1', '\u2DE2',
      '\u2DE3', '\u2DE4', '\u2DE5', '\u2DE6', '\u2DE7', '\u2DE8', '\u2DE9', '\u2DEA',
      '\u2DEB', '\u2DEC', '\u2DED', '\u2DEE', '\u2DEF', '\u2DF0', '\u2DF1', '\u2DF2',
      '\u2DF3', '\u2DF4', '\u2DF5', '\u2DF6', '\u2DF7', '\u2DF8', '\u2DF9', '\u2DFA',
      '\u2DFB', '\u2DFC', '\u2DFD', '\u2DFE', '\u2DFF', '\uA66F', '\uA67C', '\uA67D',
      '\uA6F0', '\uA6F1', '\uA8E0', '\uA8E1', '\uA8E2', '\uA8E3', '\uA8E4', '\uA8E5',
      '\uA8E6', '\uA8E7', '\uA8E8', '\uA8E9', '\uA8EA', '\uA8EB', '\uA8EC', '\uA8ED',
      '\uA8EE', '\uA8EF', '\uA8F0', '\uA8F1', '\uAAB0', '\uAAB2', '\uAAB3', '\uAAB7',
      '\uAAB8', '\uAABE', '\uAABF', '\uAAC1', '\uFE20', '\uFE21', '\uFE22', '\uFE23',
      '\uFE24', '\uFE25', '\uFE26', '\u{10A0F}', '\u{10A38}', '\u{1D185}', '\u{1D186}',
      '\u{1D187}', '\u{1D188}', '\u{1D189}', '\u{1D1AA}', '\u{1D1AB}', '\u{1D1AC}',
      '\u{1D1AD}', '\u{1D242}', '\u{1D243}', '\u{1D244}',
    ]
  end
end
