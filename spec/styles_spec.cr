require "./spec_helper"

describe Term2::Style do
  describe ".new" do
    it "creates a style with defaults" do
      style = Term2::Style.new
      style.foreground.should be_nil
      style.background.should be_nil
      style.bold?.should be_false
      style.italic?.should be_false
    end

    it "creates a style with attributes" do
      style = Term2::Style.new(bold: true, italic: true)
      style.bold?.should be_true
      style.italic?.should be_true
    end
  end

  describe "#apply" do
    it "returns plain text when no style" do
      style = Term2::Style.new
      style.apply("hello").should eq("hello")
    end

    it "applies bold style" do
      style = Term2::Style.new(bold: true)
      result = style.apply("hello")
      result.should contain("\e[")
      result.should contain("1")  # bold code
      result.should end_with("\e[0m")
    end

    it "applies foreground color" do
      style = Term2::Style.new(foreground: Term2::Color::RED)
      result = style.apply("hello")
      result.should contain("31")  # red foreground
    end
  end

  describe ".bold" do
    it "creates a bold style" do
      Term2::Style.bold.bold?.should be_true
    end
  end

  describe ".red" do
    it "creates a red foreground style" do
      style = Term2::Style.red
      style.foreground.should eq(Term2::Color::RED)
    end
  end

  describe "#merge" do
    it "combines two styles" do
      style1 = Term2::Style.new(bold: true)
      style2 = Term2::Style.new(italic: true)
      merged = style1.merge(style2)
      merged.bold?.should be_true
      merged.italic?.should be_true
    end

    it "second style colors override first" do
      style1 = Term2::Style.new(foreground: Term2::Color::RED)
      style2 = Term2::Style.new(foreground: Term2::Color::BLUE)
      merged = style1.merge(style2)
      merged.foreground.should eq(Term2::Color::BLUE)
    end
  end
end

describe Term2::Color do
  describe "constants" do
    it "has standard colors" do
      Term2::Color::RED.should be_a(Term2::Color)
      Term2::Color::GREEN.should be_a(Term2::Color)
      Term2::Color::BLUE.should be_a(Term2::Color)
    end

    it "has bright colors" do
      Term2::Color::BRIGHT_RED.should be_a(Term2::Color)
      Term2::Color::BRIGHT_GREEN.should be_a(Term2::Color)
    end
  end

  describe ".indexed" do
    it "creates 256-color indexed color" do
      color = Term2::Color.indexed(208)
      color.type.should eq(Term2::Color::Type::Indexed)
    end

    it "clamps values to valid range" do
      color = Term2::Color.indexed(300)
      color.value.should eq(255)
    end
  end

  describe ".rgb" do
    it "creates RGB true color" do
      color = Term2::Color.rgb(100, 150, 200)
      color.type.should eq(Term2::Color::Type::RGB)
      color.value.should eq({100, 150, 200})
    end
  end

  describe "#foreground_codes" do
    it "returns codes for named colors" do
      codes = Term2::Color::RED.foreground_codes
      codes.should eq([31])  # 30 + 1 (red)
    end

    it "returns codes for indexed colors" do
      codes = Term2::Color.indexed(208).foreground_codes
      codes.should eq([38, 5, 208])
    end

    it "returns codes for RGB colors" do
      codes = Term2::Color.rgb(100, 150, 200).foreground_codes
      codes.should eq([38, 2, 100, 150, 200])
    end
  end
end

describe Term2::S do
  describe "chaining" do
    it "chains multiple styles" do
      s = Term2::S.bold.cyan.underline
      s.should be_a(Term2::S)
    end
  end

  describe "#apply" do
    it "applies styles to text" do
      result = Term2::S.bold.apply("hello")
      result.should start_with("\e[")
      result.should contain("1")  # bold code
      result.should contain("hello")
      result.should end_with("\e[0m")
    end

    it "chains multiple styles" do
      result = Term2::S.bold.cyan.apply("hello")
      result.should contain("1")   # bold
      result.should contain("36")  # cyan
    end
  end

  describe "#|" do
    it "is shorthand for apply" do
      result = Term2::S.red | "hello"
      result.should contain("31")  # red
      result.should contain("hello")
    end
  end

  describe "class methods" do
    it "starts chains with bold" do
      Term2::S.bold.should be_a(Term2::S)
    end

    it "starts chains with colors" do
      Term2::S.red.should be_a(Term2::S)
      Term2::S.cyan.should be_a(Term2::S)
    end

    it "starts chains with 256-color" do
      Term2::S.fg(208).should be_a(Term2::S)
    end

    it "starts chains with RGB" do
      Term2::S.fg(100, 150, 200).should be_a(Term2::S)
    end
  end

  describe "background colors" do
    it "applies background colors" do
      result = Term2::S.on_red.apply("hello")
      result.should contain("41")  # red background
    end
  end
end

describe "String extensions" do
  describe "#bold" do
    it "makes text bold" do
      result = "hello".bold
      result.should eq("\e[1mhello\e[0m")
    end
  end

  describe "#red" do
    it "makes text red" do
      result = "hello".red
      result.should eq("\e[31mhello\e[0m")
    end
  end

  describe "#cyan" do
    it "makes text cyan" do
      result = "hello".cyan
      result.should eq("\e[36mhello\e[0m")
    end
  end

  describe "#gray" do
    it "makes text gray" do
      result = "hello".gray
      result.should eq("\e[90mhello\e[0m")
    end
  end

  describe "#on_blue" do
    it "sets blue background" do
      result = "hello".on_blue
      result.should eq("\e[44mhello\e[0m")
    end
  end

  describe "#fg with index" do
    it "sets 256-color foreground" do
      result = "hello".fg(208)
      result.should eq("\e[38;5;208mhello\e[0m")
    end
  end

  describe "#fg with RGB" do
    it "sets RGB foreground" do
      result = "hello".fg(100, 150, 200)
      result.should eq("\e[38;2;100;150;200mhello\e[0m")
    end
  end

  describe "#styled" do
    it "applies raw SGR codes" do
      result = "hello".styled(1, 36)  # bold cyan
      result.should eq("\e[1;36mhello\e[0m")
    end
  end
end

describe Term2::Text do
  describe ".bold" do
    it "applies bold to text" do
      result = Term2::Text.bold("hello")
      result.should contain("1")  # bold code
    end
  end

  describe ".red" do
    it "applies red to text" do
      result = Term2::Text.red("hello")
      result.should contain("31")  # red code
    end
  end

  describe ".style" do
    it "applies style object to text" do
      style = Term2::Style.new(bold: true)
      result = Term2::Text.style("hello", style)
      result.should contain("1")  # bold
    end

    it "combines multiple styles" do
      result = Term2::Text.style("hello", Term2::Style.bold, Term2::Style.cyan)
      result.should contain("1")   # bold
      result.should contain("36")  # cyan
    end
  end
end
