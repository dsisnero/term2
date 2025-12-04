ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/help/main"

describe "Example: help" do
  it "tracks input and toggles full help" do
    tm = Term2::Teatest::TestModel(HelpModel).new(
      HelpModel.new,
      Term2::Teatest.with_initial_term_size(80, 10),
    )

    tm.send(Term2::KeyMsg.new(Term2::Key.new("up")))
    tm.send(Term2::KeyMsg.new(Term2::Key.new("?")))
    tm.quit

    model = tm.final_model
    model.last_key.should eq("↑")
    model.help.show_all?.should be_true
  end
end
