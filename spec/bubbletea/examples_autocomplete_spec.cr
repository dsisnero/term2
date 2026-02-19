ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/autocomplete/main"

describe "Bubbletea example: autocomplete" do
  it "renders prompt and cycles suggestions with key input (offline-safe)" do
    model = AutocompleteModel.new

    "bub".each_char do |ch|
      model.update(Term2::TestHelpers.uv_key(ch))
    end

    model.update(Term2::TestHelpers.uv_key("ctrl+n"))
    model.update(Term2::TestHelpers.uv_key("tab"))

    model.text_input.value.should eq("bubbletea")
  end
end
