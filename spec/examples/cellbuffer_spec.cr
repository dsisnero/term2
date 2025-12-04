ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/cellbuffer/main"

describe "Example: cellbuffer" do
  it "renders ellipse after frame update" do
    tm = Term2::Teatest::TestModel(CellBufferModel).new(
      CellBufferModel.new,
      Term2::Teatest.with_initial_term_size(40, 20)
    )
    tm.send(Term2::WindowSizeMsg.new(40, 20))

    # Force a frame render without waiting for tick
    tm.send(CellbufferFrameMsg.new)

    Term2::Teatest.wait_for(tm.output_reader, duration: 1.second) do |txt|
      txt.includes?(ASTERISK)
    end

    tm.quit
  end
end
