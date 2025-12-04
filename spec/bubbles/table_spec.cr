require "../spec_helper"
require "../../src/components/table"

def golden(name)
  File.read(File.join("bubbles", "table", "testdata", "TestModel_View", "#{name}.golden"))
end

def golden_alignment(name)
  File.read(File.join("bubbles", "table", "testdata", "TestTableAlignment", "#{name}.golden"))
end

TEST_COLS = [
  Term2::Components::Table::Column.new("col1", 10),
  Term2::Components::Table::Column.new("col2", 10),
  Term2::Components::Table::Column.new("col3", 10),
] of Term2::Components::Table::Column

describe Term2::Components::Table do
  it "renders rows with truncation and padding like bubbles" do
    tests = [
      {
        name:  "simple row",
        table: Term2::Components::Table.new(
          TEST_COLS,
          [["Foooooo", "Baaaaar", "Baaaaaz"]],
          0,
          0
        ).tap(&.cell_style=(Term2::Style.new)),
        expected: "Foooooo   Baaaaar   Baaaaaz   ",
      },
      {
        name:  "simple row with truncations",
        table: Term2::Components::Table.new(
          TEST_COLS,
          [["Foooooooooo", "Baaaaaaaaar", "Quuuuuuuuux"]],
          0,
          0
        ).tap(&.cell_style=(Term2::Style.new)),
        expected: "Foooooooo…Baaaaaaaa…Quuuuuuuu…",
      },
      {
        name:  "simple row avoiding truncations",
        table: Term2::Components::Table.new(
          TEST_COLS,
          [["Fooooooooo", "Baaaaaaaar", "Quuuuuuuux"]],
          0,
          0
        ).tap(&.cell_style=(Term2::Style.new)),
        expected: "FoooooooooBaaaaaaaarQuuuuuuuux",
      },
    ]

    tests.each do |tc|
      row = tc[:table].render_row(tc[:table].rows[0], 0, false)
      row.should eq tc[:expected]
    end
  end

  it "aligns table with and without borders" do
    biscuits = Term2::Components::Table.build(
      Term2::Components::Table.with_height(5),
      Term2::Components::Table.with_columns([
        Term2::Components::Table::Column.new("Name", 25),
        Term2::Components::Table::Column.new("Country of Origin", 16),
        Term2::Components::Table::Column.new("Dunk-able", 12),
      ]),
      Term2::Components::Table.with_rows([
        ["Chocolate Digestives", "UK", "Yes"],
        ["Tim Tams", "Australia", "No"],
        ["Hobnobs", "UK", "Yes"],
      ])
    )

    biscuits.view.should eq golden_alignment("No_border")

    # wrap in a simple border (replicating baseStyle border in Go test)
    lines = biscuits.view.split("\n")
    sep = "─" * (lines.first? ? lines.first.size : 0)
    view_with_sep = ([lines[0], sep] + lines[1..]).join("\n")

    bordered = add_border(view_with_sep)
    bordered.should eq golden_alignment("With_border")
  end

  it "supports cursor navigation" do
    tests = {
      "New"                         => {rows: [%w[r1], %w[r2], %w[r3]], action: ->(_t : Term2::Components::Table) { }, want: 0},
      "MoveDown"                    => {rows: [%w[r1], %w[r2], %w[r3], %w[r4]], action: ->(t : Term2::Components::Table) { t.move_down(2) }, want: 2},
      "MoveUp"                      => {rows: [%w[r1], %w[r2], %w[r3], %w[r4]], action: ->(t : Term2::Components::Table) { t.cursor = 3; t.move_up(2) }, want: 1},
      "GotoBottom"                  => {rows: [%w[r1], %w[r2], %w[r3], %w[r4]], action: ->(t : Term2::Components::Table) { t.goto_bottom }, want: 3},
      "GotoTop"                     => {rows: [%w[r1], %w[r2], %w[r3], %w[r4]], action: ->(t : Term2::Components::Table) { t.cursor = 3; t.goto_top }, want: 0},
      "SetCursor"                   => {rows: [%w[r1], %w[r2], %w[r3], %w[r4]], action: ->(t : Term2::Components::Table) { t.set_cursor(2) }, want: 2},
      "MoveDown overflow"           => {rows: [%w[r1], %w[r2], %w[r3], %w[r4]], action: ->(t : Term2::Components::Table) { t.move_down(5) }, want: 3},
      "MoveUp overflow"             => {rows: [%w[r1], %w[r2], %w[r3], %w[r4]], action: ->(t : Term2::Components::Table) { t.cursor = 3; t.move_up(5) }, want: 0},
      "Blur does not stop movement" => {rows: [%w[r1], %w[r2], %w[r3], %w[r4]], action: ->(t : Term2::Components::Table) { t.blur; t.move_down(2) }, want: 2},
    }

    tests.each do |_, tc|
      table = Term2::Components::Table.build(Term2::Components::Table.with_columns(TEST_COLS), Term2::Components::Table.with_rows(tc[:rows]))
      tc[:action].call(table)
      table.cursor.should eq tc[:want]
    end
  end

  it "sets rows and columns" do
    table = Term2::Components::Table.build(Term2::Components::Table.with_columns(TEST_COLS))
    table.rows.size.should eq 0
    table.rows = [%w[r1], %w[r2]]
    table.rows.size.should eq 2
    table.rows.should eq [%w[r1], %w[r2]]

    table = Term2::Components::Table.new
    table.columns.size.should eq 0
    table.columns = [Term2::Components::Table::Column.new("Foo", 0), Term2::Components::Table::Column.new("Bar", 0)]
    table.columns.map(&.title).should eq ["Foo", "Bar"]
  end

  it "renders views matching golden fixtures" do
    tests = {
      "Empty" => -> {
        Term2::Components::Table.new
      },
      "Single_row_and_column" => -> {
        Term2::Components::Table.build(
          Term2::Components::Table.with_columns([Term2::Components::Table::Column.new("Name", 25)]),
          Term2::Components::Table.with_rows([["Chocolate Digestives"]])
        )
      },
      "Multiple_rows_and_columns" => -> {
        Term2::Components::Table.build(
          Term2::Components::Table.with_columns([
            Term2::Components::Table::Column.new("Name", 25),
            Term2::Components::Table::Column.new("Country of Origin", 16),
            Term2::Components::Table::Column.new("Dunk-able", 12),
          ]),
          Term2::Components::Table.with_rows([
            ["Chocolate Digestives", "UK", "Yes"],
            ["Tim Tams", "Australia", "No"],
            ["Hobnobs", "UK", "Yes"],
          ])
        )
      },
      "Extra_padding" => -> {
        styles = Term2::Components::Table::Styles.new(
          header: Term2::Style.new.padding(2, 2),
          cell: Term2::Style.new.padding(2, 2),
          selected: Term2::Style.new
        )
        Term2::Components::Table.build(
          Term2::Components::Table.with_height(10),
          Term2::Components::Table.with_columns([
            Term2::Components::Table::Column.new("Name", 25),
            Term2::Components::Table::Column.new("Country of Origin", 16),
            Term2::Components::Table::Column.new("Dunk-able", 12),
          ]),
          Term2::Components::Table.with_rows([
            ["Chocolate Digestives", "UK", "Yes"],
            ["Tim Tams", "Australia", "No"],
            ["Hobnobs", "UK", "Yes"],
          ]),
          Term2::Components::Table.with_styles(styles)
        )
      },
      "No_padding" => -> {
        styles = Term2::Components::Table::Styles.new(
          header: Term2::Style.new,
          cell: Term2::Style.new,
          selected: Term2::Style.new
        )
        Term2::Components::Table.build(
          Term2::Components::Table.with_height(10),
          Term2::Components::Table.with_columns([
            Term2::Components::Table::Column.new("Name", 25),
            Term2::Components::Table::Column.new("Country of Origin", 16),
            Term2::Components::Table::Column.new("Dunk-able", 12),
          ]),
          Term2::Components::Table.with_rows([
            ["Chocolate Digestives", "UK", "Yes"],
            ["Tim Tams", "Australia", "No"],
            ["Hobnobs", "UK", "Yes"],
          ]),
          Term2::Components::Table.with_styles(styles)
        )
      },
      "Bordered_headers" => -> {
        styles = Term2::Components::Table::Styles.new(
          header: Term2::Style.new.border(Term2::Border.normal),
          cell: Term2::Style.new,
          selected: Term2::Style.new
        )
        Term2::Components::Table.build(
          Term2::Components::Table.with_columns([
            Term2::Components::Table::Column.new("Name", 25),
            Term2::Components::Table::Column.new("Country of Origin", 16),
            Term2::Components::Table::Column.new("Dunk-able", 12),
          ]),
          Term2::Components::Table.with_rows([
            ["Chocolate Digestives", "UK", "Yes"],
            ["Tim Tams", "Australia", "No"],
            ["Hobnobs", "UK", "Yes"],
          ]),
          Term2::Components::Table.with_styles(styles)
        )
      },
      "Bordered_cells" => -> {
        styles = Term2::Components::Table::Styles.new(
          header: Term2::Style.new,
          cell: Term2::Style.new.border(Term2::Border.normal),
          selected: Term2::Style.new
        )
        Term2::Components::Table.build(
          Term2::Components::Table.with_columns([
            Term2::Components::Table::Column.new("Name", 25),
            Term2::Components::Table::Column.new("Country of Origin", 16),
            Term2::Components::Table::Column.new("Dunk-able", 12),
          ]),
          Term2::Components::Table.with_rows([
            ["Chocolate Digestives", "UK", "Yes"],
            ["Tim Tams", "Australia", "No"],
            ["Hobnobs", "UK", "Yes"],
          ]),
          Term2::Components::Table.with_styles(styles)
        )
      },
      "Manual_height_greater_than_rows" => -> {
        Term2::Components::Table.build(
          Term2::Components::Table.with_height(6),
          Term2::Components::Table.with_columns([
            Term2::Components::Table::Column.new("Name", 25),
            Term2::Components::Table::Column.new("Country of Origin", 16),
            Term2::Components::Table::Column.new("Dunk-able", 12),
          ]),
          Term2::Components::Table.with_rows([
            ["Chocolate Digestives", "UK", "Yes"],
            ["Tim Tams", "Australia", "No"],
            ["Hobnobs", "UK", "Yes"],
          ])
        )
      },
      "Manual_height_less_than_rows" => -> {
        Term2::Components::Table.build(
          Term2::Components::Table.with_height(2),
          Term2::Components::Table.with_columns([
            Term2::Components::Table::Column.new("Name", 25),
            Term2::Components::Table::Column.new("Country of Origin", 16),
            Term2::Components::Table::Column.new("Dunk-able", 12),
          ]),
          Term2::Components::Table.with_rows([
            ["Chocolate Digestives", "UK", "Yes"],
            ["Tim Tams", "Australia", "No"],
            ["Hobnobs", "UK", "Yes"],
          ])
        )
      },
      "Manual_width_greater_than_columns" => -> {
        Term2::Components::Table.build(
          Term2::Components::Table.with_width(80),
          Term2::Components::Table.with_columns([
            Term2::Components::Table::Column.new("Name", 25),
            Term2::Components::Table::Column.new("Country of Origin", 16),
            Term2::Components::Table::Column.new("Dunk-able", 12),
          ]),
          Term2::Components::Table.with_rows([
            ["Chocolate Digestives", "UK", "Yes"],
            ["Tim Tams", "Australia", "No"],
            ["Hobnobs", "UK", "Yes"],
          ])
        )
      },
      "Modified_viewport_height" => -> {
        m = Term2::Components::Table.build(
          Term2::Components::Table.with_columns([
            Term2::Components::Table::Column.new("Name", 25),
            Term2::Components::Table::Column.new("Country of Origin", 16),
            Term2::Components::Table::Column.new("Dunk-able", 12),
          ]),
          Term2::Components::Table.with_rows([
            ["Chocolate Digestives", "UK", "Yes"],
            ["Tim Tams", "Australia", "No"],
            ["Hobnobs", "UK", "Yes"],
          ])
        )
        m.viewport.height = 2
        m.update_viewport
        m
      },
    }

    tests.each do |name, build|
      table = build.call
      table_view = table.view
      if table_view != golden(name)
        puts "Mismatch for #{name}"
      end
      table_view.should eq golden(name)
    end
  end
end

def add_border(view : String) : String
  lines = view.split("\n")
  width = lines.max_of(&.size) || 0
  top = "┌" + ("─" * width) + "┐"
  bottom = "└" + ("─" * width) + "┘"
  body = lines.map { |line| "│#{line.ljust(width)}│" }
  ([top] + body + [bottom]).join("\n")
end
