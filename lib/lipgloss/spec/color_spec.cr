require "./spec_helper"

private def rgb_tuple(color : Lipgloss::Color | Lipgloss::RGBAColor) : {Int32, Int32, Int32}
  case color
  when Lipgloss::Color
    color.to_rgb
  else
    {color.r.to_i, color.g.to_i, color.b.to_i}
  end
end

private def require_rgba(value : Lipgloss::RGBAColor?, label : String) : Lipgloss::RGBAColor
  value.should_not be_nil, label
  value.as(Lipgloss::RGBAColor)
end

describe "Lipgloss parity: color profiles" do
  it "renders foreground colors according to profile" do
    renderer = Lipgloss::StyleRenderer.new
    input = "hello"
    color = Lipgloss::Color.from_hex("#5A56E0")

    cases = {
      Lipgloss::ColorProfile::ASCII     => "hello",
      Lipgloss::ColorProfile::ANSI      => "\e[94mhello\e[0m",
      Lipgloss::ColorProfile::ANSI256   => "\e[38;5;62mhello\e[0m",
      Lipgloss::ColorProfile::TrueColor => "\e[38;2;90;86;224mhello\e[0m",
    }

    cases.each do |profile, expected|
      renderer.color_profile = profile
      style = Lipgloss::Style.new.renderer(renderer).foreground(color).string = input
      style.render.should eq(expected)
    end
  end
end

describe "Lipgloss parity: color utilities" do
  it "parses hex with go-compatible rules" do
    red_hex = require_rgba(Lipgloss.parse_hex?("#FF0000"), "expected #FF0000 to parse")
    {red_hex.r, red_hex.g, red_hex.b, red_hex.a}.should eq({255_u8, 0_u8, 0_u8, 255_u8})

    green_hex = require_rgba(Lipgloss.parse_hex?("#0F0"), "expected #0F0 to parse")
    {green_hex.r, green_hex.g, green_hex.b, green_hex.a}.should eq({0_u8, 255_u8, 0_u8, 255_u8})

    lowercase_red = require_rgba(Lipgloss.parse_hex?("#ff0000"), "expected lowercase hex to parse")
    {lowercase_red.r, lowercase_red.g, lowercase_red.b, lowercase_red.a}.should eq({255_u8, 0_u8, 0_u8, 255_u8})

    Lipgloss.parse_hex?("FF0000").should be_nil
    Lipgloss.parse_hex?("").should be_nil
    Lipgloss.parse_hex?("#").should be_nil
    Lipgloss.parse_hex?("#F0").should be_nil
    Lipgloss.parse_hex?("#FF00000").should be_nil
    Lipgloss.parse_hex?("#FG0000").should be_nil
  end

  it "maps color string specs like go Color()" do
    rgb_tuple(Lipgloss.color("#FF0000").as(Lipgloss::Color)).should eq({255, 0, 0})
    rgb_tuple(Lipgloss.color("9").as(Lipgloss::Color)).should eq({255, 0, 0})
    rgb_tuple(Lipgloss.color("21").as(Lipgloss::Color)).should eq({0, 0, 255})
    rgb_tuple(Lipgloss.color("16711680").as(Lipgloss::Color)).should eq({255, 0, 0})
    Lipgloss.color("invalid color").should be_a(Lipgloss::NoColor)
  end

  it "applies alpha with clamping" do
    require_rgba(Lipgloss.alpha(Lipgloss::RGBAColor.new(255_u8, 0_u8, 0_u8, 255_u8), 1.0), "alpha(1.0)").a.should eq(255_u8)
    require_rgba(Lipgloss.alpha(Lipgloss::RGBAColor.new(0_u8, 255_u8, 0_u8, 255_u8), 0.5), "alpha(0.5)").a.should eq(127_u8)
    require_rgba(Lipgloss.alpha(Lipgloss::RGBAColor.new(0_u8, 0_u8, 255_u8, 255_u8), 0.25), "alpha(0.25)").a.should eq(63_u8)
    require_rgba(Lipgloss.alpha(Lipgloss::RGBAColor.new(255_u8, 0_u8, 255_u8, 255_u8), 1.5), "alpha(1.5)").a.should eq(255_u8)
    require_rgba(Lipgloss.alpha(Lipgloss::RGBAColor.new(255_u8, 255_u8, 0_u8, 255_u8), -0.5), "alpha(-0.5)").a.should eq(0_u8)
    Lipgloss.alpha(nil, 0.5).should be_nil
  end

  it "computes complementary colors" do
    rgb_tuple(require_rgba(Lipgloss.complementary(Lipgloss::Color.from_hex("#FF0000")), "complementary red")).should eq({0, 255, 255})
    rgb_tuple(require_rgba(Lipgloss.complementary(Lipgloss::Color.from_hex("#00FF00")), "complementary green")).should eq({255, 0, 255})
    rgb_tuple(require_rgba(Lipgloss.complementary(Lipgloss::Color.from_hex("#0000FF")), "complementary blue")).should eq({255, 255, 0})
    rgb_tuple(require_rgba(Lipgloss.complementary(Lipgloss::Color.from_hex("#000000")), "complementary black")).should eq({0, 0, 0})
    rgb_tuple(require_rgba(Lipgloss.complementary(Lipgloss::Color.from_hex("#FFFFFF")), "complementary white")).should eq({255, 255, 255})
    Lipgloss.complementary(nil).should be_nil
  end

  it "darkens colors with go-compatible clamping" do
    rgb_tuple(require_rgba(Lipgloss.darken(Lipgloss::Color.from_hex("#FFFFFF"), 0.5), "darken white 50%")).should eq({127, 127, 127})
    rgb_tuple(require_rgba(Lipgloss.darken(Lipgloss::Color.from_hex("#FF0000"), 0.25), "darken red 25%")).should eq({191, 0, 0})
    rgb_tuple(require_rgba(Lipgloss.darken(Lipgloss::Color.from_hex("#0000FF"), 0.75), "darken blue 75%")).should eq({0, 0, 63})
    rgb_tuple(require_rgba(Lipgloss.darken(Lipgloss::Color.from_hex("#FFFFFF"), 0.0), "darken clamp min")).should eq({255, 255, 255})
    rgb_tuple(require_rgba(Lipgloss.darken(Lipgloss::Color.from_hex("#FFFFFF"), 1.0), "darken clamp max")).should eq({0, 0, 0})
    Lipgloss.darken(nil, 0.5).should be_nil
  end

  it "lightens colors with go-compatible clamping" do
    rgb_tuple(require_rgba(Lipgloss.lighten(Lipgloss::Color.from_hex("#000000"), 0.5), "lighten black 50%")).should eq({127, 127, 127})
    rgb_tuple(require_rgba(Lipgloss.lighten(Lipgloss::Color.from_hex("#800000"), 0.25), "lighten dark red 25%")).should eq({191, 63, 63})
    rgb_tuple(require_rgba(Lipgloss.lighten(Lipgloss::Color.from_hex("#000080"), 0.75), "lighten dark blue 75%")).should eq({191, 191, 255})
    rgb_tuple(require_rgba(Lipgloss.lighten(Lipgloss::Color.from_hex("#000000"), 0.0), "lighten clamp min")).should eq({0, 0, 0})
    rgb_tuple(require_rgba(Lipgloss.lighten(Lipgloss::Color.from_hex("#000000"), 1.0), "lighten clamp max")).should eq({255, 255, 255})
    Lipgloss.lighten(nil, 0.5).should be_nil
  end
end
