require "./spec_helper"

alias Table = Lipgloss::StyleTable::Table
alias StringData = Lipgloss::StyleTable::StringData
alias Filter = Lipgloss::StyleTable::Filter

TABLE_GOLDEN_DIR = File.join(__DIR__, "table", "testdata")

def load_golden(*parts)
  path = File.join(TABLE_GOLDEN_DIR, *parts)
  File.read(path)
end

def table_style(row, col)
  case
  when row == Lipgloss::StyleTable::HEADER_ROW
    Lipgloss::Style.new.padding(0, 1).align(Lipgloss::Position::Center)
  when row.even?
    Lipgloss::Style.new.padding(0, 1)
  else
    Lipgloss::Style.new.padding(0, 1)
  end
end

def add_rows(table : Table, rows : Enumerable(Enumerable(String)))
  rows.each { |r| table.row(r) }
end

describe "Lipgloss parity: table renderer" do
  around_each do |example|
    renderer = Lipgloss::StyleRenderer.default
    previous_profile = renderer.color_profile
    renderer.color_profile = Lipgloss::ColorProfile::ASCII
    begin
      example.run
    ensure
      renderer.color_profile = previous_profile
    end
  end

  it "renders basic table" do
    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
    add_rows(table, [
      ["Chinese", "Nǐn hǎo", "Nǐ hǎo"],
      ["French", "Bonjour", "Salut"],
      ["Japanese", "こんにちは", "やあ"],
      ["Russian", "Zdravstvuyte", "Privet"],
      ["Spanish", "Hola", "¿Qué tal?"],
    ])

    table.string.should eq(load_golden("TestTable.golden"))
  end

  it "renders example table" do
    header_style = Lipgloss::Style.new.padding(0, 1).align(Lipgloss::Position::Center)
    even_row_style = Lipgloss::Style.new.padding(0, 1)
    odd_row_style = Lipgloss::Style.new.padding(0, 1)

    rows = [
      {"Chinese", "您好", "你好"},
      {"Japanese", "こんにちは", "やあ"},
      {"Russian", "Здравствуйте", "Привет"},
      {"Spanish", "Hola", "¿Qué tal?"},
    ]

    table = Table.new
      .border(Lipgloss::Border.normal)
      .border_style(Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(99)))
      .style_func(->(row : Int32, _col : Int32) {
        case
        when row == Lipgloss::StyleTable::HEADER_ROW
          header_style
        when row.even?
          even_row_style
        else
          odd_row_style
        end
      })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
    add_rows(table, rows.map(&.to_a))
    table.row("English", "You look absolutely fabulous.", "How's it going?")

    table.string.should eq(load_golden("TestTableExample.golden"))
  end

  it "renders empty table" do
    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")

    table.string.should eq(load_golden("TestTableEmpty.golden"))
  end

  it "renders without style func" do
    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(nil)
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
      .row("Chinese", "Nǐn hǎo", "Nǐ hǎo")
      .row("French", "Bonjour", "Salut")
      .row("Japanese", "こんにちは", "やあ")
      .row("Russian", "Zdravstvuyte", "Privet")
      .row("Spanish", "Hola", "¿Qué tal?")

    table.string.should eq(load_golden("TestTableNoStyleFunc.golden"))
  end

  it "renders with margin and right alignment" do
    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(_r : Int32, _c : Int32) { Lipgloss::Style.new.margin(0, 1).align(Lipgloss::Position::Right) })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
      .row("Arabic", "أهلين", "أهلا")
      .row("Chinese", "Nǐn hǎo", "Nǐ hǎo")
      .row("French", "Bonjour", "Salut")
      .row("Japanese", "こんにちは", "やあ")
      .row("Russian", "Zdravstvuyte", "Privet")
      .row("Spanish", "Hola", "¿Qué tal?")

    table.string.should eq(load_golden("TestTableMarginAndRightAlignment.golden"))
  end

  it "renders with offset" do
    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
      .row("Chinese", "Nǐn hǎo", "Nǐ hǎo")
      .row("French", "Bonjour", "Salut")
      .row("Japanese", "こんにちは", "やあ")
      .row("Russian", "Zdravstvuyte", "Privet")
      .row("Spanish", "Hola", "¿Qué tal?")
      .offset(1)

    table.string.should eq(load_golden("TestTableOffset.golden"))
  end

  it "renders with double border" do
    rows = [
      {"Chinese", "Nǐn hǎo", "Nǐ hǎo"},
      {"French", "Bonjour", "Salut"},
      {"Japanese", "こんにちは", "やあ"},
      {"Russian", "Zdravstvuyte", "Privet"},
      {"Spanish", "Hola", "¿Qué tal?"},
    ]

    table = Table.new
      .border(Lipgloss::Border.double)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
    add_rows(table, rows.map(&.to_a))

    table.string.should eq(load_golden("TestTableBorder.golden"))
  end

  it "supports set rows" do
    rows = [
      {"Chinese", "Nǐn hǎo", "Nǐ hǎo"},
      {"French", "Bonjour", "Salut"},
      {"Japanese", "こんにちは", "やあ"},
      {"Russian", "Zdravstvuyte", "Privet"},
      {"Spanish", "Hola", "¿Qué tal?"},
    ]
    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
    add_rows(table, rows.map(&.to_a))

    table.string.should eq(load_golden("TestTableSetRows.golden"))
  end

  it "handles more cells than headers" do
    rows = [
      {"Chinese", "Nǐn hǎo", "Nǐ hǎo"},
      {"French", "Bonjour", "Salut"},
      {"Japanese", "こんにちは", "やあ"},
      {"Russian", "Zdravstvuyte", "Privet"},
      {"Spanish", "Hola", "¿Qué tal?"},
    ]
    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL")
    add_rows(table, rows.map(&.to_a))

    table.string.should eq(load_golden("TestMoreCellsThanHeaders.golden"))
  end

  it "handles more cells than headers extra" do
    rows = [
      {"Chinese", "Nǐn hǎo", "Nǐ hǎo"},
      {"French", "Bonjour", "Salut", "Salut"},
      {"Japanese", "こんにちは", "やあ"},
      {"Russian", "Zdravstvuyte", "Privet", "Privet", "Privet"},
      {"Spanish", "Hola", "¿Qué tal?"},
    ]

    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL")
    add_rows(table, rows.map(&.to_a))

    table.string.should eq(load_golden("TestMoreCellsThanHeadersExtra.golden"))
  end

  it "renders without headers" do
    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .row("Chinese", "Nǐn hǎo", "Nǐ hǎo")
      .row("French", "Bonjour", "Salut")
      .row("Japanese", "こんにちは", "やあ")
      .row("Russian", "Zdravstvuyte", "Privet")
      .row("Spanish", "Hola", "¿Qué tal?")

    table.string.should eq(load_golden("TestTableNoHeaders.golden"))
  end

  it "renders without column separators" do
    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .row("Chinese", "Nǐn hǎo", "Nǐ hǎo")
      .row("French", "Bonjour", "Salut")
      .row("Japanese", "こんにちは", "やあ")
      .row("Russian", "Zdravstvuyte", "Privet")
      .row("Spanish", "Hola", "¿Qué tal?")
    table.border_column = false

    table.string.should eq(load_golden("TestTableNoColumnSeparators.golden"))
  end

  it "renders without column separators with headers" do
    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
      .row("Chinese", "Nǐn hǎo", "Nǐ hǎo")
      .row("French", "Bonjour", "Salut")
      .row("Japanese", "こんにちは", "やあ")
      .row("Russian", "Zdravstvuyte", "Privet")
      .row("Spanish", "Hola", "¿Qué tal?")
    table.border_column = false

    table.string.should eq(load_golden("TestTableNoColumnSeparatorsWithHeaders.golden"))
  end

  it "handles border columns with extra rows" do
    rows = [
      {"Chinese", "Nǐn hǎo", "Nǐ hǎo"},
      {"French", "Bonjour", "Salut", "Salut"},
      {"Japanese", "こんにちは", "やあ"},
      {"Russian", "Zdravstvuyte", "Privet", "Privet", "Privet"},
      {"Spanish", "Hola", "¿Qué tal?"},
    ]

    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL")
    table.border_column = false
    add_rows(table, rows.map(&.to_a))

    table.string.should eq(load_golden("TestBorderColumnsWithExtraRows.golden"))
  end

  it "handles unset borders" do
    rows = [
      {"Chinese", "Nǐn hǎo", "Nǐ hǎo"},
      {"French", "Bonjour", "Salut"},
      {"Japanese", "こんにちは", "やあ"},
      {"Russian", "Zdravstvuyte", "Privet"},
      {"Spanish", "Hola", "¿Qué tal?"},
    ]

    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
    add_rows(table, rows.map(&.to_a))
    table.border_top = false
    table.border_bottom = false
    table.border_left = false
    table.border_right = false

    table.string.should eq(load_golden("TestTableUnsetBorders.golden"))
  end

  it "handles unset header separator" do
    rows = [
      {"Chinese", "Nǐn hǎo", "Nǐ hǎo"},
      {"French", "Bonjour", "Salut"},
      {"Japanese", "こんにちは", "やあ"},
      {"Russian", "Zdravstvuyte", "Privet"},
      {"Spanish", "Hola", "¿Qué tal?"},
    ]

    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
    add_rows(table, rows.map(&.to_a))
    table.border_header = false
    table.border_top = false
    table.border_bottom = false
    table.border_left = false
    table.border_right = false

    table.string.should eq(load_golden("TestTableUnsetHeaderSeparator.golden"))
  end

  it "handles unset header separator with border" do
    rows = [
      {"Chinese", "Nǐn hǎo", "Nǐ hǎo"},
      {"French", "Bonjour", "Salut"},
      {"Japanese", "こんにちは", "やあ"},
      {"Russian", "Zdravstvuyte", "Privet"},
      {"Spanish", "Hola", "¿Qué tal?"},
    ]

    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
    add_rows(table, rows.map(&.to_a))
    table.border_header = false

    table.string.should eq(load_golden("TestTableUnsetHeaderSeparatorWithBorder.golden"))
  end

  it "renders row separators" do
    rows = [
      {"Chinese", "Nǐn hǎo", "Nǐ hǎo"},
      {"French", "Bonjour", "Salut"},
      {"Japanese", "こんにちは", "やあ"},
      {"Russian", "Zdravstvuyte", "Privet"},
      {"Spanish", "Hola", "¿Qué tal?"},
    ]

    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
    add_rows(table, rows.map(&.to_a))
    table.border_row = true

    table.string.should eq(load_golden("TestTableRowSeparators", "no_overflow.golden"))

    table_height = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
    add_rows(table_height, rows)
    table_height.height(8)
    table_height.border_row = true

    table_height.string.should eq(load_golden("TestTableRowSeparators", "with_overflow.golden"))
  end

  it "renders width expand" do
    rows = [
      {"Chinese", "Nǐn hǎo", "Nǐ hǎo"},
      {"French", "Bonjour", "Salut"},
      {"Japanese", "こんにちは", "やあ"},
      {"Russian", "Zdravstvuyte", "Privet"},
      {"Spanish", "Hola", "¿Qué tal?"},
    ]

    table = Table.new
      .width(80)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .border(Lipgloss::Border.normal)
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
    add_rows(table, rows.map(&.to_a))

    Lipgloss::Text.width(table.string).should eq(80)
    table.string.should eq(load_golden("TestTableWidthExpand.golden"))
  end

  it "renders width shrink" do
    rows = [
      {"Chinese", "Nǐn hǎo", "Nǐ hǎo"},
      {"French", "Bonjour", "Salut"},
      {"Japanese", "こんにちは", "やあ"},
      {"Russian", "Zdravstvuyte", "Privet"},
      {"Spanish", "Hola", "¿Qué tal?"},
    ]

    table = Table.new
      .width(30)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .border(Lipgloss::Border.normal)
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
    add_rows(table, rows.map(&.to_a))

    table.string.should eq(load_golden("TestTableWidthShrink.golden"))
  end

  it "renders width smart crop" do
    rows = [
      {"Kini", "40", "New York"},
      {"Eli", "30", "London"},
      {"Iris", "20", "Paris"},
    ]

    table = Table.new
      .width(25)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .border(Lipgloss::Border.normal)
      .headers("Name", "Age of Person", "Location")
    add_rows(table, rows.map(&.to_a))

    table.string.should eq(load_golden("TestTableWidthSmartCrop.golden"))
  end

  it "renders width smart crop extensive" do
    rows = [
      {"Chinese", "您好", "你好"},
      {"Japanese", "こんにちは", "やあ"},
      {"Arabic", "أهلين", "أهلا"},
      {"Russian", "Здравствуйте", "Привет"},
      {"Spanish", "Hola", "¿Qué tal?"},
      {"English", "You look absolutely fabulous.", "How's it going?"},
    ]

    table = Table.new
      .width(18)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .border(Lipgloss::Border.thick)
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
      .wrap(false)
    add_rows(table, rows.map(&.to_a))

    table.string.should eq(load_golden("TestTableWidthSmartCropExtensive.golden"))
  end

  it "renders width smart crop tiny" do
    rows = [
      {"Chinese", "您好", "你好"},
      {"Japanese", "こんにちは", "やあ"},
      {"Russian", "Здравствуйте", "Привет"},
      {"Spanish", "Hola", "¿Qué tal?"},
      {"English", "You look absolutely fabulous.", "How's it going?"},
    ]

    table = Table.new
      .width(1)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .border(Lipgloss::Border.normal)
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
    add_rows(table, rows.map(&.to_a))

    table.string.should eq(load_golden("TestTableWidthSmartCropTiny.golden"))
  end
end
