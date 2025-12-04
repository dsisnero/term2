require "../spec_helper"
require "../../src/components/progress"

describe Term2::Components::Progress do
  it "renders gradient and scaled gradient matching edge colors" do
    col_a = "#FF0000"
    col_b = "#00FF00"

    [false, true].each do |scale|
      opts_progress = scale ? Term2::Components::Progress.with_scaled_gradient(col_a, col_b) : Term2::Components::Progress.with_gradient(col_a, col_b)
      opts_progress.width = 10
      opts_progress.show_percentage = false

      [3, 5, 50].each do |w|
        opts_progress.width = w
        bar = opts_progress.view_as(1.0)

        colors = bar.split(opts_progress.full_char.to_s + "\e[0m")
        colors = colors[0...-1] # last split empty

        first = colors.first
        last = colors.last

        first.should contain("\e[38;2;255,0,0m")
        last.should contain("\e[38;2;0,255,0m")
      end
    end
  end
end
