require "../../../src/term2"

include Term2::Prelude

module AdvancedLayout
  def self.cell(title : String, content : String, width : Int32 = 24, height : Int32 = 8) : String
    top = "┌" + "─" * (width - 2) + "┐"
    bottom = "└" + "─" * (width - 2) + "┘"
    separator = "├" + "─" * (width - 2) + "┤"

    body_lines = content.lines.map(&.strip)
    body_height = height - 4

    String.build do |io|
      io << top << "\n"
      io << "│" << center_text("##{title}", width - 2) << "│\n"
      io << separator << "\n"

      body_lines.each { |line| io << "│" << center_text(line, width - 2) << "│\n" }
      (body_height - body_lines.size).times { io << "│" << " " * (width - 2) << "│\n" }

      io << bottom
    end
  end

  def self.center_text(text : String, width : Int32) : String
    padding = [width - text.size, 0].max
    left = (padding / 2).to_i32
    right = (padding - left).to_i32
    " " * left.to_i32 + text + " " * right.to_i32
  end

  def self.join_columns(blocks : Array(String)) : String
    return "" if blocks.empty?
    result = blocks.first
    remaining = blocks[1..-1]
    if remaining
      remaining.each do |blk|
        result = Term2.join_horizontal(Term2::Position::Top, result, blk)
      end
    end
    result
  end

  def self.grid_layout(items : Array(Tuple(String, String)), columns : Int32, width : Int32 = 26, height : Int32 = 9) : String
    rows = [] of String
    row = [] of String
    items.each do |title, content|
      row << cell(title, content, width, height)
      if row.size == columns
        rows << join_columns(row)
        row = [] of String
      end
    end
    rows << join_columns(row) unless row.empty?
    rows.join("\n\n")
  end

  def self.title_block
    stripes = ["Lipgloss Advanced Layout Examples", "=" * 64].join("\n")
    Term2::Style.new.bold(true).fg_hex("#F25D94").render(stripes)
  end
end

class AdvancedLayoutModel
  include Model

  def init : Cmd
    Cmds.none
  end

  def update(msg : Message) : {Model, Cmd}
    if msg.is_a?(KeyMsg) && ["q", "ctrl+c"].includes?(msg.key.to_s)
      {self, Term2.quit}
    else
      {self, Cmds.none}
    end
  end

  def view : String
    grid_items = [
      {"1", "Item One"},
      {"2", "Item Two with\nmultiple lines"},
      {"3", "Three"},
      {"4", "Four"},
      {"5", "Five"},
      {"6", "Six"},
      {"7", "Seven"},
      {"8", "Eight"},
      {"9", "Nine"},
    ]

    sections = [
      AdvancedLayout.title_block,
      "",
      "Example 1: Grid Layout (3x3)",
      AdvancedLayout.grid_layout(grid_items, 3),
      "",
      "Example 2: Responsive Highlights",
      "  • Layouts respond to terminal width automatically",
      "  • Tabs and panels are arranged in columns",
      "",
      "Example 3: Dialog and Status",
      "  - Dialog sits centered with action buttons",
      "  - Status bar reports health at the bottom",
      "",
      "Press q or ctrl+c to exit.",
    ]

    sections.join("\n")
  end
end

Term2.run(AdvancedLayoutModel.new)
