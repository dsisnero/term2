ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/realtime/main"

describe "Example: realtime" do
  it "receives activity messages" do
    tm = Term2::Teatest::TestModel(RealtimeModel).new(
      RealtimeModel.new,
      Term2::Teatest.with_initial_term_size(40, 10),
    )

    tm.send(ResponseMsg.new)
    tm.quit
    final = tm.final_model
    final.responses.should eq(1)
  end
end
