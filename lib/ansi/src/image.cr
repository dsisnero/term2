module Ansi
  module Image
    abstract def width : Int32
    abstract def height : Int32
    abstract def pixel(x : Int32, y : Int32) : Color
    abstract def each_pixel(&block : Int32, Int32, Color ->) : Nil
  end

  class RGBAImage
    include Image

    getter width : Int32
    getter height : Int32

    def initialize(@width : Int32, @height : Int32, fill : Color = Color.black)
      @pixels = Array(Color).new(@width * @height, fill)
    end

    def pixel(x : Int32, y : Int32) : Color
      @pixels[y * @width + x]
    end

    def set(x : Int32, y : Int32, color : Color) : Nil
      @pixels[y * @width + x] = color
    end

    def each_pixel(& : Int32, Int32, Color ->) : Nil
      @height.times do |y|
        row_offset = y * @width
        @width.times do |x|
          yield x, y, @pixels[row_offset + x]
        end
      end
    end
  end

  class GrayImage
    include Image

    getter width : Int32
    getter height : Int32

    def initialize(@width : Int32, @height : Int32, fill : UInt8 = 0_u8)
      @pixels = Array(UInt8).new(@width * @height, fill)
    end

    def pixel(x : Int32, y : Int32) : Color
      value = @pixels[y * @width + x]
      Color.new(value, value, value, 0xff_u8)
    end

    def set(x : Int32, y : Int32, gray : UInt8) : Nil
      @pixels[y * @width + x] = gray
    end

    def each_pixel(& : Int32, Int32, Color ->) : Nil
      @height.times do |y|
        row_offset = y * @width
        @width.times do |x|
          value = @pixels[row_offset + x]
          yield x, y, Color.new(value, value, value, 0xff_u8)
        end
      end
    end
  end
end
