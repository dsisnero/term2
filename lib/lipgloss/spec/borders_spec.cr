require "./spec_helper"

describe "Lipgloss parity: borders" do
  it "computes border sizes" do
    tests = [
      {name: "default", style: Lipgloss::Style.new, want_x: 0, want_y: 0},
      {name: "border normal", style: Lipgloss::Style.new.border(Lipgloss::Border.normal), want_x: 2, want_y: 2},
      {name: "border normal true", style: Lipgloss::Style.new.border(Lipgloss::Border.normal, true), want_x: 2, want_y: 2},
      {name: "border normal true false", style: Lipgloss::Style.new.border(Lipgloss::Border.normal, true, false), want_x: 0, want_y: 2},
      {name: "border normal true true false", style: Lipgloss::Style.new.border(Lipgloss::Border.normal, true, true, false), want_x: 2, want_y: 1},
      {name: "border normal true true false false", style: Lipgloss::Style.new.border(Lipgloss::Border.normal, true, true, false, false), want_x: 1, want_y: 1},
      {name: "border top only", style: Lipgloss::Style.new.border_top(true).border_style(Lipgloss::Border.normal), want_x: 0, want_y: 1},
      {name: "border style normal implicit", style: Lipgloss::Style.new.border_style(Lipgloss::Border.normal), want_x: 2, want_y: 2},
      {name: "custom border", style: Lipgloss::Style.new.border_style(Lipgloss::Border.new(left: "123456789")), want_x: 1, want_y: 0},
    ]

    tests.each do |test_case|
      x = test_case[:style].horizontal_border_size
      y = test_case[:style].vertical_border_size
      {x, y}.should eq({test_case[:want_x], test_case[:want_y]}), test_case[:name]
      {test_case[:style].horizontal_frame_size, test_case[:style].vertical_frame_size}.should eq({test_case[:want_x], test_case[:want_y]})
      test_case[:style].frame_size.should eq({test_case[:want_x], test_case[:want_y]})
    end
  end

  it "gets first rune" do
    cases = {
      ""                                            => "",
      "A"                                           => "A",
      "世"                                           => "世",
      "Hello"                                       => "H",
      "你好世界"                                        => "你",
      "Hello世界"                                     => "H",
      "世界Hello"                                     => "世",
      "😀Happy"                                      => "😀",
      "ñoño"                                        => "ñ",
      "The quick brown fox jumps over the lazy dog" => "T",
    }
    cases.each do |input, expect|
      Lipgloss.get_first_rune_as_string(input).should eq(expect)
    end
  end
end
