ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "teatest"
require "../../examples/bubbletea/keyboard-enhancements/main"

describe "Example: keyboard-enhancements" do
  it "matches the Go output" do
    model = KeyboardEnhancementsExample::Model.new
    view = model.view
    output = view.is_a?(String) ? view : view.content
    Teatest.require_equal_output("KeyboardEnhancements/default", output.to_slice)
  end
end
