require "../../src/term2"

module LibglossStyles
  NORMAL     = Lipgloss::Color.hex("#EEEEEE")
  SUBTLE     = Lipgloss::Color.hex("#D9DCCF")
  HIGHLIGHT  = Lipgloss::Color.hex("#874BFD")
  SPECIAL    = Lipgloss::Color.hex("#43BF6D")
  BACKGROUND = Lipgloss::Color.hex("#1C1C1C")
  ACCENT     = Lipgloss::Color.hex("#FF5F87")

  DOC_STYLE = Lipgloss::Style.new
    .padding(1, 2, 1, 2)
    .background(BACKGROUND)

  def self.tab(label : String, active : Bool)
    style = Lipgloss::Style.new
      .border(Lipgloss::Border.normal, true)
      .padding(0, 2)
      .foreground(NORMAL)
      .border_foreground(active ? HIGHLIGHT : SUBTLE)
    style.render(label)
  end

  def self.panel(width : Int32, title : String, content : String)
    Lipgloss::Style.new
      .border(Lipgloss::Border.rounded)
      .padding(0, 1)
      .width(width)
      .foreground(NORMAL)
      .background(SUBTLE)
      .render("#{title}\n#{content}")
  end

  def self.list_item(text : String, selected : Bool)
    style = Lipgloss::Style.new
      .padding(0, 1)
      .width(30)
      .border(Lipgloss::Border.normal, true)
      .border_foreground(selected ? HIGHLIGHT : SUBTLE)
      .foreground(selected ? HIGHLIGHT : NORMAL)
    style.render(text)
  end

  def self.table_row(values : Array(String), widths : Array(Int32), header : Bool = false) : String
    cells = values.each_with_index.map do |value, idx|
      width = widths[idx] || value.size.to_i32
      content = value.ljust(width)
      style = Lipgloss::Style.new
        .padding(0, 1)
        .foreground(header ? ACCENT : NORMAL)
      style.render(content)
    end
    cells.join("│")
  end

  def self.history_entry(text : String, width : Int32)
    Lipgloss::Style.new
      .border(Lipgloss::Border.normal)
      .padding(0, 1)
      .width(width)
      .foreground(NORMAL)
      .background(SUBTLE)
      .render(text)
  end
end
