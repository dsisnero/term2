ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "teatest"
require "../../examples/bubbletea/capability/main"

describe "Example: capability" do
  it "matches the Go output" do
    prev_renderer = Lipgloss::StyleRenderer.default
    ansi_renderer = Lipgloss::StyleRenderer.new
    ansi_renderer.color_profile = Lipgloss::ColorProfile::ANSI
    Lipgloss::StyleRenderer.default = ansi_renderer

    begin
      model = CapabilityExample::Model.new
      model, _ = model.update(Term2::UV::WindowSizeEvent.new(80, 24))

      view = model.view
      output = view.is_a?(String) ? view : view.content
      output = output.gsub("\e[0m", "\e[m")

      Teatest.require_equal_output("Capability/default", output.to_slice)
    ensure
      Lipgloss::StyleRenderer.default = prev_renderer
    end
  end
end
