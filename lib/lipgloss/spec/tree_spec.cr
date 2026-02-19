require "./spec_helper"

TREE_GOLDEN_DIR = File.join(__DIR__, "..", "vendor", "lipgloss", "tree", "testdata")

private def tree_golden(*parts : String) : String
  File.read(File.join(TREE_GOLDEN_DIR, *parts)).chomp
end

describe Lipgloss::Tree do
  around_each do |example|
    renderer = Lipgloss::StyleRenderer.default
    previous_profile = renderer.color_profile
    renderer.color_profile = Lipgloss::ColorProfile::ANSI256
    begin
      example.run
    ensure
      renderer.color_profile = previous_profile
    end
  end

  it "renders tree before and after rounded enumerator" do
    tr = Lipgloss::Tree.new
      .child(
        "Foo",
        Lipgloss::Tree.root("Bar")
          .child(
            "Qux",
            Lipgloss::Tree.root("Quux").child("Foo", "Bar"),
            "Quuux"
          ),
        "Baz"
      )

    tr.to_s.should eq(tree_golden("TestTree", "before.golden"))

    tr.enumerator(->(children : Lipgloss::Tree::Children, index : Int32) { Lipgloss::Tree.rounded_enumerator(children, index) })

    tr.to_s.should eq(tree_golden("TestTree", "after.golden"))
  end

  it "renders hidden subtree" do
    tr = Lipgloss::Tree.new
      .child(
        "Foo",
        Lipgloss::Tree.root("Bar")
          .child(
            "Qux",
            Lipgloss::Tree.root("Quux").child("Foo", "Bar").hide(true),
            "Quuux"
          ),
        "Baz"
      )

    tr.to_s.should eq(tree_golden("TestTreeHidden.golden"))
  end

  it "renders fully hidden tree" do
    tr = Lipgloss::Tree.new
      .child(
        "Foo",
        Lipgloss::Tree.root("Bar")
          .child(
            "Qux",
            Lipgloss::Tree.root("Quux").child("Foo", "Bar"),
            "Quuux"
          ),
        "Baz"
      )
      .hide(true)

    tr.to_s.should eq(tree_golden("TestTreeAllHidden.golden"))
  end

  it "renders rooted tree" do
    tr = Lipgloss::Tree.new
      .root("Root")
      .child(
        "Foo",
        Lipgloss::Tree.root("Bar").child("Qux", "Quuux"),
        "Baz"
      )

    tr.to_s.should eq(tree_golden("TestTreeRoot.golden"))
  end

  it "renders when first node is subtree" do
    tr = Lipgloss::Tree.new
      .child(
        Lipgloss::Tree.new.root("Bar").child("Qux", "Quuux"),
        "Baz"
      )

    tr.to_s.should eq(tree_golden("TestTreeStartsWithSubtree.golden"))
  end

  it "auto parents unnamed subtrees" do
    tr = Lipgloss::Tree.new
      .child(
        "Bar",
        "Foo",
        Lipgloss::Tree.new.child("Qux", "Qux", "Qux", "Qux", "Qux"),
        Lipgloss::Tree.new.child("Quux", "Quux", "Quux", "Quux", "Quux"),
        "Baz"
      )

    tr.to_s.should eq(tree_golden("TestTreeAddTwoSubTreesWithoutName.golden"))
  end

  it "renders when last node is subtree" do
    tr = Lipgloss::Tree.new
      .child(
        "Foo",
        Lipgloss::Tree.root("Bar")
          .child(
            "Qux",
            Lipgloss::Tree.root("Quux").child("Foo", "Bar"),
            "Quuux"
          )
      )

    tr.to_s.should eq(tree_golden("TestTreeLastNodeIsSubTree.golden"))
  end

  it "handles nil child value" do
    tr = Lipgloss::Tree.new
      .child(
        nil,
        Lipgloss::Tree.root("Bar")
          .child(
            "Qux",
            Lipgloss::Tree.root("Quux").child("Bar"),
            "Quuux"
          ),
        "Baz"
      )

    tr.to_s.should eq(tree_golden("TestTreeNil.golden"))
  end

  it "renders custom styles/enumerator/indenter" do
    tr = Lipgloss::Tree.new
      .child(
        "Foo",
        Lipgloss::Tree.new
          .root("Bar")
          .child(
            "Qux",
            Lipgloss::Tree.new.root("Quux").child("Foo", "Bar"),
            "Quuux"
          ),
        "Baz"
      )
      .item_style(Lipgloss::Style.new.foreground(Lipgloss::Color.new(Lipgloss::Color::Type::Named, 9)))
      .enumerator_style(Lipgloss::Style.new.foreground(Lipgloss::Color.new(Lipgloss::Color::Type::Named, 12)).padding_right(1))
      .indenter_style(Lipgloss::Style.new.foreground(Lipgloss::Color.new(Lipgloss::Color::Type::Named, 12)).padding_right(1))
      .enumerator(->(_children : Lipgloss::Tree::Children, _index : Int32) { "->" })
      .indenter(->(_children : Lipgloss::Tree::Children, _index : Int32) { "->" })

    tr.to_s.should eq(tree_golden("TestTreeCustom.golden"))
  end

  it "renders multiline nodes" do
    tr = Lipgloss::Tree.new
      .root("Big\nRoot\nNode")
      .child(
        "Foo",
        Lipgloss::Tree.new
          .root("Bar")
          .child(
            "Line 1\nLine 2\nLine 3\nLine 4",
            Lipgloss::Tree.new.root("Quux").child("Foo", "Bar"),
            "Quuux"
          ),
        "Baz\nLine 2"
      )

    tr.to_s.should eq(tree_golden("TestTreeMultilineNode.golden"))
  end

  it "renders subtree with custom enumerator style func" do
    tr = Lipgloss::Tree.new
      .root("The Root Node™")
      .child(
        Lipgloss::Tree.new
          .root("Parent")
          .child("child 1", "child 2")
          .item_style_func(->(_children : Lipgloss::Tree::Children, _index : Int32) { Lipgloss::Style.new.transform(->(s : String) { "* " + s }) })
          .enumerator_style_func(->(_children : Lipgloss::Tree::Children, _index : Int32) { Lipgloss::Style.new.transform(->(s : String) { "+ " + s }).padding_right(1) }),
        "Baz"
      )

    tr.to_s.should eq(tree_golden("TestTreeSubTreeWithCustomEnumerator.golden"))
  end

  it "aligns mixed enumerator sizes" do
    romans = {1 => "I", 2 => "II", 3 => "III", 4 => "IV", 5 => "V", 6 => "VI"}

    tr = Lipgloss::Tree.new
      .root("The Root Node™")
      .child("Foo", "Foo", "Foo", "Foo", "Foo")
      .enumerator(->(_children : Lipgloss::Tree::Children, index : Int32) { romans[index + 1] || "" })

    tr.to_s.should eq(tree_golden("TestTreeMixedEnumeratorSize.golden"))
  end

  it "allows nil style funcs" do
    tr = Lipgloss::Tree.new
      .root("Silly")
      .child("Willy ", "Nilly")
      .item_style_func(nil)
      .enumerator_style_func(nil)

    tr.to_s.should eq(tree_golden("TestTreeStyleNilFuncs.golden"))
  end

  it "styles by item value" do
    tr = Lipgloss::Tree.new
      .root("Root")
      .child("Foo", "Baz")
      .enumerator(->(data : Lipgloss::Tree::Children, index : Int32) { data.at(index).try(&.value) == "Foo" ? ">" : "-" })

    tr.to_s.should eq(tree_golden("TestTreeStyleAt.golden"))
  end

  it "supports root style" do
    tr = Lipgloss::Tree.new
      .root("Root")
      .child("Foo", "Baz")
      .root_style(Lipgloss::Style.new.background(Lipgloss::Color.from_hex("#5A56E0")))
      .item_style(Lipgloss::Style.new.background(Lipgloss::Color.from_hex("#04B575")))

    Lipgloss::Text.strip_ansi(tr.to_s).should eq(tree_golden("TestRootStyle.golden"))
  end

  it "supports data at and filter semantics" do
    data = Lipgloss::Tree.new_string_data("Foo", "Bar")
    data.at(0).try(&.to_s).should eq("Foo")
    data.at(10).should be_nil
    data.at(-1).should be_nil

    filtered = Lipgloss::Tree
      .new_filter(Lipgloss::Tree.new_string_data("Foo", "Bar", "Baz", "Nope"))
      .filter(->(index : Int32) { index != 3 })

    tr = Lipgloss::Tree.new.root("Root").child(filtered)
    tr.to_s.should eq(tree_golden("TestFilter.golden"))
    filtered.at(1).try(&.value).should eq("Bar")
    filtered.at(10).should be_nil
  end

  it "renders tree table and add-item variants" do
    table = Lipgloss::StyleTable::Table.new
      .width(20)
      .border(Lipgloss::Border.normal)
      .style_func(->(_row : Int32, _col : Int32) { Lipgloss::Style.new.padding(0, 1) })
      .headers("Foo", "Bar")
      .row("Qux", "Baz")
      .row("Qux", "Baz")

    tr = Lipgloss::Tree.new
      .child(
        "Foo",
        Lipgloss::Tree.new
          .root("Bar")
          .child("Baz", "Baz", table, "Baz"),
        "Qux"
      )

    tr.to_s.should eq(tree_golden("TestTreeTable.golden"))

    with_root = Lipgloss::Tree.new
      .child("Foo", "Bar", Lipgloss::Tree.new.child("Baz"), "Qux")
    with_root.to_s.should eq(tree_golden("TestAddItemWithAndWithoutRoot", "with_root.golden"))

    without_root = Lipgloss::Tree.new
      .child("Foo", Lipgloss::Tree.new.root("Bar").child("Baz"), "Qux")
    without_root.to_s.should eq(tree_golden("TestAddItemWithAndWithoutRoot", "without_root.golden"))
  end

  it "embeds list within tree" do
    tr = Lipgloss::Tree.new
      .child(Lipgloss::List.new("A", "B", "C").enumerator(->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.arabic(items, index) }))
      .child(Lipgloss::List.new("1", "2", "3").enumerator(->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.alphabet(items, index) }))

    tr.to_s.should eq(tree_golden("TestEmbedListWithinTree.golden"))
  end

  it "renders multiline prefixes" do
    paddings_style = Lipgloss::Style.new.padding_left(1).padding_bottom(1)

    tr = Lipgloss::Tree.new
      .enumerator(->(_children : Lipgloss::Tree::Children, index : Int32) { index == 1 ? "│\n│" : " " })
      .indenter(->(_children : Lipgloss::Tree::Children, _index : Int32) { " " })
      .item_style(paddings_style)
      .child("Foo Document\nThe Foo Files")
      .child("Bar Document\nThe Bar Files")
      .child("Baz Document\nThe Baz Files")

    tr.to_s.should eq(tree_golden("TestMultilinePrefix.golden"))
  end

  it "renders multiline prefixes in subtree" do
    paddings_style = Lipgloss::Style.new.padding(0, 0, 1, 1)

    tr = Lipgloss::Tree.new
      .child("Foo")
      .child("Bar")
      .child(
        Lipgloss::Tree.new
          .root("Baz")
          .enumerator(->(_children : Lipgloss::Tree::Children, index : Int32) { index == 1 ? "│\n│" : " " })
          .indenter(->(_children : Lipgloss::Tree::Children, _index : Int32) { " " })
          .item_style(paddings_style)
          .child("Foo Document\nThe Foo Files")
          .child("Bar Document\nThe Bar Files")
          .child("Baz Document\nThe Baz Files")
      )
      .child("Qux")

    tr.to_s.should eq(tree_golden("TestMultilinePrefixSubtree.golden"))
  end

  it "renders multiline prefix inception" do
    glow_enum = ->(_children : Lipgloss::Tree::Children, index : Int32) { index == 1 ? "│\n│" : " " }
    glow_indenter = ->(_children : Lipgloss::Tree::Children, _index : Int32) { "  " }
    paddings_style = Lipgloss::Style.new.padding_left(1).padding_bottom(1)

    tr = Lipgloss::Tree.new
      .enumerator(glow_enum)
      .indenter(glow_indenter)
      .item_style(paddings_style)
      .child("Foo Document\nThe Foo Files")
      .child("Bar Document\nThe Bar Files")
      .child(
        Lipgloss::Tree.new
          .enumerator(glow_enum)
          .indenter(glow_indenter)
          .item_style(paddings_style)
          .child("Qux Document\nThe Qux Files")
          .child("Quux Document\nThe Quux Files")
          .child("Quuux Document\nThe Quuux Files")
      )
      .child("Baz Document\nThe Baz Files")

    tr.to_s.should eq(tree_golden("TestMultilinePrefixInception.golden"))
  end

  it "supports scalar and array child types" do
    tr = Lipgloss::Tree.new
      .child(0)
      .child(true)
      .child(["Foo", "Bar"])
      .child(["Qux", "Quux", "Quuux"])

    tr.to_s.should eq(tree_golden("TestTypes.golden"))
  end
end
