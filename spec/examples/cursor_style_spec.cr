ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "teatest"
require "../../examples/bubbletea/cursor-style/main"

describe "Example: cursor-style" do
  it "matches the Go output" do
    model = CursorStyleExample::Model.new
    view = model.view
    output = view.is_a?(String) ? view : view.content
    Teatest.require_equal_output("CursorStyle/default", output.to_slice)
  end
end
