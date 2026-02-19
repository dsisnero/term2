require "./spec_helper"
require "compress/zlib"

# Helper to create a 2x2 test image with red and blue pattern (from Go test)
private def test_image : Ansi::Image
  image = Ansi::RGBAImage.new(2, 2)
  image.set(0, 0, Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8)) # Red
  image.set(1, 0, Ansi::Color.new(0_u8, 0_u8, 255_u8, 255_u8)) # Blue
  image.set(0, 1, Ansi::Color.new(0_u8, 0_u8, 255_u8, 255_u8)) # Blue
  image.set(1, 1, Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8)) # Red
  image
end

describe Ansi::Kitty do
  describe "constants" do
    it "has format constants" do
      Ansi::Kitty::RGBA.should eq 32
      Ansi::Kitty::RGB.should eq 24
      Ansi::Kitty::PNG.should eq 100
    end

    it "has compression constant" do
      Ansi::Kitty::Zlib.should eq 'z'.ord.to_u8
    end

    it "has transmission mode constants" do
      Ansi::Kitty::Direct.should eq 'd'.ord.to_u8
      Ansi::Kitty::File.should eq 'f'.ord.to_u8
      Ansi::Kitty::TempFile.should eq 't'.ord.to_u8
      Ansi::Kitty::SharedMemory.should eq 's'.ord.to_u8
    end
  end

  describe "Encoder" do
    describe "#encode" do
      it "handles empty image (zero width or height)" do
        encoder = Ansi::Kitty::Encoder.new
        image = Ansi::RGBAImage.new(0, 0)
        io = IO::Memory.new

        encoder.encode(io, image)
        io.to_slice.size.should eq 0
      end
    end
  end

  describe ".encode_graphics" do
    it "encodes image with direct transmission" do
      image = test_image
      options = Ansi::Kitty::Options.new
      options.transmission = Ansi::Kitty::Direct
      options.format = Ansi::Kitty::RGBA

      io = IO::Memory.new
      Ansi::Kitty.encode_graphics(io, image, options)

      # Should produce some output
      io.pos.should be > 0
    end

    it "handles nil options" do
      image = test_image
      io = IO::Memory.new

      Ansi::Kitty.encode_graphics(io, image, nil)
      io.pos.should be > 0
    end
  end

  describe "Options" do
    describe "#options" do
      it "returns empty array for default options" do
        opts = Ansi::Kitty::Options.new
        opts.options.should be_a(Array(String))
        # Default format is 0, which becomes RGBA in options method
        # So format option should not appear (since it's the default)
        opts.options.should_not contain("f=32")
      end

      it "includes non-default format" do
        opts = Ansi::Kitty::Options.new
        opts.format = Ansi::Kitty::RGB
        opts.options.should contain("f=24")
      end
    end
  end
end
