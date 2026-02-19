require "./spec_helper"

describe "Ansi palette" do
  describe ".set_palette" do
    it "returns empty string for invalid index" do
      color = Ansi::Color.new(255_u8, 0_u8, 0_u8)
      Ansi.set_palette(-1, color).should eq ""
      Ansi.set_palette(16, color).should eq ""
      Ansi.set_palette(256, color).should eq ""
    end

    it "returns empty string for nil color" do
      Ansi.set_palette(0, nil).should eq ""
    end

    it "generates correct escape sequences for valid colors" do
      # Test cases from Go's TestSetPalette
      cases = [
        {0, Ansi::Color.new(255_u8, 0_u8, 0_u8), "\e]P0ff0000\a"},
        {1, Ansi::Color.new(0_u8, 255_u8, 0_u8), "\e]P100ff00\a"},
        {2, Ansi::Color.new(0_u8, 0_u8, 255_u8), "\e]P20000ff\a"},
        {3, Ansi::Color.new(255_u8, 255_u8, 0_u8), "\e]P3ffff00\a"},
        {4, Ansi::Color.new(255_u8, 0_u8, 255_u8), "\e]P4ff00ff\a"},
        {5, Ansi::Color.new(0_u8, 255_u8, 255_u8), "\e]P500ffff\a"},
        {6, Ansi::Color.new(192_u8, 192_u8, 192_u8), "\e]P6c0c0c0\a"},
        {7, Ansi::Color.new(128_u8, 128_u8, 128_u8), "\e]P7808080\a"},
        {8, Ansi::Color.new(255_u8, 128_u8, 128_u8), "\e]P8ff8080\a"},
        {9, Ansi::Color.new(128_u8, 255_u8, 128_u8), "\e]P980ff80\a"},
        {10, Ansi::Color.new(128_u8, 128_u8, 255_u8), "\e]Pa8080ff\a"},
        {11, Ansi::Color.new(255_u8, 255_u8, 128_u8), "\e]Pbffff80\a"},
        {12, Ansi::Color.new(255_u8, 128_u8, 255_u8), "\e]Pcff80ff\a"},
        {13, Ansi::Color.new(128_u8, 255_u8, 255_u8), "\e]Pd80ffff\a"},
        {14, Ansi::Color.new(192_u8, 192_u8, 192_u8), "\e]Pec0c0c0\a"},
        {15, Ansi::Color.new(0_u8, 0_u8, 0_u8), "\e]Pf000000\a"},
      ]

      cases.each do |index, color, expected|
        Ansi.set_palette(index, color).should eq expected
      end
    end
  end

  describe "ResetPalette" do
    it "is a constant string" do
      Ansi::ResetPalette.should eq "\e]R\a"
    end
  end
end
