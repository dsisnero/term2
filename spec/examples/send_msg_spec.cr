ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/send-msg/main"

describe "Example: send-msg" do
  it "receives external messages" do
    model = SendMsgModel.new
    tm = Term2::Teatest::TestModel(SendMsgModel).new(
      model,
      Term2::Teatest.with_initial_term_size(60, 15),
    )

    tm.send(ResultMsg.new("tacos", 200.milliseconds))
    tm.quit

    final = tm.final_model
    final.results.any? { |r| r.food == "tacos" && r.duration == 200.milliseconds }.should be_true
  end
end
