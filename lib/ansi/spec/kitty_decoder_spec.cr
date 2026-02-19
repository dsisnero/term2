require "./spec_helper"
require "compress/zlib"

private def build_rgba_image(width : Int32, height : Int32, colors : Array(Ansi::Color)) : Ansi::RGBAImage
  image = Ansi::RGBAImage.new(width, height)
  idx = 0
  height.times do |y|
    width.times do |x|
      image.set(x, y, colors[idx])
      idx += 1
    end
  end
  image
end

private def images_equal?(a : Ansi::Image, b : Ansi::Image) : Bool
  return false if a.width != b.width || a.height != b.height
  a.each_pixel do |x, y, color_a|
    color_b = b.pixel(x, y)
    return false if color_a.r != color_b.r || color_a.g != color_b.g || color_a.b != color_b.b || color_a.a != color_b.a
  end
  true
end

describe "Ansi::Kitty::Decoder" do
  it "decodes formats" do
    red = Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8)
    blue = Ansi::Color.new(0_u8, 0_u8, 255_u8, 255_u8)
    pixels = [red, blue, blue, red]
    rgba_expected = build_rgba_image(2, 2, pixels)

    tests = [
      {
        name:    "RGBA format 2x2",
        decoder: begin
          d = Ansi::Kitty::Decoder.new
          d.format = Ansi::Kitty::RGBA
          d.width = 2
          d.height = 2
          d
        end,
        input: Bytes[
          255, 0, 0, 255,
          0, 0, 255, 255,
          0, 0, 255, 255,
          255, 0, 0, 255,
        ],
        expected: rgba_expected,
        raises:   false,
      },
      {
        name:    "RGB format 2x2",
        decoder: begin
          d = Ansi::Kitty::Decoder.new
          d.format = Ansi::Kitty::RGB
          d.width = 2
          d.height = 2
          d
        end,
        input: Bytes[
          255, 0, 0,
          0, 0, 255,
          0, 0, 255,
          255, 0, 0,
        ],
        expected: rgba_expected,
        raises:   false,
      },
      {
        name:    "RGBA with compression",
        decoder: begin
          d = Ansi::Kitty::Decoder.new
          d.format = Ansi::Kitty::RGBA
          d.width = 2
          d.height = 2
          d.decompress = true
          d
        end,
        input: begin
          data = Bytes[
            255, 0, 0, 255,
            0, 0, 255, 255,
            0, 0, 255, 255,
            255, 0, 0, 255,
          ]
          io = IO::Memory.new
          Compress::Zlib::Writer.open(io, &.write(data))
          io.to_slice
        end,
        expected: rgba_expected,
        raises:   false,
      },
      {
        name:    "PNG format",
        decoder: begin
          d = Ansi::Kitty::Decoder.new
          d.format = Ansi::Kitty::PNG
          d
        end,
        input: begin
          canvas = StumpyPNG::Canvas.new(1, 1)
          canvas[0, 0] = StumpyPNG::RGBA.new(255, 0, 0, 255)
          io = IO::Memory.new
          StumpyPNG.write(canvas, io)
          io.to_slice
        end,
        expected: build_rgba_image(1, 1, [red]),
        raises:   false,
      },
      {
        name:    "invalid format",
        decoder: begin
          d = Ansi::Kitty::Decoder.new
          d.format = 999
          d.width = 2
          d.height = 2
          d
        end,
        input:    Bytes[0, 0, 0],
        expected: Ansi::RGBAImage.new(0, 0),
        raises:   true,
      },
      {
        name:    "incomplete RGBA data",
        decoder: begin
          d = Ansi::Kitty::Decoder.new
          d.format = Ansi::Kitty::RGBA
          d.width = 2
          d.height = 2
          d
        end,
        input:    Bytes[255, 0, 0],
        expected: Ansi::RGBAImage.new(0, 0),
        raises:   true,
      },
      {
        name:    "invalid compressed data",
        decoder: begin
          d = Ansi::Kitty::Decoder.new
          d.format = Ansi::Kitty::RGBA
          d.width = 2
          d.height = 2
          d.decompress = true
          d
        end,
        input:    Bytes[1, 2, 3],
        expected: Ansi::RGBAImage.new(0, 0),
        raises:   true,
      },
      {
        name:    "default format (RGBA)",
        decoder: begin
          d = Ansi::Kitty::Decoder.new
          d.width = 1
          d.height = 1
          d
        end,
        input:    Bytes[255, 0, 0, 255],
        expected: build_rgba_image(1, 1, [red]),
        raises:   false,
      },
    ]

    tests.each do |test_case|
      if test_case[:raises]
        expect_raises(Exception) do
          test_case[:decoder].decode(IO::Memory.new(test_case[:input]))
        end
        next
      end

      result = test_case[:decoder].decode(IO::Memory.new(test_case[:input]))
      images_equal?(result, test_case[:expected]).should be_true
    end
  end

  it "decodes edge cases" do
    tests = [
      {
        name:    "zero dimensions",
        decoder: begin
          d = Ansi::Kitty::Decoder.new
          d.format = Ansi::Kitty::RGBA
          d.width = 0
          d.height = 0
          d
        end,
        input:    Bytes[],
        expected: Ansi::RGBAImage.new(0, 0),
        raises:   true,
      },
      {
        name:    "negative width",
        decoder: begin
          d = Ansi::Kitty::Decoder.new
          d.format = Ansi::Kitty::RGBA
          d.width = -1
          d.height = 1
          d
        end,
        input:    Bytes[255, 0, 0, 255],
        expected: Ansi::RGBAImage.new(0, 0),
        raises:   true,
      },
      {
        name:    "very large dimensions",
        decoder: begin
          d = Ansi::Kitty::Decoder.new
          d.format = Ansi::Kitty::RGBA
          d.width = 1
          d.height = 1000000
          d
        end,
        input:    Bytes[255, 0, 0, 255],
        expected: Ansi::RGBAImage.new(0, 0),
        raises:   true,
      },
    ]

    tests.each do |test_case|
      if test_case[:raises]
        expect_raises(Exception) do
          test_case[:decoder].decode(IO::Memory.new(test_case[:input]))
        end
        next
      end

      result = test_case[:decoder].decode(IO::Memory.new(test_case[:input]))
      images_equal?(result, test_case[:expected]).should be_true
    end
  end
end
