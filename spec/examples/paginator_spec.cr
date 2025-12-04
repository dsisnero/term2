ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/paginator/main"

describe "Example: paginator" do
  it "moves pages" do
    tm = Term2::Teatest::TestModel(PaginatorModel).new(
      PaginatorModel.new,
      Term2::Teatest.with_initial_term_size(80, 24),
    )
    tm.send(Term2::WindowSizeMsg.new(80, 24))

    tm.send(Term2::KeyMsg.new(Term2::Key.new("right")))
    tm.send(Term2::KeyMsg.new(Term2::Key.new("q")))

    model = tm.final_model
    model.paginator.page.should eq(1)
  end
end
