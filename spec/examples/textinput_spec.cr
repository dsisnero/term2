ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/textinput/main"

describe "Example: textinput" do
  it "quits on enter" do
    tm = Term2::Teatest::TestModel(TextInputExampleModel).new(
      TextInputExampleModel.new,
      Term2::Teatest.with_initial_term_size(40, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(40, 10))

    tm.send(Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Enter)))
    tm.final_output
  end
end
