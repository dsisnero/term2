require "./spec_helper"

describe "Lipgloss parity: place whitespace options" do
  it "supports custom whitespace chars for horizontal placement" do
    content = "X\nYY"
    rendered = Lipgloss.place_horizontal(8, Lipgloss::Position::Left, content, Lipgloss.with_whitespace_chars(".-"))

    rendered.should eq("X.-.-.-.\nYY.-.-.-")
  end

  it "supports custom whitespace chars for vertical placement" do
    rendered = Lipgloss.place_vertical(4, Lipgloss::Position::Bottom, "AB", Lipgloss.with_whitespace_chars("+-"))
    rendered.should eq("+-\n+-\n+-\nAB")
  end

  it "supports whitespace style in placement" do
    style = Lipgloss::Style.new.bold(true)
    rendered = Lipgloss.place_horizontal(
      5,
      Lipgloss::Position::Right,
      "A",
      Lipgloss.with_whitespace_style(style)
    )

    Lipgloss::Text.strip_ansi(rendered).should eq("    A")
    rendered.includes?("\e[1m").should be_true
  end
end
