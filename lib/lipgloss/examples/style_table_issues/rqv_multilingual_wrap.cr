require "../../src/lipgloss"

alias Table = Lipgloss::StyleTable::Table

headers = {"Package", "Version", "Link"}
rows = [
  {"sourcegit", "0.19", "https://aur.archlinux.org/packages/sourcegit-bin"},
  {"Welcome", "いらっしゃいませ", "مرحباً"},
  {"Goodbye", "さようなら", "مع السلامة"},
]

table = Table.new
  .headers(*headers)
  .style_func(->(row : Int32, col : Int32) {
    if row == Lipgloss::StyleTable::HEADER_ROW
      Lipgloss::Style.new
    elsif rows[row][col].includes?("https://")
      Lipgloss::Style.new.foreground(Lipgloss::Color.from_hex("#31BB71"))
    else
      Lipgloss::Style.new
    end
  })
  .width(60)
  .wrap(true)

rows.each { |row| table.row(row) }
puts table.string
