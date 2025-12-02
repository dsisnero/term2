require "../spec_helper"

describe "Lipgloss parity: style rendering" do
  it "renders underline with and without spaces" do
    renderer = Term2::StyleRenderer.new
    renderer.color_profile = Term2::ColorProfile::TrueColor
    renderer.has_dark_background = true
    cases = [
      {style: -> { Term2::Style.new.renderer(renderer).underline(true) }, expected: "\e[4;4ma\e[0m\e[4;4mb\e[0m\e[4m \e[0m\e[4;4mc\e[0m"},
      {style: -> { Term2::Style.new.renderer(renderer).underline(true).underline_spaces(true) }, expected: "\e[4;4ma\e[0m\e[4;4mb\e[0m\e[4m \e[0m\e[4;4mc\e[0m"},
      {style: -> { Term2::Style.new.renderer(renderer).underline(true).underline_spaces(false) }, expected: "\e[4;4ma\e[0m\e[4;4mb\e[0m \e[4;4mc\e[0m"},
      {style: -> { Term2::Style.new.renderer(renderer).underline_spaces(true) }, expected: "ab\e[4m \e[0mc"},
    ]

    cases.each_with_index do |tc, idx|
      s = tc[:style].call.set_string("ab c")
      s.render.should eq(tc[:expected]), "case #{idx} failed"
    end
  end

  it "renders strikethrough with and without spaces" do
    renderer = Term2::StyleRenderer.new
    renderer.color_profile = Term2::ColorProfile::TrueColor
    renderer.has_dark_background = true
    cases = [
      {style: -> { Term2::Style.new.renderer(renderer).strikethrough(true) }, expected: "\e[9ma\e[0m\e[9mb\e[0m\e[9m \e[0m\e[9mc\e[0m"},
      {style: -> { Term2::Style.new.renderer(renderer).strikethrough(true).strikethrough_spaces(true) }, expected: "\e[9ma\e[0m\e[9mb\e[0m\e[9m \e[0m\e[9mc\e[0m"},
      {style: -> { Term2::Style.new.renderer(renderer).strikethrough(true).strikethrough_spaces(false) }, expected: "\e[9ma\e[0m\e[9mb\e[0m \e[9mc\e[0m"},
      {style: -> { Term2::Style.new.renderer(renderer).strikethrough_spaces(true) }, expected: "ab\e[9m \e[0mc"},
    ]

    cases.each_with_index do |tc, idx|
      s = tc[:style].call.set_string("ab c")
      s.render.should eq(tc[:expected]), "case #{idx} failed"
    end
  end
end