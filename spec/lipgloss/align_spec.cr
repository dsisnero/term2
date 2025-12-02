require "../spec_helper"

# Expose helper for testing private align method
class Term2::Style
  def spec_align_text_vertical(str : String, pos : Term2::Position, height : Int32) : String
    align_text_vertical(str, pos, height)
  end
end

describe "Lipgloss parity: align text vertical" do
  it "matches lipgloss align behavior" do
    tests = [
      {str: "Foo", pos: Term2::Position::Top, height: 2, want: "Foo\n"},
      {str: "Foo", pos: Term2::Position::Center, height: 5, want: "\n\nFoo\n\n"},
      {str: "Foo", pos: Term2::Position::Bottom, height: 5, want: "\n\n\n\nFoo"},
      {str: "Foo\nBar", pos: Term2::Position::Bottom, height: 5, want: "\n\n\nFoo\nBar"},
      {str: "Foo\nBar", pos: Term2::Position::Center, height: 5, want: "\nFoo\nBar\n\n"},
      {str: "Foo\nBar", pos: Term2::Position::Top, height: 5, want: "Foo\nBar\n\n\n"},
      {str: "Foo\nBar\nBaz", pos: Term2::Position::Bottom, height: 5, want: "\n\nFoo\nBar\nBaz"},
      {str: "Foo\nBar\nBaz", pos: Term2::Position::Center, height: 5, want: "\nFoo\nBar\nBaz\n"},
      {str: "Foo\nBar\nBaz", pos: Term2::Position::Bottom, height: 3, want: "Foo\nBar\nBaz"},
      {str: "Foo\nBar\nBaz", pos: Term2::Position::Center, height: 3, want: "Foo\nBar\nBaz"},
      {str: "Foo\nBar\nBaz", pos: Term2::Position::Top, height: 3, want: "Foo\nBar\nBaz"},
      {str: "Foo\n\n\n\nBar", pos: Term2::Position::Bottom, height: 5, want: "Foo\n\n\n\nBar"},
      {str: "Foo\n\n\n\nBar", pos: Term2::Position::Center, height: 5, want: "Foo\n\n\n\nBar"},
      {str: "Foo\n\n\n\nBar", pos: Term2::Position::Top, height: 5, want: "Foo\n\n\n\nBar"},
      {str: "Foo\nBar\nBaz", pos: Term2::Position::Center, height: 9, want: "\n\n\nFoo\nBar\nBaz\n\n\n"},
      {str: "Foo\nBar\nBaz", pos: Term2::Position::Center, height: 10, want: "\n\n\nFoo\nBar\nBaz\n\n\n\n"},
    ]

    tests.each do |t|
      Term2::Style.new.spec_align_text_vertical(t[:str], t[:pos], t[:height]).should eq(t[:want])
    end
  end
end