require "../../src/lipgloss"

alias Table = Lipgloss::StyleTable::Table

style_func = ->(row : Int32, col : Int32) do
  if row == Lipgloss::StyleTable::HEADER_ROW
    Lipgloss::Style.new.padding(0, 1)
  elsif col == 0
    Lipgloss::Style.new.width(18).padding(1)
  else
    Lipgloss::Style.new.width(25).padding(1, 2)
  end
end

table = Table.new
  .border(Lipgloss::Border.normal)
  .style_func(style_func)
  .headers("EXPRESSION", "MEANING")
  .row("Chutar o balde", "Literally translates to \"kick the bucket.\" It's used when someone gives up or loses patience.")
  .row("Engolir sapos", "Literally means \"to swallow frogs.\" It's used to describe someone who has to tolerate or endure unpleasant situations.")
  .row("Arroz de festa", "Literally means \"party rice.\" It´s used to refer to someone who shows up everywhere.")

puts table.string
