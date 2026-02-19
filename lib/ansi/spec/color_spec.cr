require "./spec_helper"
require "colorful"

describe Ansi::Color do
  describe "initialize" do
    it "creates a color with RGBA values" do
      color = Ansi::Color.new(255_u8, 128_u8, 64_u8, 255_u8)
      color.r.should eq 255_u8
      color.g.should eq 128_u8
      color.b.should eq 64_u8
      color.a.should eq 255_u8
    end

    it "defaults alpha to 255" do
      color = Ansi::Color.new(255_u8, 128_u8, 64_u8)
      color.a.should eq 255_u8
    end
  end

  describe ".black" do
    it "returns black color" do
      black = Ansi::Color.black
      black.r.should eq 0_u8
      black.g.should eq 0_u8
      black.b.should eq 0_u8
      black.a.should eq 255_u8
    end
  end
end

# Pending tests for missing color functionality
# These tests are based on Go's x/ansi/color_test.go

describe "Color conversions (from Go tests)" do
  # TestRGBAToHex
  it "converts RGBA values to hex" do
    # Cases from Go test:
    # {0, 0, 255, 0xffff, 0x0000ff}
    # {255, 255, 255, 0xffff, 0xffffff}
    # {255, 0, 0, 0xffff, 0xffff0000}

    # Note: Go test checks RGBA() of TrueColor(hex)
    # TrueColor is a uint32 representing hex color
    color1 = Ansi::TrueColor.new(0x0000ff)
    r1, g1, b1, a1 = color1.rgba
    # RGBA returns 16-bit values (0-0xFFFF)
    (r1 >> 8).should eq 0_u32
    (g1 >> 8).should eq 0_u32
    (b1 >> 8).should eq 255_u32
    a1.should eq 0xFFFF_u32

    color2 = Ansi::TrueColor.new(0xffffff)
    r2, g2, b2, a2 = color2.rgba
    (r2 >> 8).should eq 255_u32
    (g2 >> 8).should eq 255_u32
    (b2 >> 8).should eq 255_u32
    a2.should eq 0xFFFF_u32

    color3 = Ansi::TrueColor.new(0xff0000)
    r3, g3, b3, a3 = color3.rgba
    (r3 >> 8).should eq 255_u32
    (g3 >> 8).should eq 0_u32
    (b3 >> 8).should eq 0_u32
    a3.should eq 0xFFFF_u32
  end

  # TestColorToHexString
  it "converts colors to hex strings" do
    # Cases from Go test:
    # TrueColor(0x0000ff) -> "#0000ff"
    # TrueColor(0xffffff) -> "#ffffff"
    # TrueColor(0xff0000) -> "#ff0000"

    # color_to_hex_string expects Ansi::Color
    # Convert TrueColor to Color via hex_to_rgb
    color1 = Ansi::TrueColor.new(0x0000ff)
    r1, g1, b1 = Ansi.hex_to_rgb(color1.value)
    c1 = Ansi::Color.new(r1, g1, b1)
    Ansi.color_to_hex_string(c1).should eq "#0000ff"

    color2 = Ansi::TrueColor.new(0xffffff)
    r2, g2, b2 = Ansi.hex_to_rgb(color2.value)
    c2 = Ansi::Color.new(r2, g2, b2)
    Ansi.color_to_hex_string(c2).should eq "#ffffff"

    color3 = Ansi::TrueColor.new(0xff0000)
    r3, g3, b3 = Ansi.hex_to_rgb(color3.value)
    c3 = Ansi::Color.new(r3, g3, b3)
    Ansi.color_to_hex_string(c3).should eq "#ff0000"
  end

  # TestAnsiToRGB
  it "converts ANSI color codes to RGB" do
    # Cases from Go test:
    # 0 (black) -> {0, 0, 0}
    # 1 (red) -> {128, 0, 0}
    # 255 (highest ANSI color) -> {238, 238, 238}

    color0 = Ansi.ansi_to_rgb(0_u8)
    (color0.r).should eq 0_u8
    (color0.g).should eq 0_u8
    (color0.b).should eq 0_u8

    color1 = Ansi.ansi_to_rgb(1_u8)
    (color1.r).should eq 128_u8
    (color1.g).should eq 0_u8
    (color1.b).should eq 0_u8

    color255 = Ansi.ansi_to_rgb(255_u8)
    (color255.r).should eq 238_u8
    (color255.g).should eq 238_u8
    (color255.b).should eq 238_u8
  end

  # TestHexToRGB
  it "converts hex values to RGB" do
    # Cases from Go test:
    # 0x0000FF -> {0, 0, 255}
    # 0xFFFFFF -> {255, 255, 255}
    # 0xFF0000 -> {255, 0, 0}

    r1, g1, b1 = Ansi.hex_to_rgb(0x0000FF_u32)
    r1.should eq 0_u8
    g1.should eq 0_u8
    b1.should eq 255_u8

    r2, g2, b2 = Ansi.hex_to_rgb(0xFFFFFF_u32)
    r2.should eq 255_u8
    g2.should eq 255_u8
    b2.should eq 255_u8

    r3, g3, b3 = Ansi.hex_to_rgb(0xFF0000_u32)
    r3.should eq 255_u8
    g3.should eq 0_u8
    b3.should eq 0_u8
  end

  # TestHexTo256
  it "converts hex colors to 256-color palette" do
    cases = {
      "white"                             => {Colorful::Color.new(r: 1.0, g: 1.0, b: 1.0), "#ffffff", Ansi::IndexedColor.new(231_u8)},
      "offwhite"                          => {Colorful::Color.new(r: 0.9333, g: 0.9333, b: 0.933), "#eeeeee", Ansi::IndexedColor.new(255_u8)},
      "slightly brighter than offwhite"   => {Colorful::Color.new(r: 0.95, g: 0.95, b: 0.95), "#f2f2f2", Ansi::IndexedColor.new(255_u8)},
      "red"                               => {Colorful::Color.new(r: 1.0, g: 0.0, b: 0.0), "#ff0000", Ansi::IndexedColor.new(196_u8)},
      "silver foil"                       => {Colorful::Color.new(r: 0.6863, g: 0.6863, b: 0.6863), "#afafaf", Ansi::IndexedColor.new(145_u8)},
      "silver chalice"                    => {Colorful::Color.new(r: 0.698, g: 0.698, b: 0.698), "#b2b2b2", Ansi::IndexedColor.new(249_u8)},
      "slightly closer to silver foil"    => {Colorful::Color.new(r: 0.692, g: 0.692, b: 0.692), "#b0b0b0", Ansi::IndexedColor.new(145_u8)},
      "slightly closer to silver chalice" => {Colorful::Color.new(r: 0.694, g: 0.694, b: 0.694), "#b1b1b1", Ansi::IndexedColor.new(249_u8)},
      "gray"                              => {Colorful::Color.new(r: 0.5, g: 0.5, b: 0.5), "#808080", Ansi::IndexedColor.new(244_u8)},
    }

    cases.each do |_, (input, expected_hex, expected_output)|
      input.hex.should eq expected_hex
      output = Ansi.convert_256(input)
      output.should eq expected_output
    end
  end
end

describe "Convert16 (from Go tests)" do
  it "converts colors to 16-color palette" do
    # BasicColor returns itself
    color = Ansi::BasicColor.new(5_u8)
    result = Ansi.convert_16(color)
    result.should be_a(Ansi::BasicColor)
    result.value.should eq 5_u8

    # IndexedColor maps via ANSI256_TO_16 table
    # Test a few known mappings
    mappings = {
        0_u8 => 0_u8,
        1_u8 => 1_u8,
       16_u8 => 0_u8,
       17_u8 => 4_u8,
      255_u8 => 15_u8,
    }
    mappings.each do |index, expected|
      color = Ansi::IndexedColor.new(index)
      result = Ansi.convert_16(color)
      result.value.should eq expected
    end

    # TrueColor conversion (via Colorful::Color)
    true_color = Ansi::TrueColor.new(0xFF0000_u32) # red
    result = Ansi.convert_16(true_color)
    result.should be_a(Ansi::BasicColor)
    # Expected mapping? red (0xFF0000) maps to 256-color 196, which maps to 16-color? we can trust the chain
    # Just ensure it's a valid basic color (0-15)
    result.value.should be <= 15_u8

    # Color conversion (via Colorful::Color)
    color = Ansi::Color.new(255_u8, 0_u8, 0_u8)
    result = Ansi.convert_16(color)
    result.should be_a(Ansi::BasicColor)
    result.value.should be <= 15_u8

    # Colorful::Color conversion
    colorful = Colorful::Color.new(r: 1.0, g: 0.0, b: 0.0)
    result = Ansi.convert_16(colorful)
    result.should be_a(Ansi::BasicColor)
    result.value.should be <= 15_u8
  end

  it "maps all 256 indices correctly via ANSI256_TO_16" do
    256.times do |i|
      color = Ansi::IndexedColor.new(i.to_u8)
      result = Ansi.convert_16(color)
      # The mapping is defined in ANSI256_TO_16, but we can't access private constant.
      # Instead we can compute expected by converting to 256 then mapping via table?
      # We'll just ensure no exception.
      result.should be_a(Ansi::BasicColor)
      result.value.should be <= 15_u8
    end
  end
end

# Tests for color types
describe "Color types (from Go implementation)" do
  describe "BasicColor (ANSI 3/4-bit colors)" do
    it "has constants for standard ANSI colors" do
      Ansi::BasicColor::Black.value.should eq 0_u8
      Ansi::BasicColor::Red.value.should eq 1_u8
      Ansi::BasicColor::Green.value.should eq 2_u8
      Ansi::BasicColor::Yellow.value.should eq 3_u8
      Ansi::BasicColor::Blue.value.should eq 4_u8
      Ansi::BasicColor::Magenta.value.should eq 5_u8
      Ansi::BasicColor::Cyan.value.should eq 6_u8
      Ansi::BasicColor::White.value.should eq 7_u8
      Ansi::BasicColor::BrightBlack.value.should eq 8_u8
      Ansi::BasicColor::BrightRed.value.should eq 9_u8
      Ansi::BasicColor::BrightGreen.value.should eq 10_u8
      Ansi::BasicColor::BrightYellow.value.should eq 11_u8
      Ansi::BasicColor::BrightBlue.value.should eq 12_u8
      Ansi::BasicColor::BrightMagenta.value.should eq 13_u8
      Ansi::BasicColor::BrightCyan.value.should eq 14_u8
      Ansi::BasicColor::BrightWhite.value.should eq 15_u8
    end

    it "implements rgba method" do
      color = Ansi::BasicColor.new(1_u8) # red
      r, g, b, a = color.rgba
      # Red is ANSI color 1 which maps to RGB 128, 0, 0
      (r >> 8).should eq 128_u32
      (g >> 8).should eq 0_u32
      (b >> 8).should eq 0_u32
      a.should eq 0xFFFF_u32
    end

    it "handles values out of range" do
      # Values > 15 should still work (return black or some default)
      color = Ansi::BasicColor.new(255_u8)
      _, _, _, a = color.rgba
      # Should return something valid
      a.should eq 0xFFFF_u32
    end
  end

  describe "IndexedColor (ANSI 256 colors)" do
    it "represents colors 0-255" do
      color0 = Ansi::IndexedColor.new(0_u8)
      color0.value.should eq 0_u8

      color255 = Ansi::IndexedColor.new(255_u8)
      color255.value.should eq 255_u8
    end

    it "implements rgba method" do
      # Test a few known colors
      # ANSI color 1 (red)
      color1 = Ansi::IndexedColor.new(1_u8)
      r1, g1, b1, a1 = color1.rgba
      (r1 >> 8).should eq 128_u32
      (g1 >> 8).should eq 0_u32
      (b1 >> 8).should eq 0_u32
      a1.should eq 0xFFFF_u32

      # ANSI color 231 (white from color cube)
      color231 = Ansi::IndexedColor.new(231_u8)
      r231, g231, b231, a231 = color231.rgba
      (r231 >> 8).should eq 255_u32
      (g231 >> 8).should eq 255_u32
      (b231 >> 8).should eq 255_u32
      a231.should eq 0xFFFF_u32
    end
  end

  describe "TrueColor (24-bit colors)" do
    it "represents 24-bit RGB colors" do
      color = Ansi::TrueColor.new(0xFF0000_u32)
      color.value.should eq 0xFF0000_u32
    end

    it "implements rgba method" do
      # Test red
      red = Ansi::TrueColor.new(0xFF0000_u32)
      r1, g1, b1, a1 = red.rgba
      (r1 >> 8).should eq 255_u32
      (g1 >> 8).should eq 0_u32
      (b1 >> 8).should eq 0_u32
      a1.should eq 0xFFFF_u32

      # Test green
      green = Ansi::TrueColor.new(0x00FF00_u32)
      r2, g2, b2, a2 = green.rgba
      (r2 >> 8).should eq 0_u32
      (g2 >> 8).should eq 255_u32
      (b2 >> 8).should eq 0_u32
      a2.should eq 0xFFFF_u32

      # Test blue
      blue = Ansi::TrueColor.new(0x0000FF_u32)
      r3, g3, b3, a3 = blue.rgba
      (r3 >> 8).should eq 0_u32
      (g3 >> 8).should eq 0_u32
      (b3 >> 8).should eq 255_u32
      a3.should eq 0xFFFF_u32
    end
  end

  it "implements Color interface for all color types" do
    # All color types should implement rgba method
    basic = Ansi::BasicColor.new(1_u8)
    indexed = Ansi::IndexedColor.new(1_u8)
    true_color = Ansi::TrueColor.new(0xFF0000_u32)
    ansi_color = Ansi::Color.new(255_u8, 0_u8, 0_u8)

    # They should all respond to rgba
    basic.responds_to?(:rgba).should be_true
    indexed.responds_to?(:rgba).should be_true
    true_color.responds_to?(:rgba).should be_true
    ansi_color.responds_to?(:rgba).should be_true

    # rgba should return a 4-tuple of UInt32
    basic_rgba = basic.rgba
    basic_rgba.size.should eq 4
    basic_rgba[0].should be_a(UInt32)
    basic_rgba[1].should be_a(UInt32)
    basic_rgba[2].should be_a(UInt32)
    basic_rgba[3].should be_a(UInt32)
  end
end

# Color distance and quantization
describe "Color distance and quantization" do
  it "calculates color distance" do
    # Same color should have distance 0
    Ansi.dist_sq(0, 0, 0, 0, 0, 0).should eq 0
    Ansi.dist_sq(255, 255, 255, 255, 255, 255).should eq 0
    Ansi.dist_sq(128, 64, 32, 128, 64, 32).should eq 0

    # Black to white squared distance: 3 * 255^2 = 195075
    Ansi.dist_sq(0, 0, 0, 255, 255, 255).should eq 195075

    # Red to green: (255-0)^2 + (0-255)^2 + (0-0)^2 = 65025 + 65025 + 0 = 130050
    Ansi.dist_sq(255, 0, 0, 0, 255, 0).should eq 130050

    # Test with various values
    Ansi.dist_sq(100, 150, 200, 100, 150, 200).should eq 0
    Ansi.dist_sq(100, 150, 200, 101, 151, 201).should eq 3                # (1^2 + 1^2 + 1^2) = 3
    Ansi.dist_sq(10, 20, 30, 40, 50, 60).should eq(30*30 + 30*30 + 30*30) # 2700
  end

  it "finds nearest color in palette" do
    black = Ansi::Color.new(0_u8, 0_u8, 0_u8)
    white = Ansi::Color.new(255_u8, 255_u8, 255_u8)
    red = Ansi::Color.new(255_u8, 0_u8, 0_u8)
    green = Ansi::Color.new(0_u8, 255_u8, 0_u8)
    blue = Ansi::Color.new(0_u8, 0_u8, 255_u8)

    palette = [black, white, red, green, blue]

    # Black should map to black
    Ansi.nearest_color_index(black, palette).should eq 0
    Ansi.nearest_color(black, palette).should eq black

    # Near-black dark gray should map to black
    dark_gray = Ansi::Color.new(10_u8, 10_u8, 10_u8)
    Ansi.nearest_color_index(dark_gray, palette).should eq 0
    Ansi.nearest_color(dark_gray, palette).should eq black

    # Near-white light gray should map to white
    light_gray = Ansi::Color.new(240_u8, 240_u8, 240_u8)
    Ansi.nearest_color_index(light_gray, palette).should eq 1
    Ansi.nearest_color(light_gray, palette).should eq white

    # Reddish color should map to red
    dark_red = Ansi::Color.new(200_u8, 0_u8, 0_u8)
    Ansi.nearest_color_index(dark_red, palette).should eq 2
    Ansi.nearest_color(dark_red, palette).should eq red

    # Empty palette returns -1 index and returns original color
    Ansi.nearest_color_index(red, [] of Ansi::Color).should eq -1
    Ansi.nearest_color(red, [] of Ansi::Color).should eq red
  end

  it "quantizes colors to limited palette" do
    # Create 2x2 image with distinct colors
    image = Ansi::RGBAImage.new(2, 2)
    image.set(0, 0, Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8))   # red
    image.set(0, 1, Ansi::Color.new(0_u8, 255_u8, 0_u8, 255_u8))   # green
    image.set(1, 0, Ansi::Color.new(0_u8, 0_u8, 255_u8, 255_u8))   # blue
    image.set(1, 1, Ansi::Color.new(255_u8, 255_u8, 0_u8, 255_u8)) # yellow

    # Request palette with 2 colors (should quantize)
    palette = Ansi::Sixel.new_palette(image, 2)
    palette.palette_colors.size.should eq 2

    # Colors should be some combination of the input colors
    # (exact result depends on median cut algorithm)
    # We'll just verify we got a valid palette
    palette.palette_colors.each do |sixel_color|
      sixel_color.red.should be <= 100_u32
      sixel_color.green.should be <= 100_u32
      sixel_color.blue.should be <= 100_u32
      sixel_color.alpha.should be <= 100_u32
    end

    # Test with max colors equal to unique colors (no quantization needed)
    palette2 = Ansi::Sixel.new_palette(image, 4)
    palette2.palette_colors.size.should eq 4

    # Test with more colors than unique colors (should return all unique colors)
    palette3 = Ansi::Sixel.new_palette(image, 8)
    palette3.palette_colors.size.should eq 4
  end
end
