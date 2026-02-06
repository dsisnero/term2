require "../spec_helper"
require "../../src/components/table"

describe Term2::Components::Table do
  it "initializes with data" do
    cols = [
      Term2::Components::Table::Column.new("ID", 5),
      Term2::Components::Table::Column.new("Name", 10),
    ]
    rows = [
      ["1", "Alice"],
      ["2", "Bob"],
    ]

    table = Term2::Components::Table.new(cols, rows)
    table.rows.size.should eq 2
    table.columns.size.should eq 2
  end

  it "initializes with DSL" do
    table = Term2::Components::Table.new(width: 50, height: 10) do |tbl|
      tbl.column "ID", 5
      tbl.column "Name", 10
      tbl.row "1", "Alice"
      tbl.row "2", "Bob"
    end

    table.columns.size.should eq 2
    table.rows.size.should eq 2
    table.columns[0].title.should eq "ID"
    table.rows[0][1].should eq "Alice"
  end

  it "initializes with tuples and arrays" do
    table = Term2::Components::Table.new(
      columns: [{"ID", 5}, {"Name", 10}],
      rows: [["1", "Alice"], ["2", "Bob"]]
    )

    table.columns.size.should eq 2
    table.rows.size.should eq 2
    table.columns[0].title.should eq "ID"
    table.rows[0][1].should eq "Alice"
  end

  it "navigates" do
    cols = [Term2::Components::Table::Column.new("ID", 5)]
    rows = [["1"], ["2"], ["3"]]
    table = Term2::Components::Table.new(cols, rows)
    table.focus

    table.cursor.should eq 0

    # Down
    msg = Term2::KeyMsg.new(Term2::Key.new("down"))
    table, _ = table.update(msg)
    table.cursor.should eq 1

    # End
    msg = Term2::KeyMsg.new(Term2::Key.new("end"))
    table, _ = table.update(msg)
    table.cursor.should eq 2

    # Up
    msg = Term2::KeyMsg.new(Term2::Key.new("up"))
    table, _ = table.update(msg)
    table.cursor.should eq 1
  end

  it "renders" do
    cols = [
      Term2::Components::Table::Column.new("ID", 5),
      Term2::Components::Table::Column.new("Name", 10),
    ]
    rows = [
      ["1", "Alice"],
      ["2", "Bob"],
    ]

    table = Term2::Components::Table.new(cols, rows)
    table.focus

    view = table.view.content

    plain = Lipgloss::Text.strip_ansi(view)

    # Header
    plain.should contain "ID"
    plain.should contain "Name"

    # Rows
    plain.should contain "1"
    plain.should contain "Alice"
    plain.should contain "2"
    plain.should contain "Bob"

    # Selection style (reverse video)
    # First row is selected
    # "1    Alice     "
    # Should be wrapped in reverse style
    # We can check for ANSI codes if we knew exact format, but checking content is good start.
  end

  it "filters rows with fuzzy search" do
    cols = [
      Term2::Components::Table::Column.new("ID", 5),
      Term2::Components::Table::Column.new("Name", 10),
    ]
    rows = [
      ["1", "Alice"],
      ["2", "Bob"],
      ["3", "Alicia"],
    ]

    table = Term2::Components::Table::FilteredTable.new(cols, rows)
    table.filter_text = "alic"

    table.visible_rows.size.should eq 2
    table.visible_rows[0][1].should contain "Ali"
    Lipgloss::Text.strip_ansi(table.view.content).should contain "Alice"
    Lipgloss::Text.strip_ansi(table.view.content).should contain "Alicia"
    Lipgloss::Text.strip_ansi(table.view.content).should_not contain "Bob"
  end
end
