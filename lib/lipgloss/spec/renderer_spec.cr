require "./spec_helper"

describe "Lipgloss parity: renderer" do
  it "toggles dark background" do
    r1 = Lipgloss.new_renderer(IO::Memory.new)
    r1.has_dark_background = false
    r1.has_dark_background?.should be_false
    r2 = Lipgloss.new_renderer(IO::Memory.new)
    r2.has_dark_background = true
    r2.has_dark_background?.should be_true
  end

  it "sets color profile" do
    r = Lipgloss.new_renderer(IO::Memory.new)
    r.color_profile = Lipgloss::ColorProfile::TrueColor
    r.color_profile.should eq(Lipgloss::ColorProfile::TrueColor)
  end
end
