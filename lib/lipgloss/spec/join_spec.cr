require "./spec_helper"

describe "Lipgloss parity: Join" do
  it "joins vertically with position" do
    Lipgloss.join_vertical(Lipgloss::Position::Left, "A", "BBBB").should eq("A   \nBBBB")
    Lipgloss.join_vertical(Lipgloss::Position::Right, "A", "BBBB").should eq("   A\nBBBB")
    Lipgloss.join_vertical(0.25, "A", "BBBB").should eq(" A  \nBBBB")
  end

  it "joins horizontally with position" do
    Lipgloss.join_horizontal(Lipgloss::Position::Top, "A", "B\nB\nB\nB").should eq("AB\n B\n B\n B")
    Lipgloss.join_horizontal(Lipgloss::Position::Bottom, "A", "B\nB\nB\nB").should eq(" B\n B\n B\nAB")
    Lipgloss.join_horizontal(0.25, "A", "B\nB\nB\nB").should eq(" B\nAB\n B\n B")
  end
end
