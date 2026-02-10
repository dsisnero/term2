ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/textinputs/main"

describe "Example: textinputs", tags: "interactive" do
  it "cycles focus and quits on enter at submit" do
    tm = Term2::Teatest::TestModel(TextinputsModel).new(
      TextinputsModel.new,
      Term2::Teatest.with_initial_term_size(50, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(50, 10))

    tm.send(Term2::TestHelpers.uv_key("tab"))
    tm.send(Term2::TestHelpers.uv_key("tab"))
    tm.send(Term2::TestHelpers.uv_key("enter"))
    tm.send(Term2::TestHelpers.uv_key("q"))

    output = tm.final_output
    output.should contain("Submit")
  end
end
