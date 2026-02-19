require "./spec_helper"

private def rgba_tuple(color : Lipgloss::RGBAColor) : {UInt8, UInt8, UInt8, UInt8}
  {color.r, color.g, color.b, color.a}
end

describe "Lipgloss parity: Blending" do
  it "blends 1d gradients with go-compatible output" do
    red = Lipgloss::RGBAColor.new(255_u8, 0_u8, 0_u8, 255_u8)
    blue = Lipgloss::RGBAColor.new(0_u8, 0_u8, 255_u8, 255_u8)
    green = Lipgloss::RGBAColor.new(0_u8, 255_u8, 0_u8, 255_u8)

    blended = Lipgloss.blend1d(10, red, blue)
    blended.should_not be_nil
    values = blended.as(Array(Lipgloss::RGBAColor)).map { |color_value| rgba_tuple(color_value) }
    values.should eq([
      {255_u8, 0_u8, 0_u8, 255_u8},
      {246_u8, 0_u8, 45_u8, 255_u8},
      {235_u8, 0_u8, 73_u8, 255_u8},
      {223_u8, 0_u8, 99_u8, 255_u8},
      {210_u8, 0_u8, 124_u8, 255_u8},
      {193_u8, 0_u8, 149_u8, 255_u8},
      {173_u8, 0_u8, 175_u8, 255_u8},
      {147_u8, 0_u8, 201_u8, 255_u8},
      {109_u8, 0_u8, 228_u8, 255_u8},
      {0_u8, 0_u8, 255_u8, 255_u8},
    ])

    Lipgloss.blend1d(4, red, green, blue).as(Array(Lipgloss::RGBAColor)).map { |color_value| rgba_tuple(color_value) }.should eq([
      {255_u8, 0_u8, 0_u8, 255_u8},
      {0_u8, 255_u8, 0_u8, 255_u8},
      {0_u8, 255_u8, 0_u8, 255_u8},
      {0_u8, 0_u8, 255_u8, 255_u8},
    ])

    Lipgloss.blend1d(0).should eq([] of Lipgloss::RGBAColor)
    Lipgloss.blend1d(0, red).should eq([] of Lipgloss::RGBAColor)
    Lipgloss.blend1d(3, red).as(Array(Lipgloss::RGBAColor)).map { |color_value| rgba_tuple(color_value) }.should eq([
      {255_u8, 0_u8, 0_u8, 255_u8},
      {255_u8, 0_u8, 0_u8, 255_u8},
      {255_u8, 0_u8, 0_u8, 255_u8},
    ])
  end

  it "blends 2d gradients with go-compatible shape/edge behavior" do
    red = Lipgloss::RGBAColor.new(255_u8, 0_u8, 0_u8, 255_u8)
    blue = Lipgloss::RGBAColor.new(0_u8, 0_u8, 255_u8, 255_u8)
    green = Lipgloss::RGBAColor.new(0_u8, 255_u8, 0_u8, 255_u8)

    Lipgloss.blend2d(2, 2, 0.0, red, blue).as(Array(Lipgloss::RGBAColor)).size.should eq(4)
    Lipgloss.blend2d(3, 2, 90.0, red, blue).as(Array(Lipgloss::RGBAColor)).size.should eq(6)
    Lipgloss.blend2d(2, 3, 180.0, red, blue).as(Array(Lipgloss::RGBAColor)).size.should eq(6)
    Lipgloss.blend2d(2, 2, 270.0, red, blue).as(Array(Lipgloss::RGBAColor)).size.should eq(4)
    Lipgloss.blend2d(2, 2, 450.0, red, blue).as(Array(Lipgloss::RGBAColor)).size.should eq(4)
    Lipgloss.blend2d(2, 2, -90.0, red, blue).as(Array(Lipgloss::RGBAColor)).size.should eq(4)

    Lipgloss.blend2d(1, 1, 0.0, red).as(Array(Lipgloss::RGBAColor)).map { |color_value| rgba_tuple(color_value) }.should eq([
      {255_u8, 0_u8, 0_u8, 255_u8},
    ])

    Lipgloss.blend2d(0, -1, 0.0, red).as(Array(Lipgloss::RGBAColor)).size.should eq(1)
    Lipgloss.blend2d(2, 2, 0.0).should be_nil
    Lipgloss.blend2d(2, 2, 0.0, nil, nil).should be_nil

    with_nil = Lipgloss.blend2d(2, 2, 0.0, red, nil, blue)
    with_nil.should_not be_nil
    with_nil.as(Array(Lipgloss::RGBAColor)).size.should eq(4)

    three_colors = Lipgloss.blend2d(2, 2, 0.0, red, green, blue)
    three_colors.should_not be_nil
    three_colors.as(Array(Lipgloss::RGBAColor)).size.should eq(4)
  end
end
