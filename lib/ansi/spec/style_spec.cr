require "./spec_helper"

describe Ansi::Style do
  describe "initialize" do
    it "returns reset sequence for empty style" do
      style = Ansi::Style.new([] of Ansi::Attr)
      style.to_s.should eq "\e[m"
    end
  end

  # Port of Go TestReset
  describe "reset" do
    it "returns reset sequence for default style" do
      style = Ansi::Style.new([] of Ansi::Attr)
      style.to_s.should eq "\e[m"
    end
  end

  # Port of Go TestBold
  describe "bold" do
    it "returns bold sequence" do
      style = Ansi::Style.new([] of Ansi::Attr)
      style = style.bold
      style.to_s.should eq "\e[1m"
    end
  end

  # Port of Go TestDefaultBackground
  describe "default_background" do
    it "returns default background sequence" do
      style = Ansi::Style.new([] of Ansi::Attr)
      style = style.default_background_color
      style.to_s.should eq "\e[49m"
    end
  end

  # Port of Go TestSequence
  describe "sequence" do
    it "returns combined sequence" do
      style = Ansi::Style.new([] of Ansi::Attr)
      style = style.bold.underline(true).foreground_color(Ansi::IndexedColor.new(255_u8))
      style.to_s.should eq "\e[1;4;38;5;255m"
    end
  end

  # Port of Go TestColorColor
  describe "color_color" do
    it "returns sequence with color" do
      # color.Black in Go is 0,0,0
      black = Ansi::Color.new(0_u8, 0_u8, 0_u8)
      style = Ansi::Style.new([] of Ansi::Attr)
      style = style.bold.underline(true).foreground_color(black)
      style.to_s.should eq "\e[1;4;38;2;0;0;0m"
    end
  end

  # Port of Go TestNilColors
  describe "nil_colors" do
    it "returns default color sequences for nil colors" do
      style = Ansi::Style.new([] of Ansi::Attr)
      style = style.foreground_color(nil).background_color(nil).underline_color(nil)
      style.to_s.should eq "\e[39;49;59m"
    end
  end
end
