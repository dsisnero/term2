ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/sequence/main"

describe "Example: sequence" do
  it "runs commands in order and quits" do
    tm = Term2::Teatest::TestModel(SequenceModel).new(
      SequenceModel.new,
      Term2::Teatest.with_initial_term_size(40, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(40, 10))

    model = tm.final_model(
      Term2::Teatest.with_final_timeout(6.seconds),
      Term2::Teatest.with_timeout_fn { tm.quit },
    )
    model.logs.should contain("1-1-1")
    model.logs.should contain("3-2-2")
  end
end
