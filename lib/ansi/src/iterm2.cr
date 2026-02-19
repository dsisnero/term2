module Ansi
  module Iterm2
    AUTO = "auto"

    def self.cells(n : Int32) : String
      n.to_s
    end

    def self.pixels(n : Int32) : String
      "#{n}px"
    end

    def self.percent(n : Int32) : String
      "#{n}%"
    end

    private struct FileOptions
      getter name : String
      getter size : Int64
      getter width : String
      getter height : String
      getter? ignore_aspect_ratio : Bool
      getter? inline : Bool
      getter? do_not_move_cursor : Bool
      getter content : Bytes

      def initialize(
        @name : String = "",
        @size : Int64 = 0_i64,
        @width : String = "",
        @height : String = "",
        @ignore_aspect_ratio : Bool = false,
        @inline : Bool = false,
        @do_not_move_cursor : Bool = false,
        @content : Bytes = Bytes.empty,
      )
      end

      def options_string : String
        opts = [] of String
        opts << "name=#{@name}" unless @name.empty?
        opts << "size=#{@size}" if @size != 0
        opts << "width=#{@width}" unless @width.empty?
        opts << "height=#{@height}" unless @height.empty?
        opts << "preserveAspectRatio=0" if @ignore_aspect_ratio
        opts << "inline=1" if @inline
        opts << "doNotMoveCursor=1" if @do_not_move_cursor
        opts.join(";")
      end
    end

    struct File
      getter name : String
      getter size : Int64
      getter width : String
      getter height : String
      getter? ignore_aspect_ratio : Bool
      getter? inline : Bool
      getter? do_not_move_cursor : Bool
      getter content : Bytes

      def initialize(
        @name : String = "",
        @size : Int64 = 0_i64,
        @width : String = "",
        @height : String = "",
        @ignore_aspect_ratio : Bool = false,
        @inline : Bool = false,
        @do_not_move_cursor : Bool = false,
        @content : Bytes = Bytes.empty,
      )
      end

      def to_s : String
        options = FileOptions.new(
          @name,
          @size,
          @width,
          @height,
          @ignore_aspect_ratio,
          @inline,
          @do_not_move_cursor,
          @content
        )

        String.build do |io|
          io << "File=" << options.options_string
          if @content.size > 0
            io << ':'
            io.write(@content)
          end
        end
      end
    end

    struct MultipartFile
      getter name : String
      getter size : Int64
      getter width : String
      getter height : String
      getter? ignore_aspect_ratio : Bool
      getter? inline : Bool
      getter? do_not_move_cursor : Bool
      getter content : Bytes

      def initialize(
        @name : String = "",
        @size : Int64 = 0_i64,
        @width : String = "",
        @height : String = "",
        @ignore_aspect_ratio : Bool = false,
        @inline : Bool = false,
        @do_not_move_cursor : Bool = false,
        @content : Bytes = Bytes.empty,
      )
      end

      def to_s : String
        options = FileOptions.new(
          @name,
          @size,
          @width,
          @height,
          @ignore_aspect_ratio,
          @inline,
          @do_not_move_cursor,
          @content
        )
        "MultipartFile=#{options.options_string}"
      end
    end

    struct FilePart
      getter content : Bytes

      def initialize(@content : Bytes)
      end

      def to_s : String
        String.build do |io|
          io << "FilePart="
          io.write(@content)
        end
      end
    end

    struct FileEnd
      def to_s : String
        "FileEnd"
      end
    end
  end
end
