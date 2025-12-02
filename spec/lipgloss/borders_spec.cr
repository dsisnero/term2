require "../spec_helper"

describe "Lipgloss parity: borders" do
  it "computes border sizes" do
    tests = [
      {name: "default", style: Term2::Style.new, want_x: 0, want_y: 0},
      {name: "border normal", style: Term2::Style.new.border(Term2::Border.normal), want_x: 2, want_y: 2},
      {name: "border normal true", style: Term2::Style.new.border(Term2::Border.normal, true), want_x: 2, want_y: 2},
      {name: "border normal true false", style: Term2::Style.new.border(Term2::Border.normal, true, false), want_x: 0, want_y: 2},
      {name: "border normal true true false", style: Term2::Style.new.border(Term2::Border.normal, true, true, false), want_x: 2, want_y: 1},
      {name: "border normal true true false false", style: Term2::Style.new.border(Term2::Border.normal, true, true, false, false), want_x: 1, want_y: 1},
      {name: "border top only", style: Term2::Style.new.border_top(true).border_style(Term2::Border.normal), want_x: 0, want_y: 1},
      {name: "border style normal implicit", style: Term2::Style.new.border_style(Term2::Border.normal), want_x: 2, want_y: 2},
      {name: "custom border", style: Term2::Style.new.border_style(Term2::Border.new(left: "123456789")), want_x: 1, want_y: 0},
    ]

    tests.each do |t|
      x = t[:style].get_horizontal_border_size
      y = t[:style].get_vertical_border_size
      {x, y}.should eq({t[:want_x], t[:want_y]}), t[:name]
      {t[:style].get_horizontal_frame_size, t[:style].get_vertical_frame_size}.should eq({t[:want_x], t[:want_y]})
      t[:style].get_frame_size.should eq({t[:want_x], t[:want_y]})
    end
  end

  it "gets first rune" do
    cases = {
      ""        => "",
      "A"       => "A",
      "世"       => "世",
      "Hello"   => "H",
      "你好世界"    => "你",
      "Hello世界" => "H",
      "世界Hello" => "世",
      "😀Happy"  => "😀",
      "ñoño"    => "ñ",
    }
    cases.each do |input, expect|
      Term2.get_first_rune_as_string(input).should eq(expect)
    end
  end
end