require "./spec_helper"
require "colorful"

describe "Ansi background color functions" do
  describe ".set_foreground_color" do
    it "returns sequence with empty string" do
      Ansi.set_foreground_color("").should eq "\e]10;\a"
    end

    it "accepts HexColor and returns correct sequence" do
      hex_color = Ansi::HexColor.new("#ff0000")
      Ansi.set_foreground_color(hex_color.hex).should eq "\e]10;#ff0000\a"

      # Test with 3-digit hex
      hex_color3 = Ansi::HexColor.new("#f00")
      Ansi.set_foreground_color(hex_color3.hex).should eq "\e]10;#ff0000\a"

      # Test with other colors from Go test
      # In Go test: brightMagenta.Hex() -> "#ff00ff"
      # We can create HexColor directly
      magenta_hex = Ansi::HexColor.new("#ff00ff")
      Ansi.set_foreground_color(magenta_hex.hex).should eq "\e]10;#ff00ff\a"
    end
  end

  describe ".set_background_color" do
    it "returns sequence with color string" do
      Ansi.set_background_color("#ff0000").should eq "\e]11;#ff0000\a"
    end

    it "maps color255 (ExtendedColor) to #eeeeee" do
      color = Ansi::IndexedColor.new(255_u8)
      rgb = Ansi.ansi_to_rgb(color.value)
      hex = Ansi.color_to_hex_string(rgb)
      hex.should eq "#eeeeee"
    end

    it "uses color255 for background" do
      Ansi.set_background_color("#eeeeee").should eq "\e]11;#eeeeee\a"
    end
  end

  describe ".set_cursor_color" do
    it "returns sequence with color string" do
      Ansi.set_cursor_color("#00ff00").should eq "\e]12;#00ff00\a"
    end

    it "uses hex color #ffeeaa for cursor" do
      Ansi.set_cursor_color("#ffeeaa").should eq "\e]12;#ffeeaa\a"
    end
  end

  describe "constants" do
    it "RequestForegroundColor is correct" do
      Ansi::RequestForegroundColor.should eq "\e]10;?\a"
    end

    it "ResetForegroundColor is correct" do
      Ansi::ResetForegroundColor.should eq "\e]110\a"
    end

    it "RequestBackgroundColor is correct" do
      Ansi::RequestBackgroundColor.should eq "\e]11;?\a"
    end

    it "ResetBackgroundColor is correct" do
      Ansi::ResetBackgroundColor.should eq "\e]111\a"
    end

    it "RequestCursorColor is correct" do
      Ansi::RequestCursorColor.should eq "\e]12;?\a"
    end

    it "ResetCursorColor is correct" do
      Ansi::ResetCursorColor.should eq "\e]112\a"
    end
  end

  # Tests for HexColor and other color types
  describe "HexColor type (from Go)" do
    it "implements HexColor with hex() method" do
      hex_color = Ansi::HexColor.new("#ff0000")
      hex_color.hex.should eq "#ff0000"
      hex_color.to_s.should eq "#ff0000"

      # Test RGBA values (red)
      r, g, b, a = hex_color.rgba
      (r >> 8).should eq 255_u32
      (g >> 8).should eq 0_u32
      (b >> 8).should eq 0_u32
      a.should eq 0xFFFF_u32

      # Test 3-digit hex
      hex_color3 = Ansi::HexColor.new("#f00")
      hex_color3.hex.should eq "#ff0000"

      # Test without #
      hex_color4 = Ansi::HexColor.new("00ff00")
      hex_color4.hex.should eq "#00ff00"

      # Test invalid hex returns empty string and 0 RGBA
      invalid = Ansi::HexColor.new("not a color")
      invalid.hex.should eq ""
      r2, g2, b2, a2 = invalid.rgba
      r2.should eq 0_u32
      g2.should eq 0_u32
      b2.should eq 0_u32
      a2.should eq 0_u32
    end
  end

  describe "BasicColor constants (from Go)" do
    it "maps BrightMagenta to #ff00ff" do
      color = Ansi::BasicColor::BrightMagenta
      rgb = Ansi.ansi_to_rgb(color.value)
      hex = Ansi.color_to_hex_string(rgb)
      hex.should eq "#ff00ff"
    end
  end
end
