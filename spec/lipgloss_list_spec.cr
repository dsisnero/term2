require "./spec_helper"
require "../src/lipgloss"

describe Term2::LipGloss::List do
  it "renders a bullet list" do
    list = Term2::LipGloss::List.new
      .items("Apple", "Banana")

    output = list.render
    lines = output.split('\n')

    lines[0].should contain("• Apple")
    lines[1].should contain("• Banana")
  end

  it "renders an arabic list" do
    list = Term2::LipGloss::List.new
      .items("First", "Second")
      .enumerator(Term2::LipGloss::List::Enumerator::Arabic)

    output = list.render
    lines = output.split('\n')

    lines[0].should contain("1. First")
    lines[1].should contain("2. Second")
  end

  it "renders an alphabet list" do
    list = Term2::LipGloss::List.new
      .items("A", "B")
      .enumerator(Term2::LipGloss::List::Enumerator::Alphabet)

    output = list.render
    lines = output.split('\n')

    lines[0].should contain("A. A")
    lines[1].should contain("B. B")
  end

  it "respects styles" do
    enum_style = Term2::LipGloss::Style.new.foreground(Term2::Color::RED)
    item_style = Term2::LipGloss::Style.new.bold(true)

    list = Term2::LipGloss::List.new
      .items("Item")
      .enumerator_style(enum_style)
      .item_style(item_style)

    output = list.render
    output.should_not be_empty
  end

  it "renders nested lists" do
    nested = Term2::LipGloss::List.new
      .items("Nested 1", "Nested 2")
      .enumerator(Term2::LipGloss::List::Enumerator::Alphabet)

    list = Term2::LipGloss::List.new
      .items("Item 1")
      .item(nested)
      .item("Item 3")

    output = list.render
    lines = output.split('\n')

    lines[0].should contain("• Item 1")
    lines[1].should contain("• A. Nested 1")
    lines[2].should contain("  B. Nested 2") # Indented
    lines[3].should contain("• Item 3")
  end
end
