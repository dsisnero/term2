require "./spec_helper"
require "../src/term2"

describe Term2::Style do
  describe "Fluent API" do
    it "sets foreground color" do
      style = Term2::Style.new.foreground(Term2::Color::RED)
      style.foreground_color.should eq(Term2::Color::RED)
    end

    it "sets foreground by name" do
      style = Term2::Style.new.foreground(:light_red)
      style.foreground_color.should eq(Term2::Color::BRIGHT_RED)
    end

    it "sets background color" do
      style = Term2::Style.new.background(Term2::Color::BLUE)
      style.background_color.should eq(Term2::Color::BLUE)
    end

    it "sets background by hex shorthand" do
      style = Term2::Style.new.bg_hex("#123456")
      style.background_color.should eq(Term2::Color.rgb(0x12, 0x34, 0x56))
    end

    it "builds with block" do
      style = Term2::Style.build do |s|
        s.fg_rgb(10, 20, 30).bg_indexed(240).bold(true)
      end
      style.foreground_color.should eq(Term2::Color.rgb(10, 20, 30))
      style.background_color.should eq(Term2::Color.indexed(240))
      style.bold?.should be_true
    end

    it "supports fg/bg aliases with symbols and colors" do
      style = Term2::Style.new.fg(:red).bg(:dark_gray)
      style.foreground_color.should eq(Term2::Color::RED)
      style.background_color.should eq(Term2::Color::BRIGHT_BLACK)
      style = Term2::Style.new.fg(Term2::Color::GREEN).bg(Term2::Color::BLUE)
      style.foreground_color.should eq(Term2::Color::GREEN)
      style.background_color.should eq(Term2::Color::BLUE)
    end

    it "sets named foreground/background helpers" do
      style = Term2::Style.new.red.on_light_blue
      style.foreground_color.should eq(Term2::Color::RED)
      style.background_color.should eq(Term2::Color::BRIGHT_BLUE)
      style = Term2::Style.new.light_green(false)
      style.foreground_color.should be_nil
    end

    it "sets text attributes" do
      style = Term2::Style.new.bold(true).italic(true).underline(true)
      style.bold?.should be_true
      style.italic?.should be_true
      style.underline?.should be_true
    end

    it "sets padding" do
      style = Term2::Style.new.padding(1, 2, 3, 4)
      style.padding.top.should eq(1)
      style.padding.right.should eq(2)
      style.padding.bottom.should eq(3)
      style.padding.left.should eq(4)
    end

    it "sets margin" do
      style = Term2::Style.new.margin(1)
      style.margin.top.should eq(1)
      style.margin.right.should eq(1)
      style.margin.bottom.should eq(1)
      style.margin.left.should eq(1)
    end

    it "sets width and height" do
      style = Term2::Style.new.width(10).height(5)
      style.width_value.should eq(10)
      style.height_value.should eq(5)
    end

    it "sets alignment" do
      style = Term2::Style.new.align(Term2::Position::Center)
      style.align_value.should eq(Term2::Position::Center)
    end
  end

  describe "Rendering" do
    it "renders basic text" do
      style = Term2::Style.new
      output = style.render("Hello")
      output.should eq("Hello")
    end

    it "renders with padding" do
      style = Term2::Style.new.padding(1, 2)
      output = style.render("Hello")
      lines = output.split('\n')
      lines.size.should eq(3)
      lines[0].should eq(" " * 9)
      lines[1].should eq("  Hello  ")
      lines[2].should eq(" " * 9)
    end

    it "renders with margin" do
      style = Term2::Style.new.margin(1, 0)
      output = style.render("Hello")
      lines = output.split('\n')
      lines.size.should eq(3)
      lines[0].should eq("")
      lines[1].should eq("Hello")
      lines[2].should eq("")
    end
  end

  describe "Copying" do
    it "creates an independent copy" do
      original = Term2::Style.new.bold(true).foreground(Term2::Color::RED)
      copy = original.copy

      copy.italic(true)

      original.italic?.should be_false
      copy.italic?.should be_true
      copy.bold?.should be_true
    end
  end
end

describe Term2::Color do
  it "creates named colors" do
    color = Term2::Color::RED
    color.type.should eq(Term2::Color::Type::Named)
  end

  it "creates indexed colors" do
    color = Term2::Color.new(Term2::Color::Type::Indexed, 128)
    color.type.should eq(Term2::Color::Type::Indexed)
    color.value.should eq(128)
  end

  it "creates RGB colors from hex" do
    color = Term2::Color.from_hex("#FF5500")
    color.type.should eq(Term2::Color::Type::RGB)
    color.value.should eq({255, 85, 0})
  end

  it "creates RGB colors via hex alias" do
    color = Term2::Color.hex("#0A0B0C")
    color.should eq(Term2::Color.rgb(10, 11, 12))
  end

  it "handles short hex colors" do
    color = Term2::Color.from_hex("#F50")
    color.type.should eq(Term2::Color::Type::RGB)
    color.value.should eq({255, 85, 0})
  end

  it "creates colors from names" do
    Term2::Color.from_name(:light_blue).should eq(Term2::Color::BRIGHT_BLUE)
    Term2::Color.from_name("default").should be_nil
  end
end
