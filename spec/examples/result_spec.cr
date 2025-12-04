ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/result/main"

describe "Example: result" do
  it "returns chosen value" do
    tm = Term2::Teatest::TestModel(ResultModel).new(
      ResultModel.new,
      Term2::Teatest.with_initial_term_size(40, 10),
    )

    tm.send(Term2::KeyMsg.new(Term2::Key.new("enter")))
    model = tm.final_model(
      Term2::Teatest.with_final_timeout(1.second),
      Term2::Teatest.with_timeout_fn { tm.quit },
    )
    model.choice.should eq("Taro")
  end
end
