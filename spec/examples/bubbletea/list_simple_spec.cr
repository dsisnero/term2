ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/list-simple/main"

describe "Example: list-simple", tags: "interactive" do
  it "selects an item and quits" do
    tm = Term2::Teatest::TestModel(ListSimpleModel).new(
      ListSimpleModel.new,
      Term2::Teatest.with_initial_term_size(40, 15),
    )
    tm.send(Term2::WindowSizeMsg.new(40, 15))

    tm.send(Term2::TestHelpers.uv_key("enter"))

    model = tm.final_model
    model.choice.should eq("Ramen")
  end
end
