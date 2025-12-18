ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"

require "../../../examples/bubblezone/full-lipgloss/styles"
require "../../../examples/bubblezone/full-lipgloss/tabs"
require "../../../examples/bubblezone/full-lipgloss/list"
require "../../../examples/bubblezone/full-lipgloss/dialog"
require "../../../examples/bubblezone/full-lipgloss/history"

describe "Bubblezone example components", tags: "interactive" do
  it "renders tabs, lists, dialog, and history components" do
    tabs = BubblezoneFullLipgloss::TabsComponent.new(Term2::Zone.new_prefix, ["One", "Two"], "One")
    Term2::Text.strip_ansi(tabs.view(40)).should contain("One")

    list = BubblezoneFullLipgloss::ListComponent.new(
      Term2::Zone.new_prefix,
      "Fruits",
      [BubblezoneFullLipgloss::ListItem.new("Apple", false)]
    )
    Term2::Text.strip_ansi(list.view(40, 10)).should contain("Fruits")
    Term2::Text.strip_ansi(list.view(40, 10)).should contain("Apple")

    dialog = BubblezoneFullLipgloss::DialogComponent.new(Term2::Zone.new_prefix, "Are you sure?")
    Term2::Text.strip_ansi(dialog.view(40, 10)).should contain("Are you sure?")

    history = BubblezoneFullLipgloss::HistoryComponent.new(Term2::Zone.new_prefix, ["Entry 1", "Entry 2"])
    Term2::Text.strip_ansi(history.view(60, 5)).should contain("Entry 1")
  end
end
