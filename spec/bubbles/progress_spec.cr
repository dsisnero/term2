require "../spec_helper"
require "../../src/components/progress"

describe Term2::Components::Progress do
  it "renders default bar" do
    p = Term2::Components::Progress.new
    p.width = 10
    p.show_percentage = false
    # 50% of 10 chars = 5 chars full, 5 chars empty
    Lipgloss::Text.strip_ansi(p.view_as(0.5)).should contain("█████░░░░░")
  end

  it "renders with percentage" do
    p = Term2::Components::Progress.new
    p.width = 20
    p.show_percentage = true
    # " 50%" is 4 chars. Bar width = 16.
    # 50% of 16 = 8 full.
    output = p.view_as(0.5)
    output.should contain(" 50%")
    # Check for correct bar length
    ansi_stripped = Lipgloss::Text.strip_ansi(output)
    ansi_stripped.size.should eq 20
  end

  it "renders solid color" do
    p = Term2::Components::Progress.new([
      Term2::Components::Progress.with_solid_fill("#ff0000"),
      Term2::Components::Progress.without_percentage,
    ])
    p.width = 10
    output = p.view_as(0.5)
    # Just verify it renders
    output.should contain("█████")
  end

  it "renders gradient" do
    col_a = "#5A56E0"
    col_b = "#EE6FF8"

    [true, false].each do |scale|
      # Correctly creating the option proc
      option = scale ? Term2::Components::Progress.with_scaled_gradient(col_a, col_b) : Term2::Components::Progress.with_gradient(col_a, col_b)

      # Correctly instantiating the model with the option
      p = Term2::Components::Progress.new([option])
      p.width = 10
      p.show_percentage = false

      output = p.view_as(0.5)
      output.size.should be > 10 # Should contain ANSI escape codes
    end
  end
end
