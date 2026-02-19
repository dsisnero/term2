require "./spec_helper"

describe "Lipgloss parity: Canvas" do
  it "renders drawn content" do
    canvas = Lipgloss::Canvas.new(5, 3)

    (0...canvas.height).each do |y|
      (0...canvas.width).each do |x|
        canvas.set_cell(x, y, Lipgloss::Cell.new("."))
      end
    end

    (1...2).each do |y|
      (1...4).each do |x|
        canvas.set_cell(x, y, Lipgloss::Cell.new("#"))
      end
    end

    expected = [
      ".....",
      ".###.",
      ".....",
    ].join("\n")

    canvas.render.should eq(expected)
  end

  it "trims trailing spaces on render" do
    canvas = Lipgloss::Canvas.new(5, 2)

    (0...canvas.height).each do |y|
      (0...canvas.width).each do |x|
        content = x < 3 ? "A" : " "
        canvas.set_cell(x, y, Lipgloss::Cell.new(content))
      end
    end

    expected = [
      "AAA",
      "AAA",
    ].join("\n")

    canvas.render.should eq(expected)
  end

  it "updates canvas when mutating a cell returned from cell_at" do
    canvas = Lipgloss::Canvas.new(4, 1)
    cell = canvas.cell_at(1, 0)
    cell.content = "X"

    canvas.render.should eq(" X")
  end
end
