ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/tabs/main"

describe "Example: tabs", tags: "interactive" do
  it "moves between tabs" do
    tm = Term2::Teatest::TestModel(TabsModel).new(
      TabsModel.new,
      Term2::Teatest.with_initial_term_size(80, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(80, 10))

    tm.send(Term2::TestHelpers.uv_key("right"))
    tm.send(Term2::TestHelpers.uv_key("right"))
    tm.quit

    model = tm.final_model
    model.active_tab.should eq(2)
  end
end
