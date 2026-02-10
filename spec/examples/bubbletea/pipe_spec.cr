ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/pipe/main"

describe "Example: pipe", tags: "interactive" do
  it "displays piped content" do
    tm = Term2::Teatest::TestModel(PipeModel).new(
      PipeModel.new("hello"),
      Term2::Teatest.with_initial_term_size(50, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(50, 10))

    tm.send(Term2::TestHelpers.uv_key("ctrl+c"))
    output = tm.final_output(
      Term2::Teatest.with_final_timeout(1.second),
      Term2::Teatest.with_timeout_fn { tm.quit },
    )
    output.should contain("hello")
  end
end
