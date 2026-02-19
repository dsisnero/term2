require "./spec_helper"

describe "Lipgloss parity: style rendering" do
  it "renders underline with and without spaces" do
    renderer = Lipgloss::StyleRenderer.new
    renderer.color_profile = Lipgloss::ColorProfile::TrueColor
    renderer.has_dark_background = true
    cases = [
      {style: -> { Lipgloss::Style.new.renderer(renderer).underline(true) }, expected: "\e[4;4ma\e[0m\e[4;4mb\e[0m\e[4m \e[0m\e[4;4mc\e[0m"},
      {style: -> { Lipgloss::Style.new.renderer(renderer).underline(true).underline_spaces(true) }, expected: "\e[4;4ma\e[0m\e[4;4mb\e[0m\e[4m \e[0m\e[4;4mc\e[0m"},
      {style: -> { Lipgloss::Style.new.renderer(renderer).underline(true).underline_spaces(false) }, expected: "\e[4;4ma\e[0m\e[4;4mb\e[0m \e[4;4mc\e[0m"},
      {style: -> { Lipgloss::Style.new.renderer(renderer).underline_spaces(true) }, expected: "ab\e[4m \e[0mc"},
      {style: -> { Lipgloss::Style.new.renderer(renderer).underline(true).underline_style(Lipgloss::UnderlineStyle::Curly) }, expected: "\e[4;4:3ma\e[0m\e[4;4:3mb\e[0m\e[4m \e[0m\e[4;4:3mc\e[0m"},
    ]

    cases.each_with_index do |test_case, index|
      s = test_case[:style].call
      s.string = "ab c"
      s.render.should eq(test_case[:expected]), "case #{index} failed"
    end
  end

  it "renders strikethrough with and without spaces" do
    renderer = Lipgloss::StyleRenderer.new
    renderer.color_profile = Lipgloss::ColorProfile::TrueColor
    renderer.has_dark_background = true
    cases = [
      {style: -> { Lipgloss::Style.new.renderer(renderer).strikethrough(true) }, expected: "\e[9ma\e[0m\e[9mb\e[0m\e[9m \e[0m\e[9mc\e[0m"},
      {style: -> { Lipgloss::Style.new.renderer(renderer).strikethrough(true).strikethrough_spaces(true) }, expected: "\e[9ma\e[0m\e[9mb\e[0m\e[9m \e[0m\e[9mc\e[0m"},
      {style: -> { Lipgloss::Style.new.renderer(renderer).strikethrough(true).strikethrough_spaces(false) }, expected: "\e[9ma\e[0m\e[9mb\e[0m \e[9mc\e[0m"},
      {style: -> { Lipgloss::Style.new.renderer(renderer).strikethrough_spaces(true) }, expected: "ab\e[9m \e[0mc"},
    ]

    cases.each_with_index do |test_case, index|
      s = test_case[:style].call
      s.string = "ab c"
      s.render.should eq(test_case[:expected]), "case #{index} failed"
    end
  end

  it "renders simple styled text variants" do
    cases = [
      {style: Lipgloss::Style.new.foreground("#5A56E0"), expected: "\e[38;2;90;86;224mhello\e[0m"},
      {style: Lipgloss::Style.new.bold(true), expected: "\e[1mhello\e[0m"},
      {style: Lipgloss::Style.new.italic(true), expected: "\e[3mhello\e[0m"},
      {style: Lipgloss::Style.new.underline(true), expected: "\e[4;4mh\e[0m\e[4;4me\e[0m\e[4;4ml\e[0m\e[4;4ml\e[0m\e[4;4mo\e[0m"},
      {style: Lipgloss::Style.new.blink(true), expected: "\e[5mhello\e[0m"},
      {style: Lipgloss::Style.new.faint(true), expected: "\e[2mhello\e[0m"},
    ]

    cases.each_with_index do |test_case, case_index|
      test_style = test_case[:style]
      test_style.string = "hello"
      test_style.render.should eq(test_case[:expected]), "case #{case_index} failed"
    end
  end

  it "inherits style attributes but not spacing/frame values" do
    source = Lipgloss::Style.new
      .bold(true)
      .italic(true)
      .underline(true)
      .strikethrough(true)
      .blink(true)
      .faint(true)
      .foreground("#ffffff")
      .background("#111111")
      .margin(1, 1, 1, 1)
      .padding(1, 1, 1, 1)

    inherited = Lipgloss::Style.new.inherit(source)

    inherited.bold?.should eq(source.bold?)
    inherited.italic?.should eq(source.italic?)
    inherited.underline?.should eq(source.underline?)
    inherited.strikethrough?.should eq(source.strikethrough?)
    inherited.blink?.should eq(source.blink?)
    inherited.faint?.should eq(source.faint?)
    inherited.foreground_color.should eq(source.foreground_color)
    inherited.background_color.should eq(source.background_color)

    inherited.margin_left.should_not eq(source.margin_left)
    inherited.margin_right.should_not eq(source.margin_right)
    inherited.margin_top.should_not eq(source.margin_top)
    inherited.margin_bottom.should_not eq(source.margin_bottom)
    inherited.padding_left.should_not eq(source.padding_left)
    inherited.padding_right.should_not eq(source.padding_right)
    inherited.padding_top.should_not eq(source.padding_top)
    inherited.padding_bottom.should_not eq(source.padding_bottom)
  end

  it "copies style values via copy" do
    source = Lipgloss::Style.new
      .bold(true)
      .italic(true)
      .underline(true)
      .strikethrough(true)
      .blink(true)
      .faint(true)
      .foreground("#ffffff")
      .background("#111111")
      .margin(1, 1, 1, 1)
      .padding(1, 1, 1, 1)
      .tab_width(2)

    copied = source.copy

    copied.bold?.should eq(source.bold?)
    copied.italic?.should eq(source.italic?)
    copied.underline?.should eq(source.underline?)
    copied.strikethrough?.should eq(source.strikethrough?)
    copied.blink?.should eq(source.blink?)
    copied.faint?.should eq(source.faint?)
    copied.foreground_color.should eq(source.foreground_color)
    copied.background_color.should eq(source.background_color)
    copied.margin_left.should eq(source.margin_left)
    copied.margin_right.should eq(source.margin_right)
    copied.margin_top.should eq(source.margin_top)
    copied.margin_bottom.should eq(source.margin_bottom)
    copied.padding_left.should eq(source.padding_left)
    copied.padding_right.should eq(source.padding_right)
    copied.padding_top.should eq(source.padding_top)
    copied.padding_bottom.should eq(source.padding_bottom)
    copied.tab_width.should eq(source.tab_width)
  end

  it "matches value-copy assignment semantics" do
    style = Lipgloss::Style.new.bold(true)
    copy = style
    copy.bold(false)

    style.bold?.should be_true
    copy.bold?.should be_false
  end

  it "unsets style properties" do
    style = Lipgloss::Style.new.bold(true)
    style.bold?.should be_true
    style = style.unset_bold
    style.bold?.should be_false

    style = Lipgloss::Style.new.italic(true)
    style.italic?.should be_true
    style = style.unset_italic
    style.italic?.should be_false

    style = Lipgloss::Style.new.underline(true)
    style.underline?.should be_true
    style = style.unset_underline
    style.underline?.should be_false

    style = Lipgloss::Style.new.strikethrough(true)
    style.strikethrough?.should be_true
    style = style.unset_strikethrough
    style.strikethrough?.should be_false

    style = Lipgloss::Style.new.blink(true)
    style.blink?.should be_true
    style = style.unset_blink
    style.blink?.should be_false

    style = Lipgloss::Style.new.faint(true)
    style.faint?.should be_true
    style = style.unset_faint
    style.faint?.should be_false

    style = Lipgloss::Style.new.margin(1, 2, 3, 4)
    style.unset_margin_top.margin_top.should eq(0)
    style.unset_margin_right.margin_right.should eq(0)
    style.unset_margin_bottom.margin_bottom.should eq(0)
    style.unset_margin_left.margin_left.should eq(0)

    style = Lipgloss::Style.new.padding(1, 2, 3, 4)
    style.unset_padding_top.padding_top.should eq(0)
    style.unset_padding_right.padding_right.should eq(0)
    style.unset_padding_bottom.padding_bottom.should eq(0)
    style.unset_padding_left.padding_left.should eq(0)
  end

  it "supports string value rendering and transforms" do
    Lipgloss::Style.new.render("foo").should eq("foo")
    style_with_string = Lipgloss::Style.new
    style_with_string.string = "bar"
    style_with_string.render("foo").should eq("bar foo")

    bold_with_string = Lipgloss::Style.new.bold(true)
    bold_with_string.string = "bar"
    bold_with_string.render("foo").should eq("\e[1mbar foo\e[0m")

    multi_string = Lipgloss::Style.new
    multi_string.string = "bar foobar"
    multi_string.render("foo").should eq("bar foobar foo")
    Lipgloss::Style.new.margin_right(1).render("foo").should eq("foo ")
    Lipgloss::Style.new.margin_left(1).render("foo").should eq(" foo")
    Lipgloss::Style.new.margin_right(1).render("").should eq(" ")
    Lipgloss::Style.new.margin_left(1).render("").should eq(" ")

    reverse = ->(input : String) {
      chars = input.chars
      chars.reverse.join
    }
    transformed = Lipgloss::Style.new.bold(true).transform(reverse)
    transformed.render("The quick brown 狐 jumped over the lazy 犬").should eq("\e[1m犬 yzal eht revo depmuj 狐 nworb kciuq ehT\e[0m")
  end

  it "converts tabs according to tab width" do
    Lipgloss::Style.new.render("[\t]").should eq("[    ]")
    Lipgloss::Style.new.tab_width(2).render("[\t]").should eq("[  ]")
    Lipgloss::Style.new.tab_width(0).render("[\t]").should eq("[]")
    Lipgloss::Style.new.tab_width(-1).render("[\t]").should eq("[\t]")
  end

  it "supports custom padding characters" do
    Lipgloss::Style.new.padding(0, 3).padding_char('x').render("TEST").should eq("xxxTESTxxx")
  end

  it "supports hyperlink and unset_hyperlink" do
    renderer = Lipgloss::StyleRenderer.new
    renderer.color_profile = Lipgloss::ColorProfile::ANSI256
    renderer.has_dark_background = true

    basic = Lipgloss::Style.new.renderer(renderer).hyperlink("https://example.com")
    basic.string = "https://example.com"
    basic.render.should eq("\e]8;;https://example.com\ahttps://example.com\e]8;;\a")

    with_params = Lipgloss::Style.new.renderer(renderer).hyperlink("https://example.com", "id=123")
    with_params.string = "example"
    with_params.render.should eq("\e]8;id=123;https://example.com\aexample\e]8;;\a")

    styled_link = Lipgloss::Style.new.renderer(renderer).hyperlink("https://example.com", "id=123").bold(true).foreground(Lipgloss::Color.indexed(234))
    styled_link.string = "example"
    styled_link.render.should eq("\e]8;id=123;https://example.com\a\e[1;38;5;234mexample\e[0m\e]8;;\a")

    style = Lipgloss::Style.new.renderer(renderer).hyperlink("https://example.com", "id=123").bold(true).foreground(Lipgloss::Color.indexed(234))
    style.string = "example"
    style = style.unset_hyperlink
    style.render.should eq("\e[1;38;5;234mexample\e[0m")
  end

  it "renders carriage return input equivalently to normalized newlines" do
    style = Lipgloss::Style.new.margin_left(1)
    with_crlf = "Super duper california oranges\r\nHello world\r\n"
    normalized = "Super duper california oranges\nHello world\n"
    style.render(with_crlf).should eq(style.render(normalized))
  end

  it "maintains requested content width and height when frame is accounted for" do
    content = "The Romans learned from the Greeks that quinces slowly cooked with honey would set when cool."
    width_cases = [
      Lipgloss::Style.new.padding(0, 2).border(Lipgloss::Border.normal, true),
      Lipgloss::Style.new.padding(0, 2),
      Lipgloss::Style.new.padding(0, 2).border(Lipgloss::Border.normal, true).border_left(false).border_right(false),
      Lipgloss::Style.new.padding(0, 2).border(Lipgloss::Border.normal, true).unset_border_bottom.unset_border_top.unset_border_right,
    ]
    width_cases.each do |width_style|
      content_width = 80 - width_style.horizontal_frame_size
      rendered = width_style.width(content_width).render(content)
      Lipgloss.width(rendered).should eq(content_width)
    end

    height_cases = [
      Lipgloss::Style.new.width(80).padding(0, 2).border(Lipgloss::Border.normal, true),
      Lipgloss::Style.new.width(80).padding(0, 2),
      Lipgloss::Style.new.width(80).padding(0, 2).border(Lipgloss::Border.normal, true).border_bottom(false).border_top(false),
      Lipgloss::Style.new.width(80).padding(0, 2).border(Lipgloss::Border.normal, true).unset_border_left.unset_border_bottom.unset_border_right,
    ]
    height_cases.each do |height_style|
      content_height = 20 - height_style.vertical_frame_size
      rendered = height_style.height(content_height).render(content)
      Lipgloss.height(rendered).should eq(content_height)
    end
  end
end
