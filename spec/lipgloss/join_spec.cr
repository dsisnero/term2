require "../spec_helper"

describe "Lipgloss parity: Join" do
  it "joins vertically with position" do
    Term2.join_vertical(Term2::Position::Left, "A", "BBBB").should eq("A   \nBBBB")
    Term2.join_vertical(Term2::Position::Right, "A", "BBBB").should eq("   A\nBBBB")
    Term2.join_vertical(0.25, "A", "BBBB").should eq(" A  \nBBBB")
  end

  it "joins horizontally with position" do
    Term2.join_horizontal(Term2::Position::Top, "A", "B\nB\nB\nB").should eq("AB\n B\n B\n B")
    Term2.join_horizontal(Term2::Position::Bottom, "A", "B\nB\nB\nB").should eq(" B\n B\n B\nAB")
    Term2.join_horizontal(0.25, "A", "B\nB\nB\nB").should eq(" B\nAB\n B\n B")
  end
end
