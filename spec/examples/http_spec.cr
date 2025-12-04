ENV["TERM2_REQUIRE_ONLY"] = "1"
ENV["TERM2_HTTP_EXAMPLE_STATUS"] = "204"
require "../spec_helper"
require "../../examples/bubbletea/http/main"

describe "Example: http" do
  it "reports status and quits" do
    tm = Term2::Teatest::TestModel(HttpModel).new(
      HttpModel.new,
      Term2::Teatest.with_initial_term_size(80, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(80, 10))
    model = tm.final_model(
      Term2::Teatest.with_final_timeout(1.second),
      Term2::Teatest.with_timeout_fn { tm.quit },
    )
    model.status.should eq(204)
    model.error.should be_nil
  end
end
