require "./spec_helper"
require "../src/lipgloss"

include Term2::LipGloss

describe Term2::LipGloss::Style do
  describe "Fluent API" do
    it "sets foreground color" do
      style = Style.new.foreground(Term2::Color::RED)
      style.foreground_color.should eq(Term2::Color::RED)
    end

    it "sets background color" do
      style = Style.new.background(Term2::Color::BLUE)
      style.background_color.should eq(Term2::Color::BLUE)
    end

    it "sets text attributes" do
      style = Style.new.bold.italic.underline
      style.bold?.should be_true
      style.italic?.should be_true
      style.underline?.should be_true
    end

    it "sets padding" do
      style = Style.new.padding(1, 2, 3, 4)
      style.padding.top.should eq(1)
      style.padding.right.should eq(2)
      style.padding.bottom.should eq(3)
      style.padding.left.should eq(4)
    end

    it "sets margin" do
      style = Style.new.margin(1)
      style.margin.top.should eq(1)
      style.margin.right.should eq(1)
      style.margin.bottom.should eq(1)
      style.margin.left.should eq(1)
    end

    it "sets width and height" do
      style = Style.new.width(10).height(5)
      style.width_value.should eq(10)
      style.height_value.should eq(5)
    end

    it "sets alignment" do
      style = Style.new.align(Position::Center)
      style.align_value.should eq(Position::Center)
    end
  end

  describe "Symbol Overloads" do
    it "sets foreground with symbol" do
      style = Style.new.foreground(:red)
      style.foreground_color.should eq(Term2::Color::RED)
    end

    it "sets background with symbol" do
      style = Style.new.background(:blue)
      style.background_color.should eq(Term2::Color::BLUE)
    end

    it "sets border foreground with symbol" do
      style = Style.new.border_foreground(:green)
      style.border_foreground_color.should eq(Term2::Color::GREEN)
    end
  end

  describe "Rendering" do
    it "renders basic text" do
      style = Style.new
      output = style.render("Hello")
      output.should eq("Hello")
    end

    it "renders with padding" do
      style = Style.new.padding(1, 2)
      # Top: 1 line
      # Middle: "  " + "Hello" + "  "
      # Bottom: 1 line
      # Width of content is 5 ("Hello"). Padding left 2, right 2. Total width 9.

      output = style.render("Hello")
      lines = output.split('\n')
      lines.size.should eq(3)
      lines[0].should eq(" " * 9)
      lines[1].should eq("  Hello  ")
      lines[2].should eq(" " * 9)
    end

    it "renders with margin" do
      style = Style.new.margin(1, 0) # Top/Bottom 1, Left/Right 0
      output = style.render("Hello")
      lines = output.split('\n')
      lines.size.should eq(3)
      lines[0].should eq("")
      lines[1].should eq("Hello")
      lines[2].should eq("")
    end

    it "renders with border" do
      style = Style.new.border(Border.normal)
      output = style.render("A")
      # ┌─┐
      # │A│
      # └─┘
      lines = output.split('\n')
      lines.size.should eq(3)
      lines[0].should contain("┌─┐")
      lines[1].should contain("│A│")
      lines[2].should contain("└─┘")
    end

    it "renders with alignment" do
      style = Style.new.width(10).align(Position::Right)
      output = style.render("Hello")
      # "     Hello"
      output.should eq("     Hello")
    end
  end

  describe "Transformations" do
    it "applies upper case transform" do
      style = Style.new.upper_case
      style.render("hello").should eq("HELLO")
    end

    it "applies lower case transform" do
      style = Style.new.lower_case
      style.render("HELLO").should eq("hello")
    end

    it "applies custom transform" do
      style = Style.new.transform(->(s : String) { s + "!" })
      style.render("Hello").should eq("Hello!")
    end
  end

  describe "Adaptive Color" do
    it "uses dark color by default" do
      adaptive = AdaptiveColor.new(light: Term2::Color::WHITE, dark: Term2::Color::BLACK)
      style = Style.new.foreground(adaptive)

      # Default is dark background -> uses dark color (BLACK)
      # BLACK is code 30. Term2::Style adds 0 (reset) at start.
      style.render("test").should contain("\e[0;30m")
    end

    it "uses light color when background is light" do
      adaptive = AdaptiveColor.new(light: Term2::Color::WHITE, dark: Term2::Color::BLACK)
      style = Style.new.foreground(adaptive)

      Term2::LipGloss.has_dark_background = false
      # Light background -> uses light color (WHITE)
      # WHITE is code 37. Term2::Style adds 0 (reset) at start.
      style.render("test").should contain("\e[0;37m")

      # Reset
      Term2::LipGloss.has_dark_background = true
    end
  end

  describe "Layout Utilities" do
    describe "join_horizontal" do
      it "joins blocks aligned top" do
        block1 = "A\nB"
        block2 = "C"

        # A C
        # B
        output = Term2::LipGloss.join_horizontal(Position::Top, block1, block2)
        lines = output.split('\n')
        lines[0].should eq("AC")
        lines[1].should eq("B ") # block2 padded with space of width 1 (width of "C")
      end

      it "joins blocks aligned bottom" do
        block1 = "A\nB"
        block2 = "C"

        # A
        # B C
        output = Term2::LipGloss.join_horizontal(Position::Bottom, block1, block2)
        lines = output.split('\n')
        lines[0].should eq("A ")
        lines[1].should eq("BC")
      end

      it "joins blocks aligned center" do
        block1 = "A\nB\nC"
        block2 = "D"

        # A
        # B D
        # C
        output = Term2::LipGloss.join_horizontal(Position::Center, block1, block2)
        lines = output.split('\n')
        lines[0].should eq("A ")
        lines[1].should eq("BD")
        lines[2].should eq("C ")
      end
    end

    describe "join_vertical" do
      it "joins blocks aligned left" do
        block1 = "A"
        block2 = "BB"

        # A
        # BB
        output = Term2::LipGloss.join_vertical(Position::Left, block1, block2)
        lines = output.split('\n')
        lines[0].should eq("A ")
        lines[1].should eq("BB")
      end

      it "joins blocks aligned right" do
        block1 = "A"
        block2 = "BB"

        #  A
        # BB
        output = Term2::LipGloss.join_vertical(Position::Right, block1, block2)
        lines = output.split('\n')
        lines[0].should eq(" A")
        lines[1].should eq("BB")
      end

      it "joins blocks aligned center" do
        block1 = "A"
        block2 = "BBB"

        #  A
        # BBB
        output = Term2::LipGloss.join_vertical(Position::Center, block1, block2)
        lines = output.split('\n')
        lines[0].should eq(" A ")
        lines[1].should eq("BBB")
      end
    end

    describe "place" do
      it "places content in a box" do
        # Box 5x3
        # Content "A"
        # Center/Center
        #
        # "     "
        # "  A  "
        # "     "

        output = Term2::LipGloss.place(5, 3, Position::Center, Position::Center, "A")
        lines = output.split('\n')
        lines.size.should eq(3)
        lines[0].should eq("     ")
        lines[1].should eq("  A  ")
        lines[2].should eq("     ")
      end

      it "places content top left" do
        output = Term2::LipGloss.place(3, 2, Position::Left, Position::Top, "A")
        lines = output.split('\n')
        lines[0].should eq("A  ")
        lines[1].should eq("   ")
      end

      it "places content bottom right" do
        output = Term2::LipGloss.place(3, 2, Position::Right, Position::Bottom, "A")
        lines = output.split('\n')
        lines[0].should eq("   ")
        lines[1].should eq("  A")
      end
    end

    describe "place_horizontal" do
      it "places content horizontally" do
        output = Term2::LipGloss.place_horizontal(5, Position::Center, "A")
        output.should eq("  A  ")
      end
    end

    describe "place_vertical" do
      it "places content vertically" do
        output = Term2::LipGloss.place_vertical(3, Position::Center, "A")
        lines = output.split('\n')
        lines.size.should eq(3)
        lines[0].should eq(" ")
        lines[1].should eq("A")
        lines[2].should eq(" ")
      end
    end
  end
end
