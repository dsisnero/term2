ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/textarea/main"

describe "Example: textarea", tags: "interactive" do
  it "focuses and updates text" do
    tm = Term2::Teatest::TestModel(TextareaExampleModel).new(
      TextareaExampleModel.new,
      Term2::Teatest.with_initial_term_size(60, 10),
    )
    tm.send(Term2::WindowSizeMsg.new(60, 10))

    tm.send(Term2::TestHelpers.uv_key('H'))
    tm.send(Term2::TestHelpers.uv_key('i'))
    tm.quit

    model = tm.final_model
    model.textarea.value.should contain("Hi")
  end
end
