ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "teatest"
require "../../examples/bubbletea/print-key/main"

describe "Example: print-key" do
  it "matches the Go output" do
    model = PrintKeyExample::Model.new
    view = model.view
    output = view.is_a?(String) ? view : view.content
    Teatest.require_equal_output("PrintKey/default", output.to_slice)
  end
end
