require "./spec_helper"
require "../src/term2"

describe Term2::Components::Tree do
  it "renders a simple tree" do
    tree = Term2::Components::Tree.new("Root")
      .child("Child 1")
      .child("Child 2")

    output = tree.render
    lines = output.split('\n')

    lines[0].should eq("Root")
    lines[1].should contain("├── Child 1")
    lines[2].should contain("└── Child 2")
  end

  it "renders a nested tree" do
    subtree = Term2::Components::Tree.new("Child 1")
      .child("Grandchild 1")

    tree = Term2::Components::Tree.new("Root")
      .child(subtree)
      .child("Child 2")

    output = tree.render
    lines = output.split('\n')

    lines[0].should eq("Root")
    lines[1].should contain("├── Child 1")
    lines[2].should contain("│  └── Grandchild 1") # 3-char indent matches Go Lipgloss
    lines[3].should contain("└── Child 2")
  end

  it "respects styles" do
    tree = Term2::Components::Tree.new("Root")
      .child("Child")
      .item_style(Term2::Style.new.bold(true))
      .enumerator_style(Term2::Style.new.foreground(Term2::Color::RED))

    output = tree.render
    output.should_not be_empty
  end

  it "hides subtrees" do
    tree = Term2::Components::Tree.new("Root")
      .child("Visible")
      .child(Term2::Components::Tree.new("Hidden").hide(true))

    output = tree.render
    lines = output.split('\n')

    lines.size.should eq(2)
    lines[0].should eq("Root")
    lines[1].should contain("└── Visible")
    output.should_not contain("Hidden")
  end

  it "hides the whole tree" do
    tree = Term2::Components::Tree.new("Root").hide(true)
    tree.render.should be_empty
  end
end
