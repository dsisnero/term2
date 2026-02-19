require "./spec_helper"

describe Ansi::Sixel do
  describe "Raster" do
    it "basic case" do
      raster = Ansi::Sixel::Raster.new(pan: 1, pad: 2)
      raster.to_s.should eq "\"1;2"
    end

    it "with ph and pv" do
      raster = Ansi::Sixel::Raster.new(pan: 2, pad: 3, ph: 4, pv: 5)
      raster.to_s.should eq "\"2;3;4;5"
    end

    it "zero pad converts to 1,1" do
      raster = Ansi::Sixel::Raster.new(pan: 2, pad: 0)
      raster.to_s.should eq "\"1;1"
    end

    it "with ph only" do
      raster = Ansi::Sixel::Raster.new(pan: 1, pad: 2, ph: 3, pv: 0)
      raster.to_s.should eq "\"1;2;3;0"
    end

    it "with pv only" do
      raster = Ansi::Sixel::Raster.new(pan: 1, pad: 2, ph: 0, pv: 3)
      raster.to_s.should eq "\"1;2;0;3"
    end
  end

  describe "Repeat" do
    it "basic repeat" do
      repeat = Ansi::Sixel::Repeat.new(count: 3, char: 'A')
      repeat.to_s.should eq "!3A"
    end

    it "single digit" do
      repeat = Ansi::Sixel::Repeat.new(count: 5, char: '#')
      repeat.to_s.should eq "!5#"
    end

    it "multiple digits" do
      repeat = Ansi::Sixel::Repeat.new(count: 123, char: 'x')
      repeat.to_s.should eq "!123x"
    end

    it "zero count" do
      repeat = Ansi::Sixel::Repeat.new(count: 0, char: 'B')
      repeat.to_s.should eq "!0B"
    end
  end

  # Missing functionality tests - marked as pending
  describe "WriteColor (from Go TestWriteColor)" do
    it "simple color number" do
      io = IO::Memory.new
      Ansi::Sixel.write_color(io, 1, 0, 0, 0, 0)
      io.to_s.should eq "#1"
    end

    it "RGB color" do
      io = IO::Memory.new
      Ansi::Sixel.write_color(io, 1, 2, 50, 60, 70)
      io.to_s.should eq "#1;2;50;60;70"
    end

    it "HLS color" do
      io = IO::Memory.new
      Ansi::Sixel.write_color(io, 2, 1, 180, 50, 100)
      io.to_s.should eq "#2;1;180;50;100"
    end

    it "invalid pu > 2" do
      io = IO::Memory.new
      Ansi::Sixel.write_color(io, 1, 3, 0, 0, 0)
      io.to_s.should eq "#1"
    end
  end

  describe "DecodeColor (from Go TestDecodeColor)" do
    it "simple color number" do
      data = "#1".to_slice
      color, n = Ansi::Sixel.decode_color(data)
      color.pc.should eq 1
      color.pu.should eq 0
      color.px.should eq 0
      color.py.should eq 0
      color.pz.should eq 0
      n.should eq 2
    end

    it "RGB color" do
      data = "#1;2;50;60;70".to_slice
      color, n = Ansi::Sixel.decode_color(data)
      color.pc.should eq 1
      color.pu.should eq 2
      color.px.should eq 50
      color.py.should eq 60
      color.pz.should eq 70
      n.should eq 13
    end

    it "HLS color" do
      data = "#2;1;180;50;100".to_slice
      color, n = Ansi::Sixel.decode_color(data)
      color.pc.should eq 2
      color.pu.should eq 1
      color.px.should eq 180
      color.py.should eq 50
      color.pz.should eq 100
      n.should eq 15
    end

    it "empty input" do
      data = "".to_slice
      color, n = Ansi::Sixel.decode_color(data)
      color.pc.should eq 0
      color.pu.should eq 0
      color.px.should eq 0
      color.py.should eq 0
      color.pz.should eq 0
      n.should eq 0
    end

    it "invalid introducer" do
      data = "X1".to_slice
      color, n = Ansi::Sixel.decode_color(data)
      color.pc.should eq 0
      color.pu.should eq 0
      color.px.should eq 0
      color.py.should eq 0
      color.pz.should eq 0
      n.should eq 0
    end

    it "incomplete sequence" do
      data = "#".to_slice
      color, n = Ansi::Sixel.decode_color(data)
      color.pc.should eq 0
      color.pu.should eq 0
      color.px.should eq 0
      color.py.should eq 0
      color.pz.should eq 0
      n.should eq 0
    end
  end

  describe "Color RGBA (from Go TestColor_RGBA)" do
    it "default color map 0 (black)" do
      color = Ansi::Sixel::Color.new(pc: 0)
      r, g, b, a = color.rgba
      r.should eq 0x0000_u32
      g.should eq 0x0000_u32
      b.should eq 0x0000_u32
      a.should eq 0xFFFF_u32
    end

    it "RGB mode (50%, 60%, 70%)" do
      color = Ansi::Sixel::Color.new(pc: 1, pu: 2, px: 50, py: 60, pz: 70)
      r, g, b, a = color.rgba
      r.should eq 0x8080_u32
      g.should eq 0x9999_u32
      b.should eq 0xB3B3_u32
      a.should eq 0xFFFF_u32
    end

    it "HLS mode (180°, 50%, 100%)" do
      color = Ansi::Sixel::Color.new(pc: 1, pu: 1, px: 180, py: 50, pz: 100)
      r, g, b, a = color.rgba
      # Expected: red=0, green=0xFFFF, blue=0xFFFF, alpha=0xFFFF
      # Allow small floating point error in HSL conversion
      r.should eq 0x0000_u32
      g.should eq 0xFFFF_u32
      b.should eq 0xFFFF_u32
      a.should eq 0xFFFF_u32
    end
  end

  describe "sixelRGB (from Go TestSixelRGB)" do
    it "black" do
      color = Ansi::Sixel.sixel_rgb(0, 0, 0)
      color.r.should eq 0_u8
      color.g.should eq 0_u8
      color.b.should eq 0_u8
      color.a.should eq 0xFF_u8
    end

    it "white" do
      color = Ansi::Sixel.sixel_rgb(100, 100, 100)
      color.r.should eq 0xFF_u8
      color.g.should eq 0xFF_u8
      color.b.should eq 0xFF_u8
      color.a.should eq 0xFF_u8
    end

    it "red" do
      color = Ansi::Sixel.sixel_rgb(100, 0, 0)
      color.r.should eq 0xFF_u8
      color.g.should eq 0_u8
      color.b.should eq 0_u8
      color.a.should eq 0xFF_u8
    end

    it "half intensity" do
      color = Ansi::Sixel.sixel_rgb(50, 50, 50)
      color.r.should eq 128_u8
      color.g.should eq 128_u8
      color.b.should eq 128_u8
      color.a.should eq 0xFF_u8
    end
  end

  describe "sixelHLS (from Go TestSixelHLS)" do
    it "black" do
      color = Ansi::Sixel.sixel_hls(0, 0, 0)
      color.r.should eq 0_u8
      color.g.should eq 0_u8
      color.b.should eq 0_u8
      color.a.should eq 0xFF_u8
    end

    it "white" do
      color = Ansi::Sixel.sixel_hls(0, 100, 0)
      color.r.should eq 0xFF_u8
      color.g.should eq 0xFF_u8
      color.b.should eq 0xFF_u8
      color.a.should eq 0xFF_u8
    end

    it "pure red" do
      color = Ansi::Sixel.sixel_hls(0, 50, 100)
      color.r.should eq 0xFF_u8
      color.g.should eq 0_u8
      color.b.should eq 0_u8
      color.a.should eq 0xFF_u8
    end

    it "pure green" do
      color = Ansi::Sixel.sixel_hls(120, 50, 100)

      color.r.should eq 0_u8
      color.g.should eq 0xFF_u8
      color.b.should eq 0_u8
      color.a.should eq 0xFF_u8
    end

    it "pure blue" do
      color = Ansi::Sixel.sixel_hls(240, 50, 100)
      color.r.should eq 0_u8
      color.g.should eq 0_u8
      color.b.should eq 0xFF_u8
      color.a.should eq 0xFF_u8
    end
  end

  describe "DecodeRaster (from Go TestDecodeRaster)" do
    it "basic case" do
      data = "\"1;2".to_slice
      raster, n = Ansi::Sixel.decode_raster(data)
      raster.pan.should eq 1
      raster.pad.should eq 2
      raster.ph.should eq 0
      raster.pv.should eq 0
      n.should eq 4
    end

    it "full attributes" do
      data = "\"2;3;4;5".to_slice
      raster, n = Ansi::Sixel.decode_raster(data)
      raster.pan.should eq 2
      raster.pad.should eq 3
      raster.ph.should eq 4
      raster.pv.should eq 5
      n.should eq 8
    end

    it "empty input" do
      data = "".to_slice
      raster, n = Ansi::Sixel.decode_raster(data)
      raster.pan.should eq 0
      raster.pad.should eq 0
      raster.ph.should eq 0
      raster.pv.should eq 0
      n.should eq 0
    end

    it "invalid start character" do
      data = "x1;2".to_slice
      raster, n = Ansi::Sixel.decode_raster(data)
      raster.pan.should eq 0
      raster.pad.should eq 0
      raster.ph.should eq 0
      raster.pv.should eq 0
      n.should eq 0
    end

    it "too short" do
      data = "\"1".to_slice
      raster, n = Ansi::Sixel.decode_raster(data)
      raster.pan.should eq 1
      raster.pad.should eq 0
      raster.ph.should eq 0
      raster.pv.should eq 0
      n.should eq 2
    end

    it "invalid character" do
      data = "\"1;a".to_slice
      raster, n = Ansi::Sixel.decode_raster(data)
      raster.pan.should eq 1
      raster.pad.should eq 0
      raster.ph.should eq 0
      raster.pv.should eq 0
      n.should eq 3
    end

    it "partial attributes" do
      data = "\"1;2;3".to_slice
      raster, n = Ansi::Sixel.decode_raster(data)
      raster.pan.should eq 1
      raster.pad.should eq 2
      raster.ph.should eq 3
      raster.pv.should eq 0
      n.should eq 6
    end
  end

  describe "DecodeRepeat (from Go TestDecodeRepeat)" do
    it "basic repeat" do
      data = "!3A".to_slice
      repeat, n = Ansi::Sixel.decode_repeat(data)
      repeat.count.should eq 3
      repeat.char.should eq 'A'
      n.should eq 3
    end

    it "multiple digits" do
      data = "!123x".to_slice
      repeat, n = Ansi::Sixel.decode_repeat(data)
      repeat.count.should eq 123
      repeat.char.should eq 'x'
      n.should eq 5
    end

    it "empty input" do
      data = "".to_slice
      repeat, n = Ansi::Sixel.decode_repeat(data)
      repeat.count.should eq 0
      repeat.char.should eq '\0'
      n.should eq 0
    end

    it "invalid introducer" do
      data = "X3A".to_slice
      repeat, n = Ansi::Sixel.decode_repeat(data)
      repeat.count.should eq 0
      repeat.char.should eq '\0'
      n.should eq 0
    end

    it "incomplete sequence" do
      data = "!3".to_slice
      repeat, n = Ansi::Sixel.decode_repeat(data)
      repeat.count.should eq 0
      repeat.char.should eq '\0'
      n.should eq 0
    end
  end

  describe "Palette creation (from Go TestPaletteCreationRedGreen)" do
    it "way too many colors" do
      # Create 2x2 image with red and green at full/half intensity
      image = Ansi::RGBAImage.new(2, 2)
      image.set(0, 0, Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8)) # red
      image.set(0, 1, Ansi::Color.new(128_u8, 0_u8, 0_u8, 255_u8)) # half red
      image.set(1, 0, Ansi::Color.new(0_u8, 255_u8, 0_u8, 255_u8)) # green
      image.set(1, 1, Ansi::Color.new(0_u8, 128_u8, 0_u8, 255_u8)) # half green

      palette = Ansi::Sixel.new_palette(image, 16)
      palette.palette_colors.size.should eq 4

      expected = [
        Ansi::Sixel::SixelColor.new(100_u32, 0_u32, 0_u32, 100_u32),
        Ansi::Sixel::SixelColor.new(50_u32, 0_u32, 0_u32, 100_u32),
        Ansi::Sixel::SixelColor.new(0_u32, 100_u32, 0_u32, 100_u32),
        Ansi::Sixel::SixelColor.new(0_u32, 50_u32, 0_u32, 100_u32),
      ]

      expected.each do |exp|
        palette.palette_colors.should contain(exp)
      end
    end

    it "just the right number of colors" do
      image = Ansi::RGBAImage.new(2, 2)
      image.set(0, 0, Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8))
      image.set(0, 1, Ansi::Color.new(128_u8, 0_u8, 0_u8, 255_u8))
      image.set(1, 0, Ansi::Color.new(0_u8, 255_u8, 0_u8, 255_u8))
      image.set(1, 1, Ansi::Color.new(0_u8, 128_u8, 0_u8, 255_u8))

      palette = Ansi::Sixel.new_palette(image, 4)
      palette.palette_colors.size.should eq 4

      expected = [
        Ansi::Sixel::SixelColor.new(100_u32, 0_u32, 0_u32, 100_u32),
        Ansi::Sixel::SixelColor.new(50_u32, 0_u32, 0_u32, 100_u32),
        Ansi::Sixel::SixelColor.new(0_u32, 100_u32, 0_u32, 100_u32),
        Ansi::Sixel::SixelColor.new(0_u32, 50_u32, 0_u32, 100_u32),
      ]

      expected.each do |exp|
        palette.palette_colors.should contain(exp)
      end
    end

    it "color reduction" do
      image = Ansi::RGBAImage.new(2, 2)
      image.set(0, 0, Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8))
      image.set(0, 1, Ansi::Color.new(128_u8, 0_u8, 0_u8, 255_u8))
      image.set(1, 0, Ansi::Color.new(0_u8, 255_u8, 0_u8, 255_u8))
      image.set(1, 1, Ansi::Color.new(0_u8, 128_u8, 0_u8, 255_u8))

      palette = Ansi::Sixel.new_palette(image, 2)
      palette.palette_colors.size.should eq 2

      expected = [
        Ansi::Sixel::SixelColor.new(75_u32, 0_u32, 0_u32, 100_u32),
        Ansi::Sixel::SixelColor.new(0_u32, 75_u32, 0_u32, 100_u32),
      ]

      expected.each do |exp|
        palette.palette_colors.should contain(exp)
      end
    end
  end

  describe "Palette with semi-transparency (from Go TestPaletteWithSemiTransparency)" do
    it "just the right number of colors" do
      # Create 2x2 image with blue at different intensities and alpha values
      image = Ansi::RGBAImage.new(2, 2)
      image.set(0, 0, Ansi::Color.new(0_u8, 0_u8, 255_u8, 255_u8)) # blue, opaque
      image.set(0, 1, Ansi::Color.new(0_u8, 0_u8, 128_u8, 255_u8)) # half blue, opaque
      image.set(1, 0, Ansi::Color.new(0_u8, 0_u8, 255_u8, 128_u8)) # blue, semi-transparent
      image.set(1, 1, Ansi::Color.new(0_u8, 0_u8, 255_u8, 0_u8))   # blue, transparent

      palette = Ansi::Sixel.new_palette(image, 4)
      palette.palette_colors.size.should eq 4

      expected = [
        Ansi::Sixel::SixelColor.new(0_u32, 0_u32, 100_u32, 100_u32),
        Ansi::Sixel::SixelColor.new(0_u32, 0_u32, 50_u32, 100_u32),
        Ansi::Sixel::SixelColor.new(0_u32, 0_u32, 100_u32, 50_u32),
        Ansi::Sixel::SixelColor.new(0_u32, 0_u32, 100_u32, 0_u32),
      ]

      expected.each do |exp|
        palette.palette_colors.should contain(exp)
      end
    end

    it "color reduction" do
      image = Ansi::RGBAImage.new(2, 2)
      image.set(0, 0, Ansi::Color.new(0_u8, 0_u8, 255_u8, 255_u8))
      image.set(0, 1, Ansi::Color.new(0_u8, 0_u8, 128_u8, 255_u8))
      image.set(1, 0, Ansi::Color.new(0_u8, 0_u8, 255_u8, 128_u8))
      image.set(1, 1, Ansi::Color.new(0_u8, 0_u8, 255_u8, 0_u8))

      palette = Ansi::Sixel.new_palette(image, 2)
      palette.palette_colors.size.should eq 2

      expected = [
        Ansi::Sixel::SixelColor.new(0_u32, 0_u32, 75_u32, 100_u32),
        Ansi::Sixel::SixelColor.new(0_u32, 0_u32, 100_u32, 25_u32),
      ]

      expected.each do |exp|
        palette.palette_colors.should contain(exp)
      end
    end
  end

  describe "ScanSize (from Go TestScanSize)" do
    it "two lines" do
      decoder = Ansi::Sixel::Decoder.new
      width, height = decoder.scan_size("~~~~~~-~~~~~~-".to_slice)
      width.should eq 6
      height.should eq 12
    end

    it "two lines no newline at end" do
      decoder = Ansi::Sixel::Decoder.new
      width, height = decoder.scan_size("~~~~~~-~~~~~~".to_slice)
      width.should eq 6
      height.should eq 12
    end

    it "no pixels" do
      decoder = Ansi::Sixel::Decoder.new
      width, height = decoder.scan_size("".to_slice)
      width.should eq 0
      height.should eq 0
    end

    it "smaller carriage returns" do
      decoder = Ansi::Sixel::Decoder.new
      width, height = decoder.scan_size("~$~~$~~~$~~~~$~~~~~$~~~~~~".to_slice)
      width.should eq 6
      height.should eq 6
    end

    it "transparent" do
      decoder = Ansi::Sixel::Decoder.new
      width, height = decoder.scan_size("??????".to_slice)
      width.should eq 6
      height.should eq 6
    end

    it "RLE" do
      decoder = Ansi::Sixel::Decoder.new
      width, height = decoder.scan_size("??!20?".to_slice)
      width.should eq 22
      height.should eq 6
    end

    it "Colors" do
      decoder = Ansi::Sixel::Decoder.new
      data = "#0;2;0;0;0~~~~~$#1;2;100;100;100;~~~~~~-#0~~~~~~-#1~~~~~~".to_slice
      width, height = decoder.scan_size(data)
      width.should eq 6
      height.should eq 18
    end
  end

  describe "FullImage (from Go TestFullImage)" do
    it "3x12 single color filled" do
      image_width = 3
      image_height = 12
      img = Ansi::RGBAImage.new(image_width, image_height, Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8))
      color = Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8)

      image_height.times do |y|
        image_width.times do |x|
          img.set(x, y, color)
        end
      end

      io = IO::Memory.new
      encoder = Ansi::Sixel::Encoder.new
      decoder = Ansi::Sixel::Decoder.new

      encoder.encode(io, img)
      io.rewind
      decoded = decoder.decode(io)

      decoded.width.should eq image_width
      decoded.height.should eq image_height

      image_height.times do |y|
        image_width.times do |x|
          decoded.pixel(x, y).should eq color
        end
      end
    end

    it "3x12 two color filled" do
      image_width = 3
      image_height = 12
      img = Ansi::RGBAImage.new(image_width, image_height, Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8))

      colors = {
         0 => Ansi::Color.new(0_u8, 0_u8, 255_u8, 255_u8),
         9 => Ansi::Color.new(0_u8, 255_u8, 0_u8, 255_u8),
        18 => Ansi::Color.new(0_u8, 0_u8, 255_u8, 255_u8),
        27 => Ansi::Color.new(0_u8, 255_u8, 0_u8, 255_u8),
      }

      current_color = Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8)
      image_height.times do |y|
        image_width.times do |x|
          index = y * image_width + x
          new_color = colors[index]?
          current_color = new_color if new_color
          img.set(x, y, current_color)
        end
      end

      io = IO::Memory.new
      encoder = Ansi::Sixel::Encoder.new
      decoder = Ansi::Sixel::Decoder.new

      encoder.encode(io, img)
      io.rewind
      decoded = decoder.decode(io)

      decoded.width.should eq image_width
      decoded.height.should eq image_height

      # Verify each pixel
      current_color = Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8)
      image_height.times do |y|
        image_width.times do |x|
          index = y * image_width + x
          new_color = colors[index]?
          current_color = new_color if new_color
          decoded.pixel(x, y).should eq current_color
        end
      end
    end

    it "3x12 8 color with right gutter" do
      image_width = 3
      image_height = 12
      img = Ansi::RGBAImage.new(image_width, image_height, Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8))

      colors = {
         0 => Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8),
         2 => Ansi::Color.new(0_u8, 255_u8, 0_u8, 255_u8),
         3 => Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8),
         5 => Ansi::Color.new(0_u8, 255_u8, 0_u8, 255_u8),
         6 => Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8),
         8 => Ansi::Color.new(0_u8, 255_u8, 0_u8, 255_u8),
         9 => Ansi::Color.new(0_u8, 0_u8, 255_u8, 255_u8),
        11 => Ansi::Color.new(128_u8, 128_u8, 0_u8, 255_u8),
        12 => Ansi::Color.new(0_u8, 0_u8, 255_u8, 255_u8),
        14 => Ansi::Color.new(128_u8, 128_u8, 0_u8, 255_u8),
        15 => Ansi::Color.new(0_u8, 0_u8, 255_u8, 255_u8),
        17 => Ansi::Color.new(128_u8, 128_u8, 0_u8, 255_u8),
        18 => Ansi::Color.new(0_u8, 128_u8, 128_u8, 255_u8),
        20 => Ansi::Color.new(128_u8, 0_u8, 128_u8, 255_u8),
        21 => Ansi::Color.new(0_u8, 128_u8, 128_u8, 255_u8),
        23 => Ansi::Color.new(128_u8, 0_u8, 128_u8, 255_u8),
        24 => Ansi::Color.new(0_u8, 128_u8, 128_u8, 255_u8),
        26 => Ansi::Color.new(128_u8, 0_u8, 128_u8, 255_u8),
        27 => Ansi::Color.new(64_u8, 0_u8, 0_u8, 255_u8),
        29 => Ansi::Color.new(0_u8, 64_u8, 0_u8, 255_u8),
        30 => Ansi::Color.new(64_u8, 0_u8, 0_u8, 255_u8),
        32 => Ansi::Color.new(0_u8, 64_u8, 0_u8, 255_u8),
        33 => Ansi::Color.new(64_u8, 0_u8, 0_u8, 255_u8),
        35 => Ansi::Color.new(0_u8, 64_u8, 0_u8, 255_u8),
      }

      current_color = Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8)
      image_height.times do |y|
        image_width.times do |x|
          index = y * image_width + x
          new_color = colors[index]?
          current_color = new_color if new_color
          img.set(x, y, current_color)
        end
      end

      io = IO::Memory.new
      encoder = Ansi::Sixel::Encoder.new
      decoder = Ansi::Sixel::Decoder.new

      encoder.encode(io, img)
      io.rewind
      decoded = decoder.decode(io)

      decoded.width.should eq image_width
      decoded.height.should eq image_height

      # Verify each pixel
      current_color = Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8)
      image_height.times do |y|
        image_width.times do |x|
          index = y * image_width + x
          new_color = colors[index]?
          current_color = new_color if new_color
          decoded.pixel(x, y).should eq current_color
        end
      end
    end

    it "3x12 single color with transparent band in the middle" do
      image_width = 3
      image_height = 12
      img = Ansi::RGBAImage.new(image_width, image_height, Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8))

      colors = {
         0 => Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8),
        15 => Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8),
        21 => Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8),
      }

      current_color = Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8)
      image_height.times do |y|
        image_width.times do |x|
          index = y * image_width + x
          new_color = colors[index]?
          current_color = new_color if new_color
          img.set(x, y, current_color)
        end
      end

      io = IO::Memory.new
      encoder = Ansi::Sixel::Encoder.new
      decoder = Ansi::Sixel::Decoder.new

      encoder.encode(io, img)
      io.rewind
      decoded = decoder.decode(io)

      decoded.width.should eq image_width
      decoded.height.should eq image_height

      # Verify each pixel
      current_color = Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8)
      image_height.times do |y|
        image_width.times do |x|
          index = y * image_width + x
          new_color = colors[index]?
          current_color = new_color if new_color
          decoded.pixel(x, y).should eq current_color
        end
      end
    end

    it "3x5 single color" do
      image_width = 3
      image_height = 5
      img = Ansi::RGBAImage.new(image_width, image_height, Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8))
      color = Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8)

      image_height.times do |y|
        image_width.times do |x|
          img.set(x, y, color)
        end
      end

      io = IO::Memory.new
      encoder = Ansi::Sixel::Encoder.new
      decoder = Ansi::Sixel::Decoder.new

      encoder.encode(io, img)
      io.rewind
      decoded = decoder.decode(io)

      decoded.width.should eq image_width
      decoded.height.should eq image_height

      image_height.times do |y|
        image_width.times do |x|
          decoded.pixel(x, y).should eq color
        end
      end
    end

    it "12x4 single color use RLE" do
      image_width = 12
      image_height = 4
      img = Ansi::RGBAImage.new(image_width, image_height, Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8))
      color = Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8)

      image_height.times do |y|
        image_width.times do |x|
          img.set(x, y, color)
        end
      end

      io = IO::Memory.new
      encoder = Ansi::Sixel::Encoder.new
      decoder = Ansi::Sixel::Decoder.new

      encoder.encode(io, img)
      io.rewind
      decoded = decoder.decode(io)

      decoded.width.should eq image_width
      decoded.height.should eq image_height

      image_height.times do |y|
        image_width.times do |x|
          decoded.pixel(x, y).should eq color
        end
      end
    end

    it "12x1 two color use RLE" do
      image_width = 12
      image_height = 1
      img = Ansi::RGBAImage.new(image_width, image_height, Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8))

      colors = {
        0 => Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8),
        6 => Ansi::Color.new(0_u8, 255_u8, 0_u8, 255_u8),
      }

      current_color = Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8)
      image_height.times do |y|
        image_width.times do |x|
          index = y * image_width + x
          new_color = colors[index]?
          current_color = new_color if new_color
          img.set(x, y, current_color)
        end
      end

      io = IO::Memory.new
      encoder = Ansi::Sixel::Encoder.new
      decoder = Ansi::Sixel::Decoder.new

      encoder.encode(io, img)
      io.rewind
      decoded = decoder.decode(io)

      decoded.width.should eq image_width
      decoded.height.should eq image_height

      # Verify each pixel
      current_color = Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8)
      image_height.times do |y|
        image_width.times do |x|
          index = y * image_width + x
          new_color = colors[index]?
          current_color = new_color if new_color
          decoded.pixel(x, y).should eq current_color
        end
      end
    end

    it "12x12 single color use RLE" do
      image_width = 12
      image_height = 12
      img = Ansi::RGBAImage.new(image_width, image_height, Ansi::Color.new(0_u8, 0_u8, 0_u8, 0_u8))
      color = Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8)

      image_height.times do |y|
        image_width.times do |x|
          img.set(x, y, color)
        end
      end

      io = IO::Memory.new
      encoder = Ansi::Sixel::Encoder.new
      decoder = Ansi::Sixel::Decoder.new

      encoder.encode(io, img)
      io.rewind
      decoded = decoder.decode(io)

      decoded.width.should eq image_width
      decoded.height.should eq image_height

      image_height.times do |y|
        image_width.times do |x|
          decoded.pixel(x, y).should eq color
        end
      end
    end
  end

  describe "Encoder" do
    it "exists" do
      Ansi::Sixel::Encoder.new.should be_a(Ansi::Sixel::Encoder)
    end

    # Actual encoder tests will need image creation and encoding
    # We'll add those after we verify the encoder works
  end
end
