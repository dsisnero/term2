ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/spinners/main"

describe "Example: spinners", tags: "interactive" do
  it "cycles spinner types" do
    tm = Term2::Teatest::TestModel(SpinnersModel).new(
      SpinnersModel.new,
      Term2::Teatest.with_initial_term_size(40, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(40, 10))

    tm.send(Term2::TestHelpers.uv_key("right"))
    tm.send(Term2::TestHelpers.uv_key("right"))
    tm.quit

    model = tm.final_model
    model.index.should eq(2)
  end
end
