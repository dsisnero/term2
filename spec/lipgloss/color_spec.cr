require "../spec_helper"

describe "Lipgloss parity: color profiles" do
  it "renders foreground colors according to profile" do
    renderer = Term2::StyleRenderer.new
    input = "hello"
    color = Term2::Color.from_hex("#5A56E0")

    cases = {
      Term2::ColorProfile::ASCII     => "hello",
      Term2::ColorProfile::ANSI      => "\e[94mhello\e[0m",
      Term2::ColorProfile::ANSI256   => "\e[38;5;62mhello\e[0m",
      Term2::ColorProfile::TrueColor => "\e[38;2;90;86;224mhello\e[0m",
    }

    cases.each do |profile, expected|
      renderer.color_profile = profile
      style = Term2::Style.new.renderer(renderer).foreground(color).set_string(input)
      style.render.should eq(expected)
    end
  end
end
