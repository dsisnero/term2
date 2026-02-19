require "./spec_helper"

LIST_GOLDEN_DIR = File.join(__DIR__, "..", "vendor", "lipgloss", "list", "testdata")

private def list_golden(*parts : String) : String
  File.read(File.join(LIST_GOLDEN_DIR, *parts)).chomp
end

describe Lipgloss::List do
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

  it "renders list" do
    l = Lipgloss::List.new.item("Foo").item("Bar").item("Baz")
    l.to_s.should eq(list_golden("TestList.golden"))
  end

  it "renders list items" do
    l = Lipgloss::List.new.items(["Foo", "Bar", "Baz"])
    l.to_s.should eq(list_golden("TestListItems.golden"))
  end

  it "renders sublist" do
    l = Lipgloss::List.new
      .item("Foo")
      .item("Bar")
      .item(Lipgloss::List.new("Hi", "Hello", "Halo").enumerator(->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.roman(items, index) }))
      .item("Qux")

    l.to_s.should eq(list_golden("TestSublist.golden"))
  end

  it "renders sublist items" do
    l = Lipgloss::List.new(
      "A",
      "B",
      "C",
      Lipgloss::List.new("D", "E", "F").enumerator(->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.roman(items, index) }),
      "G"
    )

    l.to_s.should eq(list_golden("TestSublistItems.golden"))
  end

  it "renders complex sublist" do
    style1 = Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(99)).padding_right(1)
    style2 = Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(212)).padding_right(1)

    l = Lipgloss::List.new
      .item("Foo")
      .item("Bar")
      .item(Lipgloss::List.new("foo2", "bar2"))
      .item("Qux")
      .item(
        Lipgloss::List.new("aaa", "bbb")
          .enumerator_style(style1)
          .enumerator(->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.roman(items, index) })
      )
      .item("Deep")
      .item(
        Lipgloss::List.new
          .enumerator_style(style2)
          .indenter_style(style2)
          .enumerator(->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.alphabet(items, index) })
          .item("foo")
          .item("Deeper")
          .item(
            Lipgloss::List.new
              .indenter_style(style1)
              .enumerator_style(style1)
              .enumerator(->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.arabic(items, index) })
              .item("a")
              .item("b")
              .item("Even Deeper, inherit parent renderer")
              .item(
                Lipgloss::List.new
                  .enumerator(->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.asterisk(items, index) })
                  .indenter_style(style2)
                  .enumerator_style(style2)
                  .item("sus")
                  .item("d minor")
                  .item("f#")
                  .item("One ore level, with another renderer")
                  .item(
                    Lipgloss::List.new
                      .indenter_style(style1)
                      .enumerator_style(style1)
                      .enumerator(->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.dash(items, index) })
                      .item("a\nmultine\nstring")
                      .item("hoccus poccus")
                      .item("abra kadabra")
                      .item("And finally, a tree within all this")
                      .item(
                        Lipgloss::Tree.new
                          .indenter_style(style2)
                          .enumerator_style(style2)
                          .child("another\nmultine\nstring")
                          .child("something")
                          .child("a subtree")
                          .child(
                            Lipgloss::Tree.new
                              .indenter_style(style2)
                              .enumerator_style(style2)
                              .child("yup")
                              .child("many itens")
                              .child("another")
                          )
                          .child("hallo")
                          .child("wunderbar!")
                      )
                      .item("this is a tree\nand other obvious statements")
                  )
              )
          )
          .item("bar")
      )
      .item("Baz")

    l.to_s.should eq(list_golden("TestComplexSublist.golden"))
  end

  it "renders multiline items" do
    l = Lipgloss::List.new
      .item("Item1\nline 2\nline 3")
      .item("Item2\nline 2\nline 3")
      .item("3")

    l.to_s.should eq(list_golden("TestMultiline.golden"))
  end

  it "renders list integers" do
    l = Lipgloss::List.new.item("1").item("2").item("3")
    l.to_s.should eq(list_golden("TestListIntegers.golden"))
  end

  it "renders enumerators" do
    tests = {
      "alphabet" => ->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.alphabet(items, index) },
      "arabic"   => ->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.arabic(items, index) },
      "roman"    => ->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.roman(items, index) },
      "bullet"   => ->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.bullet(items, index) },
      "asterisk" => ->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.asterisk(items, index) },
      "dash"     => ->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.dash(items, index) },
    }

    tests.each do |name, enumerator|
      l = Lipgloss::List.new
        .enumerator(enumerator)
        .item("Foo")
        .item("Bar")
        .item("Baz")

      l.to_s.should eq(list_golden("TestEnumerators", "#{name}.golden"))
    end
  end

  it "renders transformed enumerators" do
    tests = {
      "alphabet_lower.golden" => {
        enum:  ->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.alphabet(items, index) },
        style: Lipgloss::Style.new.padding_right(1).transform(->(s : String) { s.downcase }),
      },
      "arabic).golden" => {
        enum:  ->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.arabic(items, index) },
        style: Lipgloss::Style.new.padding_right(1).transform(->(s : String) { s.sub('.', ')') }),
      },
      "roman_within_().golden" => {
        enum:  ->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.roman(items, index) },
        style: Lipgloss::Style.new.transform(->(s : String) { "(" + s.downcase.gsub(".", "") + ") " }),
      },
      "bullet_is_dash.golden" => {
        enum:  ->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.bullet(items, index) },
        style: Lipgloss::Style.new.transform(->(_s : String) { "- " }),
      },
    }

    tests.each do |filename, test|
      l = Lipgloss::List.new
        .enumerator_style(test[:style])
        .enumerator(test[:enum])
        .item("Foo")
        .item("Bar")
        .item("Baz")

      l.to_s.should eq(list_golden("TestEnumeratorsTransform", filename))
    end
  end

  it "matches bullet prefix edge cases" do
    tests = [
      {->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.alphabet(items, index) }, 0, "A"},
      {->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.alphabet(items, index) }, 25, "Z"},
      {->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.alphabet(items, index) }, 26, "AA"},
      {->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.alphabet(items, index) }, 51, "AZ"},
      {->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.alphabet(items, index) }, 52, "BA"},
      {->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.alphabet(items, index) }, 79, "CB"},
      {->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.alphabet(items, index) }, 701, "ZZ"},
      {->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.alphabet(items, index) }, 702, "AAA"},
      {->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.alphabet(items, index) }, 801, "ADV"},
      {->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.alphabet(items, index) }, 1000, "ALM"},
      {->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.roman(items, index) }, 0, "I"},
      {->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.roman(items, index) }, 25, "XXVI"},
      {->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.roman(items, index) }, 26, "XXVII"},
      {->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.roman(items, index) }, 50, "LI"},
      {->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.roman(items, index) }, 100, "CI"},
      {->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.roman(items, index) }, 701, "DCCII"},
      {->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.roman(items, index) }, 1000, "MI"},
    ]

    tests.each do |enumerator, index, expected|
      prefix = enumerator.call(Lipgloss::Tree::NodeChildren.new, index)
      prefix.rchop(".").should eq(expected)
    end
  end

  it "aligns long enumerators" do
    l = Lipgloss::List.new.enumerator(->(items : Lipgloss::List::Items, index : Int32) { Lipgloss::List.roman(items, index) })
    100.times { l.item("Foo") }

    l.to_s.should eq(list_golden("TestEnumeratorsAlign.golden"))
  end

  it "renders nested items v2" do
    l = Lipgloss::List.new.items(
      "S",
      Lipgloss::List.new.items("neovim", "vscode"),
      "HI",
      Lipgloss::List.new.items(["vim", "doom emacs"]),
      "Parent 2",
      Lipgloss::List.new.item("I like fuzzy socks")
    )

    l.to_s.should eq(list_golden("TestSubListItems2.golden"))
  end
end
