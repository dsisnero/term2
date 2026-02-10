ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/autocomplete/main"
require "../support/teatest"

# Simple harness to exercise the autocomplete example with the teatest helper.
describe "Bubbletea example: autocomplete" do
  it "renders prompt and cycles suggestions with key input (offline-safe)" do
    tm = Term2::Teatest::TestModel(AutocompleteModel).new(AutocompleteModel.new, Term2::Teatest.with_initial_term_size(70, 30))

    # Type a prefix and cycle suggestions
    tm.type("bub")
    tm.send(Term2::TestHelpers.key_msg(Term2::TestHelpers.uv_key("ctrl+n")))
    tm.send(Term2::TestHelpers.key_msg(Term2::TestHelpers.uv_key("tab"))) # accept current suggestion

    tm.quit

    model = tm.final_model
    model.text_input.value.should eq("bubbletea")
  end
end
