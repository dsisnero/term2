require "./spec_helper"
require "base64"
require "file_utils"

private def build_test_image : Ansi::RGBAImage
  image = Ansi::RGBAImage.new(2, 2)
  image.set(0, 0, Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8))
  image.set(1, 0, Ansi::Color.new(0_u8, 255_u8, 0_u8, 255_u8))
  image.set(0, 1, Ansi::Color.new(0_u8, 0_u8, 255_u8, 255_u8))
  image.set(1, 1, Ansi::Color.new(255_u8, 255_u8, 255_u8, 255_u8))
  image
end

private def build_large_image : Ansi::RGBAImage
  image = Ansi::RGBAImage.new(100, 100)
  red = Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8)
  100.times do |y|
    100.times do |x|
      image.set(x, y, red)
    end
  end
  image
end

describe "Ansi::Kitty.encode_graphics" do
  it "writes graphics data" do
    img = build_test_image
    img_large = build_large_image

    tmp_dir = File.join(Dir.tempdir, "ansi-#{Random.rand(1_000_000)}")
    FileUtils.mkdir_p(tmp_dir)
    tmp_file = File.join(tmp_dir, "test-image")
    File.write(tmp_file, "test image data")

    begin
      tests = [
        {
          name:    "direct transmission",
          image:   img,
          options: begin
            o = Ansi::Kitty::Options.new
            o.transmission = Ansi::Kitty::Direct
            o.format = Ansi::Kitty::RGB
            o
          end,
          raises: false,
          check:  ->(output : String) {
            output.starts_with?("\e_G").should be_true
            output.ends_with?("\e\\").should be_true
            output.includes?("f=24").should be_true
          },
        },
        {
          name:    "chunked transmission",
          image:   img_large,
          options: begin
            o = Ansi::Kitty::Options.new
            o.transmission = Ansi::Kitty::Direct
            o.format = Ansi::Kitty::RGB
            o.chunk = true
            o
          end,
          raises: false,
          check:  ->(output : String) {
            chunks = output.split("\e\\")
            chunks.size.should be >= 2
            chunks = chunks[0, chunks.size - 1]
            chunks.each_with_index do |chunk, i|
              if i == chunks.size - 1
                chunk.includes?("m=0").should be_true
              else
                chunk.includes?("m=1").should be_true
              end
            end
          },
        },
        {
          name:    "file transmission",
          image:   img,
          options: begin
            o = Ansi::Kitty::Options.new
            o.transmission = Ansi::Kitty::File
            o.file = tmp_file
            o
          end,
          raises: false,
          check:  ->(output : String) {
            encoded = Base64.strict_encode(tmp_file.to_slice)
            output.includes?(encoded).should be_true
          },
        },
        {
          name:    "temp file transmission",
          image:   img,
          options: begin
            o = Ansi::Kitty::Options.new
            o.transmission = Ansi::Kitty::TempFile
            o
          end,
          raises: false,
          check:  ->(output : String) {
            stripped = output.sub(/^\e_G/, "").sub(/\e\\$/, "")
            payload = stripped.split(";")[1]
            decoded = String.new(Base64.decode(payload))
            decoded.includes?("tty-graphics-protocol").should be_true
            stripped.includes?("t=t").should be_true
          },
        },
        {
          name:    "compression enabled",
          image:   img,
          options: begin
            o = Ansi::Kitty::Options.new
            o.transmission = Ansi::Kitty::Direct
            o.compression = Ansi::Kitty::Zlib
            o
          end,
          raises: false,
          check:  ->(output : String) {
            output.includes?("o=z").should be_true
          },
        },
        {
          name:    "invalid file path",
          image:   img,
          options: begin
            o = Ansi::Kitty::Options.new
            o.transmission = Ansi::Kitty::File
            o.file = "/nonexistent/file"
            o
          end,
          raises: true,
          check:  nil,
        },
        {
          name:    "nil options",
          image:   img,
          options: nil,
          raises:  false,
          check:   ->(output : String) {
            output.starts_with?("\e_G").should be_true
          },
        },
      ]

      tests.each do |test_case|
        io = IO::Memory.new
        if test_case[:raises]
          expect_raises(Exception) do
            Ansi::Kitty.encode_graphics(io, test_case[:image], test_case[:options])
          end
          next
        end

        Ansi::Kitty.encode_graphics(io, test_case[:image], test_case[:options])
        test_case[:check].try(&.call(io.to_s))
      end
    ensure
      File.delete(tmp_file) if File.exists?(tmp_file)
      FileUtils.rm_rf(tmp_dir) if Dir.exists?(tmp_dir)
    end
  end

  it "handles edge cases" do
    tests = [
      {
        name:    "zero size image",
        image:   Ansi::RGBAImage.new(0, 0),
        options: begin
          o = Ansi::Kitty::Options.new
          o.transmission = Ansi::Kitty::Direct
          o
        end,
        raises: false,
      },
      {
        name:    "shared memory transmission",
        image:   Ansi::RGBAImage.new(1, 1),
        options: begin
          o = Ansi::Kitty::Options.new
          o.transmission = Ansi::Kitty::SharedMemory
          o
        end,
        raises: true,
      },
      {
        name:    "file transmission without file path",
        image:   Ansi::RGBAImage.new(1, 1),
        options: begin
          o = Ansi::Kitty::Options.new
          o.transmission = Ansi::Kitty::File
          o
        end,
        raises: true,
      },
    ]

    tests.each do |test_case|
      io = IO::Memory.new
      if test_case[:raises]
        expect_raises(Exception) do
          Ansi::Kitty.encode_graphics(io, test_case[:image], test_case[:options])
        end
      else
        Ansi::Kitty.encode_graphics(io, test_case[:image], test_case[:options])
      end
    end
  end
end
