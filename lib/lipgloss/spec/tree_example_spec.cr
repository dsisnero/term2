require "./spec_helper"

private def set_hidden_node(node : Lipgloss::Tree::Node?, hidden : Bool) : Nil
  return unless node
  case node
  when Lipgloss::Tree::Leaf
    node.hidden = hidden
  when Lipgloss::Tree::Tree
    node.hidden = hidden
  end
end

private def set_node_value(node : Lipgloss::Tree::Node?, value : String) : Nil
  return unless node
  node.value = value
end

describe "Lipgloss parity: tree examples" do
  it "matches ExampleLeaf_SetHidden output" do
    tree = Lipgloss::Tree.new
      .child(
        "Foo",
        Lipgloss::Tree.root("Bar")
          .child(
            "Qux",
            Lipgloss::Tree.root("Quux").child("Hello!"),
            "Quuux"
          ),
        "Baz"
      )

    set_hidden_node(tree.children.at(1).try(&.children.at(2)), true)

    tree.to_s.should eq <<-TXT.chomp
      ├── Foo
      ├── Bar
      │   ├── Qux
      │   └── Quux
      │       └── Hello!
      └── Baz
      TXT
  end

  it "matches ExampleNewLeaf output" do
    tree = Lipgloss::Tree.new
      .child(
        "Foo",
        Lipgloss::Tree.root("Bar")
          .child(
            "Qux",
            Lipgloss::Tree.root("Quux")
              .child(
                Lipgloss::Tree::Leaf.new("This should be hidden", true),
                Lipgloss::Tree::Leaf.new(Lipgloss::Tree.root("I am groot").child("leaves"), false)
              ),
            "Quuux"
          ),
        "Baz"
      )

    tree.to_s.should eq <<-TXT.chomp
      ├── Foo
      ├── Bar
      │   ├── Qux
      │   ├── Quux
      │   │   └── I am groot
      │   │       └── leaves
      │   └── Quuux
      └── Baz
      TXT
  end

  it "matches ExampleLeaf_SetValue output" do
    tree = Lipgloss::Tree.root("⁜ Makeup")
      .child(
        "Glossier",
        "Fenty Beauty",
        Lipgloss::Tree.new.child(
          "Gloss Bomb Universal Lip Luminizer",
          "Hot Cheeks Velour Blushlighter"
        ),
        "Nyx",
        "Mac",
        "Milk"
      )
      .enumerator(->(children : Lipgloss::Tree::Children, index : Int32) { Lipgloss::Tree.rounded_enumerator(children, index) })

    set_node_value(tree.children.at(0), "Il Makiage")

    Lipgloss::Text.strip_ansi(tree.to_s).should eq <<-TXT.chomp
      ⁜ Makeup
      ├── Il Makiage
      ├── Fenty Beauty
      │   ├── Gloss Bomb Universal Lip Luminizer
      │   ╰── Hot Cheeks Velour Blushlighter
      ├── Nyx
      ├── Mac
      ╰── Milk
      TXT
  end

  it "matches ExampleTree_Hide output" do
    tree = Lipgloss::Tree.new
      .child(
        "Foo",
        Lipgloss::Tree.root("Bar")
          .child(
            "Qux",
            Lipgloss::Tree.root("Quux")
              .child("Foo", "Bar")
              .hide(true),
            "Quuux"
          ),
        "Baz"
      )

    tree.to_s.should eq <<-TXT.chomp
      ├── Foo
      ├── Bar
      │   ├── Qux
      │   └── Quuux
      └── Baz
      TXT
  end

  it "matches ExampleTree_SetHidden output" do
    tree = Lipgloss::Tree.new
      .child(
        "Foo",
        Lipgloss::Tree.root("Bar")
          .child(
            "Qux",
            Lipgloss::Tree.root("Quux")
              .child("Foo", "Bar"),
            "Quuux"
          ),
        "Baz"
      )

    set_hidden_node(tree.children.at(1).try(&.children.at(1)), true)

    tree.to_s.should eq <<-TXT.chomp
      ├── Foo
      ├── Bar
      │   ├── Qux
      │   └── Quuux
      └── Baz
      TXT
  end
end
