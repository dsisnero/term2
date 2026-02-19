require "./spec_helper"

alias Table = Lipgloss::StyleTable::Table
alias StringData = Lipgloss::StyleTable::StringData
alias Filter = Lipgloss::StyleTable::Filter

TABLE_GOLDEN_DIR = File.join(__DIR__, "table", "testdata")

def load_golden(*parts)
  path = File.join(TABLE_GOLDEN_DIR, *parts)
  File.read(path)
end

def normalize_table_output(str : String) : String
  str.lines.join('\n', &.rstrip)
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
  rows.each { |row| table.row(row) }
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

  it "renders table with background" do
    renderer = Lipgloss::StyleRenderer.default
    previous_profile = renderer.color_profile
    begin
      renderer.color_profile = Lipgloss::ColorProfile::ANSI256

      table = Table.new
        .border(Lipgloss::Border.normal)
        .base_style(Lipgloss::Style.new.background(Lipgloss::Color.indexed(18)))
        .border_style(Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(15)))
        .style_func(->(_row : Int32, _col : Int32) { Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(15)) })
        .headers("LANGUAGE", "FORMAL", "INFORMAL")
      add_rows(table, [
        ["Chinese", "Nǐn hǎo", "Nǐ hǎo"],
        ["French", "Bonjour", "Salut"],
        ["Japanese", "こんにちは", "やあ"],
        ["Russian", "Zdravstvuyte", "Privet"],
        ["Spanish", "Hola", "¿Qué tal?"],
      ])

      Lipgloss::Text.strip_ansi(table.string).should eq(Lipgloss::Text.strip_ansi(load_golden("TestTableWithBackground.golden")))
    ensure
      renderer.color_profile = previous_profile
    end
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

  it "renders inner borders only" do
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
    table.border_top = false
    table.border_right = false
    table.border_bottom = false
    table.border_left = false
    table.border_row = true
    table.border_column = true

    normalize_table_output(table.string).should eq(normalize_table_output(load_golden("TestInnerBordersOnly.golden")))
  end

  it "renders empty table from new" do
    Table.new.string.should eq("")
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

  it "renders y offset with fixed height" do
    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
      .row("Chinese", "Nǐn hǎo", "Nǐ hǎo")
      .row("French", "Bonjour", "Salut")
      .row("Japanese", "こんにちは", "やあ")
      .row("Russian", "Zdravstvuyte", "Privet")
      .row("Spanish", "Hola", "¿Qué tal?")
      .y_offset(1)
      .height(8)

    table.string.should eq(load_golden("TestTableHeightWithOffset.golden"))
  end

  it "renders width shrink with no borders" do
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
    table.border_left = false
    table.border_right = false
    table.border_column = false
    add_rows(table, rows.map(&.to_a))

    table.string.should eq(load_golden("TestTableWidthShrinkNoBorders.golden"))
  end

  it "renders table widths parity case" do
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
    table.border_left = false
    table.border_right = false
    table.border_column = false
    add_rows(table, rows.map(&.to_a))

    table.string.should eq(load_golden("TestTableWidths.golden"))
  end

  it "renders ansi content correctly" do
    code = "\e[31mC\e[0m\e[32mo\e[0m\e[34md\e[0m\e[33me\e[0m"
    rows = [
      {"Apple", "Red", "\e[31m31\e[0m"},
      {"Lime", "Green", "\e[32m32\e[0m"},
      {"Banana", "Yellow", "\e[33m33\e[0m"},
      {"Blueberry", "Blue", "\e[34m34\e[0m"},
    ]

    table = Table.new
      .width(29)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .border(Lipgloss::Border.normal)
      .headers("Fruit", "Color", code)
    add_rows(table, rows.map(&.to_a))

    table.string.should eq(load_golden("TestTableANSI.golden"))
  end

  it "renders exact and extra heights" do
    exact = Table.new
      .height(9)
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
      .row("Chinese", "Nǐn hǎo", "Nǐ hǎo")
      .row("French", "Bonjour", "Salut")
      .row("Japanese", "こんにちは", "やあ")
      .row("Russian", "Zdravstvuyte", "Privet")
      .row("Spanish", "Hola", "¿Qué tal?")
    exact.string.should eq(load_golden("TestTableHeightExact.golden"))

    extra = Table.new
      .height(100)
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
      .row("Chinese", "Nǐn hǎo", "Nǐ hǎo")
      .row("French", "Bonjour", "Salut")
      .row("Japanese", "こんにちは", "やあ")
      .row("Russian", "Zdravstvuyte", "Privet")
      .row("Spanish", "Hola", "¿Qué tal?")
    extra.string.should eq(load_golden("TestTableHeightExtra.golden"))
  end

  it "clear_rows resets data without raising" do
    table = Table.new
      .border(Lipgloss::Border.normal)
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
      .row("Chinese", "Nǐn hǎo", "Nǐ hǎo")
    table.clear_rows
    table.row("French", "Bonjour", "Salut")

    output = table.string
    output.includes?("French").should be_true
    output.includes?("Chinese").should be_false
  end

  it "renders table heights scenario" do
    style_func = ->(row : Int32, col : Int32) {
      if row == Lipgloss::StyleTable::HEADER_ROW
        Lipgloss::Style.new.padding(0, 1)
      elsif col == 0
        Lipgloss::Style.new.width(18).padding(1)
      else
        Lipgloss::Style.new.width(25).padding(1, 2)
      end
    }

    rows = [
      {"Chutar o balde", "Literally translates to \"kick the bucket.\" It's used when someone gives up or loses patience."},
      {"Engolir sapos", "Literally means \"to swallow frogs.\" It's used to describe someone who has to tolerate or endure unpleasant situations."},
      {"Arroz de festa", "Literally means \"party rice.\" It´s used to refer to someone who shows up everywhere."},
    ]

    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(style_func)
      .headers("EXPRESSION", "MEANING")
    add_rows(table, rows.map(&.to_a))

    table.string.should eq(load_golden("TestTableHeights.golden"))
  end

  it "renders multiline row separator scenario" do
    style_func = ->(row : Int32, col : Int32) {
      if row == Lipgloss::StyleTable::HEADER_ROW
        Lipgloss::Style.new.padding(0, 1)
      elsif col == 0
        Lipgloss::Style.new.width(18).padding(1)
      else
        Lipgloss::Style.new.width(25).padding(1, 2)
      end
    }

    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(style_func)
      .headers("EXPRESSION", "MEANING")
      .row("Chutar o balde", "Literally translates to \"kick the bucket.\" It's used when someone gives up or loses patience.")
      .row("Engolir sapos", "Literally means \"to swallow frogs.\" It's used to describe someone who has to tolerate or endure unpleasant situations.")
      .row("Arroz de festa", "Literally means \"party rice.\" It´s used to refer to someone who shows up everywhere.")
    table.border_row = true

    table.string.should eq(load_golden("TestTableMultiLineRowSeparator.golden"))
  end

  it "renders style func variants" do
    common_rows = [
      {"Chinese", "Nǐn hǎo", "Nǐ hǎo"},
      {"French", "Bonjour", "Salut"},
      {"Japanese", "こんにちは", "やあ"},
      {"Russian", "Zdravstvuyte", "Privet"},
      {"Spanish", "Hola", "¿Qué tal?"},
    ]

    right_aligned = ->(row : Int32, _col : Int32) {
      if row == Lipgloss::StyleTable::HEADER_ROW
        Lipgloss::Style.new.align(Lipgloss::Position::Center)
      else
        Lipgloss::Style.new.margin(0, 1).align(Lipgloss::Position::Right)
      end
    }
    table1 = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(right_aligned)
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
    add_rows(table1, common_rows.map(&.to_a))
    table1.string.should eq(load_golden("TestStyleFunc", "RightAlignedTextWithMargins.golden"))

    margin_padding = ->(row : Int32, _col : Int32) {
      if row == Lipgloss::StyleTable::HEADER_ROW
        Lipgloss::Style.new.align(Lipgloss::Position::Center)
      else
        Lipgloss::Style.new.padding(1).margin(1).align(Lipgloss::Position::Right).background(Lipgloss::Color.from_hex("#874bfc"))
      end
    }
    table2 = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(margin_padding)
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
    add_rows(table2, common_rows.map(&.to_a))
    Lipgloss::Text.strip_ansi(table2.string).should eq(Lipgloss::Text.strip_ansi(load_golden("TestStyleFunc", "MarginAndPaddingSet.golden")))
  end

  it "handles carriage return content" do
    data = [
      {"a0", "b0", "c0", "d0"},
      {"a1", "b1.0\r\nb1.1\r\nb1.2\r\nb1.3\r\nb1.4\r\nb1.5\r\nb1.6", "c1", "d1"},
      {"a2", "b2", "c2", "d2"},
      {"a3", "b3", "c3", "d3"},
    ]

    table = Table.new.border(Lipgloss::Border.normal)
    add_rows(table, data.map(&.to_a))

    table.string.should eq(load_golden("TestCarriageReturn.golden"))
  end

  it "wraps pre-styled content without overflow" do
    headers = {"Package", "Version", "Link"}
    styled_link = Lipgloss.join_horizontal(
      Lipgloss::Position::Left,
      Lipgloss::Style.new.foreground(Lipgloss::Color.from_hex("#31BB71")).render("https://aur.archlinux.org/packages/sourcegit-bin")
    )
    data = [
      {"sourcegit", "0.19", styled_link},
      [] of String,
      {"Welcome", "いらっしゃいませ", "مرحباً", "환영", "欢迎"},
      {"Goodbye", "さようなら", "مع السلامة", "안녕히 가세요", "再见"},
    ]

    table = Table.new
      .headers(*headers)
      .width(80)
      .wrap(true)
    add_rows(table, data.map(&.to_a))

    normalize_table_output(Lipgloss::Text.strip_ansi(table.string)).should eq(
      normalize_table_output(Lipgloss::Text.strip_ansi(load_golden("TestWrapPreStyledContent.golden")))
    )
  end

  it "wraps style-func content without overflow" do
    headers = {"Package", "Version", "Link"}
    data = [
      {"sourcegit", "0.19", "https://aur.archlinux.org/packages/sourcegit-bin"},
      {"Welcome", "いらっしゃいませ", "مرحباً"},
      {"Goodbye", "さようなら", "مع السلامة"},
    ]

    table = Table.new
      .headers(*headers)
      .style_func(->(row : Int32, col : Int32) {
        if row == Lipgloss::StyleTable::HEADER_ROW
          Lipgloss::Style.new
        elsif data[row][col].includes?("https://")
          Lipgloss::Style.new.foreground(Lipgloss::Color.from_hex("#31BB71"))
        else
          Lipgloss::Style.new
        end
      })
      .width(60)
      .wrap(true)
    add_rows(table, data.map(&.to_a))

    normalize_table_output(Lipgloss::Text.strip_ansi(table.string)).should eq(
      normalize_table_output(Lipgloss::Text.strip_ansi(load_golden("TestWrapStyleFuncContent.golden")))
    )
  end

  it "renders filtered table" do
    data = StringData.new
      .item("Chinese", "Nǐn hǎo", "Nǐ hǎo")
      .item("French", "Bonjour", "Salut")
      .item("Japanese", "こんにちは", "やあ")
      .item("Russian", "Zdravstvuyte", "Privet")
      .item("Spanish", "Hola", "¿Qué tal?")

    filter = Filter.new(data).filter { |row| data.at(row, 0) != "French" }

    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
      .data(filter)

    table.string.should eq(load_golden("TestFilter.golden"))
  end

  it "renders inverse filtered table" do
    data = StringData.new
      .item("Chinese", "Nǐn hǎo", "Nǐ hǎo")
      .item("French", "Bonjour", "Salut")
      .item("Japanese", "こんにちは", "やあ")
      .item("Russian", "Zdravstvuyte", "Privet")
      .item("Spanish", "Hola", "¿Qué tal?")

    filter = Filter.new(data).filter { |row| data.at(row, 0) == "French" }

    table = Table.new
      .border(Lipgloss::Border.normal)
      .style_func(->(r : Int32, c : Int32) { table_style(r, c) })
      .headers("LANGUAGE", "FORMAL", "INFORMAL")
      .data(filter)

    table.string.should eq(load_golden("TestFilterInverse.golden"))
  end
end
