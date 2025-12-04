ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/list-fancy/main"

describe "Example: list-fancy" do
  it "adds an item and toggles title" do
    tm = Term2::Teatest::TestModel(FancyListModel).new(
      FancyListModel.new,
      Term2::Teatest.with_initial_term_size(80, 20),
    )
    tm.send(Term2::WindowSizeMsg.new(80, 20))

    tm.send(Term2::KeyMsg.new(Term2::Key.new("a")))
    tm.send(Term2::KeyMsg.new(Term2::Key.new("T")))
    tm.send(Term2::KeyMsg.new(Term2::Key.new("q")))

    model = tm.final_model(
      Term2::Teatest.with_final_timeout(1.second),
      Term2::Teatest.with_timeout_fn { tm.quit },
    )
    model.list.items.size.should be > 0
    model.list.status_message.should_not be_empty
  end
end
