ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubblezone/full-lipgloss/main"

describe "Bubblezone example: full-lipgloss", tags: "interactive" do
  it "renders and quits cleanly" do
    tm = Term2::Teatest::TestModel(BubblezoneFullLipglossExample::FullLipglossModel).new(
      BubblezoneFullLipglossExample::FullLipglossModel.new,
      Term2::Teatest.with_initial_term_size(100, 30),
    )
    tm.send(Term2::WindowSizeMsg.new(100, 30))

    tm.send(Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::CtrlC)))

    output = tm.final_output
    output.should contain("eat marmalade?")
    output.should contain("Citrus Fruits to Try")
    output.should contain("Actual Lip Gloss Vendors")
  end
end
