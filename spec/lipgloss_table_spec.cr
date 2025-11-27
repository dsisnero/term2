require "./spec_helper"
require "../src/lipgloss"

describe Term2::LipGloss::Table do
  it "renders a simple table" do
    table = Term2::LipGloss::Table.new
      .headers("Name", "Age")
      .row("Alice", "25")
      .row("Bob", "30")

    output = table.render
    lines = output.split('\n')

    # Check structure
    # Top border
    lines[0].should contain("┌")
    lines[0].should contain("┬")
    lines[0].should contain("┐")

    # Header
    lines[1].should contain("Name")
    lines[1].should contain("Age")
    lines[1].should contain("│")

    # Header separator
    lines[2].should contain("├")
    lines[2].should contain("┼")
    lines[2].should contain("┤")

    # Rows
    lines[3].should contain("Alice")
    lines[3].should contain("25")
    lines[4].should contain("Bob")
    lines[4].should contain("30")

    # Bottom border
    lines[5].should contain("└")
    lines[5].should contain("┴")
    lines[5].should contain("┘")
  end

  it "renders without headers" do
    table = Term2::LipGloss::Table.new
      .row("A", "B")
      .row("C", "D")

    output = table.render
    lines = output.split('\n')

    lines[0].should contain("┌")
    lines[1].should contain("A")
    lines[2].should contain("C")
    lines[3].should contain("└")
  end

  it "renders an empty table" do
    table = Term2::LipGloss::Table.new
      .headers("A", "B")

    output = table.render
    lines = output.split('\n')

    lines.size.should eq(3) # Top, Header, Bottom
    lines[0].should contain("┌")
    lines[1].should contain("A")
    lines[2].should contain("└")
  end

  it "respects styles" do
    header_style = Term2::LipGloss::Style.new.bold(true).foreground(Term2::Color::RED)
    cell_style = Term2::LipGloss::Style.new.foreground(Term2::Color::GREEN)

    table = Term2::LipGloss::Table.new
      .headers("H1")
      .row("R1")
      .header_style(header_style)
      .cell_style(cell_style)

    output = table.render
    # Check for ANSI codes?
    # Just check it renders without error for now.
    output.should_not be_empty
  end

  it "supports style_func for alignment" do
    table = Term2::LipGloss::Table.new
      .headers("     Header     ") # Wide header to force column width
      .row("123")
      .style_func(->(_row : Int32, _col : Int32) {
        Term2::LipGloss::Style.new.align(Term2::LipGloss::Position::Right).as(Term2::LipGloss::Style?)
      })

    output = table.render
    # Content "123" should be right aligned in the 16-char wide cell
    output.should contain("             123")
  end
end
