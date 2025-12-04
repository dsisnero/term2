ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/eyes/main"

describe "Example: eyes" do
  it "renders blinking eyes" do
    tm = Term2::Teatest::TestModel(EyesModel).new(EyesModel.new, Term2::Teatest.with_initial_term_size(80, 24))
    tm.send(Term2::WindowSizeMsg.new(80, 24))

    tm.send(Term2::KeyMsg.new(Term2::Key.new("q")))
    tm.quit
    final = tm.final_model
    final.blinking?.should be_false
  end
end
