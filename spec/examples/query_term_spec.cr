ENV["TERM2_REQUIRE_ONLY"] = "1"
ENV["COLORTERM"] = ""
ENV["TERM"] = "ansi"
require "../spec_helper"
require "teatest"
require "../../examples/bubbletea/query-term/main"

describe "Example: query-term" do
  it "matches the Go output" do
    Lipgloss::StyleRenderer.default.color_profile = Lipgloss::ColorProfile::ANSI
    model = QueryTermExample::Model.new
    view = model.view
    output = view.is_a?(String) ? view : view.content
    output = output.gsub("\e[0m", "\e[m")
    Teatest.require_equal_output("QueryTerm/default", output.to_slice)
  end
end
