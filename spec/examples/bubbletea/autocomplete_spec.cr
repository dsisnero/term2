ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/autocomplete/main"

describe "Example: autocomplete" do
  it "shows loading state until repos arrive and then renders suggestions" do
    model = AutocompleteModel.new

    model.text_input.set_suggestions([] of String)
    model.view.should contain("Pick a Charm™ repo:")

    repos = [Repo.from_json(%({"name":"bubbletea"})), Repo.from_json(%({"name":"lipgloss"}))]
    model.update(GotReposSuccessMsg.new(repos))

    model.text_input.available_suggestions.should eq(["bubbletea", "lipgloss"])
    rendered = model.view
    rendered.should contain("Pick a Charm™ repo:")
    rendered.should contain("charmbracelet/")
  end
end
