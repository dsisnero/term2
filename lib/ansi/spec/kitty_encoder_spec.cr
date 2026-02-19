require "./spec_helper"
require "compress/zlib"

module Ansi::Kitty
  # Helper to create a 2x2 test image with red and blue pattern (from Go test)
  def self.test_image : Ansi::Image
    image = Ansi::RGBAImage.new(2, 2)
    image.set(0, 0, Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8)) # Red
    image.set(1, 0, Ansi::Color.new(0_u8, 0_u8, 255_u8, 255_u8)) # Blue
    image.set(0, 1, Ansi::Color.new(0_u8, 0_u8, 255_u8, 255_u8)) # Blue
    image.set(1, 1, Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8)) # Red
    image
  end

  # PNG header constant from Go test
  PNG_HEADER = "\x89PNG\r\n\x1a\n"

  # Helper to compare two images for equality
  def self.images_equal?(a : Ansi::Image, b : Ansi::Image) : Bool
    return false if a.width != b.width || a.height != b.height
    a.each_pixel do |x, y, color_a|
      color_b = b.pixel(x, y)
      return false if color_a.r != color_b.r || color_a.g != color_b.g || color_a.b != color_b.b || color_a.a != color_b.a
    end
    true
  end
end

# Port of TestEncoder_Encode from Go's encoder_test.go
describe "Kitty Encoder (port of Go TestEncoder_Encode)" do
  describe "#encode" do
    it "handles nil image (produces empty output)" do
      encoder = Ansi::Kitty::Encoder.new(compress: false, format: Ansi::Kitty::RGBA)
      io = IO::Memory.new
      encoder.encode(io, nil)
      io.to_slice.size.should eq 0
    end

    it "encodes RGBA format" do
      encoder = Ansi::Kitty::Encoder.new(compress: false, format: Ansi::Kitty::RGBA)
      image = Ansi::Kitty.test_image
      io = IO::Memory.new

      encoder.encode(io, image)

      expected = Bytes[
        255, 0, 0, 255, # Red pixel
        0, 0, 255, 255, # Blue pixel
        0, 0, 255, 255, # Blue pixel
        255, 0, 0, 255, # Red pixel
      ]
      io.to_slice.should eq expected
    end

    it "encodes RGB format" do
      encoder = Ansi::Kitty::Encoder.new(compress: false, format: Ansi::Kitty::RGB)
      image = Ansi::Kitty.test_image
      io = IO::Memory.new

      encoder.encode(io, image)

      expected = Bytes[
        255, 0, 0, # Red pixel
        0, 0, 255, # Blue pixel
        0, 0, 255, # Blue pixel
        255, 0, 0, # Red pixel
      ]
      io.to_slice.should eq expected
    end

    it "encodes PNG format" do
      encoder = Ansi::Kitty::Encoder.new(compress: false, format: Ansi::Kitty::PNG)
      image = Ansi::Kitty.test_image
      io = IO::Memory.new

      encoder.encode(io, image)

      # Verify PNG header (first 8 bytes)
      png_header = io.to_slice[0, 8]
      png_header.should eq Ansi::Kitty::PNG_HEADER.to_slice
    end

    it "raises on invalid format" do
      encoder = Ansi::Kitty::Encoder.new(compress: false, format: 999)
      image = Ansi::Kitty.test_image
      io = IO::Memory.new

      expect_raises(Exception, "unsupported format: 999") do
        encoder.encode(io, image)
      end
    end

    it "encodes RGBA with compression" do
      encoder = Ansi::Kitty::Encoder.new(compress: true, format: Ansi::Kitty::RGBA)
      image = Ansi::Kitty.test_image
      io = IO::Memory.new

      encoder.encode(io, image)

      # Decompress the data like Go test does
      io.rewind

      # Use Zlib::Reader to decompress
      decompressed_io = IO::Memory.new
      Compress::Zlib::Reader.open(io) do |reader|
        IO.copy(reader, decompressed_io)
      end

      expected = Bytes[
        255, 0, 0, 255, # Red pixel
        0, 0, 255, 255, # Blue pixel
        0, 0, 255, 255, # Blue pixel
        255, 0, 0, 255, # Red pixel
      ]
      decompressed_io.to_slice.should eq expected
    end

    it "defaults format to RGBA when zero" do
      encoder = Ansi::Kitty::Encoder.new(compress: false, format: 0)
      image = Ansi::Kitty.test_image
      io = IO::Memory.new

      encoder.encode(io, image)

      expected = Bytes[
        255, 0, 0, 255, # Red pixel
        0, 0, 255, 255, # Blue pixel
        0, 0, 255, 255, # Blue pixel
        255, 0, 0, 255, # Red pixel
      ]
      io.to_slice.should eq expected
    end
  end
end

# Port of TestEncoder_EncodeWithDifferentImageTypes from Go's encoder_test.go
describe "Kitty Encoder with different image types (port of Go TestEncoder_EncodeWithDifferentImageTypes)" do
  it "handles different image types" do
    rgba = Ansi::RGBAImage.new(1, 1)
    rgba.set(0, 0, Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8))

    gray = Ansi::GrayImage.new(1, 1)
    gray.set(0, 0, 128_u8)

    tests = [
      {image: rgba, format: Ansi::Kitty::RGBA, want_len: 4},
      {image: gray, format: Ansi::Kitty::RGBA, want_len: 4},
      {image: rgba, format: Ansi::Kitty::RGB, want_len: 3},
      {image: gray, format: Ansi::Kitty::RGB, want_len: 3},
    ]

    tests.each do |test_case|
      io = IO::Memory.new
      encoder = Ansi::Kitty::Encoder.new(compress: false, format: test_case[:format])
      encoder.encode(io, test_case[:image])
      io.to_slice.size.should eq test_case[:want_len]
    end
  end
end
