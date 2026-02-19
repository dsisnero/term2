require "./spec_helper"

describe "Lipgloss parity: Size" do
  it "computes width for simple single-line strings" do
    Lipgloss.width("ab").should eq(2)
    Lipgloss.width("abcdef").should eq(6)
    Lipgloss.width("abcdefghij").should eq(10)
  end

  it "computes width for multiline strings" do
    Lipgloss.width("Line 1\nLine 2").should eq(6)
    Lipgloss.width("Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8\nLine 9\nLine 10").should eq(7)
    Lipgloss.width(("Line\n" * 49) + "Line").should eq(4)
  end
end
