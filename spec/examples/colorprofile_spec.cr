ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "teatest"
require "../../examples/bubbletea/colorprofile/main"

describe "Example: colorprofile" do
  it "matches the Go output" do
    prev_renderer = Lipgloss::StyleRenderer.default
    truecolor_renderer = Lipgloss::StyleRenderer.new
    truecolor_renderer.color_profile = Lipgloss::ColorProfile::TrueColor
    Lipgloss::StyleRenderer.default = truecolor_renderer

    begin
      model = ColorProfileExample::Model.new
      view = model.view
      output = view.is_a?(String) ? view : view.content
      output = output.gsub("\e[0m", "\e[m")

      Teatest.require_equal_output("ColorProfile/default", output.to_slice)
    ensure
      Lipgloss::StyleRenderer.default = prev_renderer
    end
  end
end
