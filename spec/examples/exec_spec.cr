ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/exec/main"

describe "Example: exec" do
  it "toggles alt screen and quits" do
    tm = Term2::Teatest::TestModel(ExecModel).new(ExecModel.new, Term2::Teatest.with_initial_term_size(40, 10))

    tm.send(Term2::KeyMsg.new(Term2::Key.new("a")))
    tm.send(Term2::KeyMsg.new(Term2::Key.new("q")))

    model = tm.final_model
    model.alt_screen_active?.should be_true
  end

  it "handles editor errors" do
    model = ExecModel.new
    err = RuntimeError.new("boom")
    model, _ = model.update(EditorFinishedMsg.new(err))
    model.err.should eq(err)
  end
end
