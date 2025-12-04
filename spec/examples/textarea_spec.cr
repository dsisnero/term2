ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/textarea/main"

describe "Example: textarea" do
  it "focuses and updates text" do
    tm = Term2::Teatest::TestModel(TextareaExampleModel).new(
      TextareaExampleModel.new,
      Term2::Teatest.with_initial_term_size(60, 10),
    )

    tm.send(Term2::KeyMsg.new(Term2::Key.new('H')))
    tm.send(Term2::KeyMsg.new(Term2::Key.new('i')))
    tm.quit

    model = tm.final_model
    model.textarea.value.should contain("Hi")
  end
end
