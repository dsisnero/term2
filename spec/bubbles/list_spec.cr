require "../spec_helper"
require "../../src/components/list"
require "../../src/components/key"

class TestListItem
  include Term2::Components::List::Item

  getter title : String
  getter description : String

  def initialize(@title : String, @description : String = "")
  end

  def filter_value : String
    @title
  end
end

class TestDelegate
  include Term2::Components::List::ItemDelegate

  def height : Int32
    1
  end

  def spacing : Int32
    0
  end

  def render(io : IO, item : Term2::Components::List::Item, index : Int32, selected : Bool, enumerator : String)
    prefix = selected ? "> " : "  "
    io << "#{prefix}#{item.as(TestListItem).title}"
  end

  def update(msg : Term2::Message, model : Term2::Components::List) : Term2::Cmd
    Term2::Cmds.none
  end
end

describe Term2::Components::List do
  it "renders status bar item name pluralization" do
    items = [TestListItem.new("foo"), TestListItem.new("bar")].map(&.as(Term2::Components::List::Item))
    list = Term2::Components::List.new(items, 10, 10)
    list.show_status_bar?.should be_true
    list_view = list.view
    list_view.includes?("items").should be_true

    list.items = [TestListItem.new("foo")].map(&.as(Term2::Components::List::Item))
    list_view = list.view
    list_view.includes?("item").should be_true
  end

  it "renders custom status bar item name" do
    items = [TestListItem.new("foo"), TestListItem.new("bar")].map(&.as(Term2::Components::List::Item))
    list = Term2::Components::List.new(items, 10, 10)
    list.item_name_singular = "connection"
    list.item_name_plural = "connections"

    list.view.includes?("connections").should be_true
    list.items = [TestListItem.new("foo")].map(&.as(Term2::Components::List::Item))
    list.view.includes?("connection").should be_true
    list.items = [] of Term2::Components::List::Item
    list.view.includes?("No connections").should be_true
  end

  it "toggles filter state via keybinding" do
    list = Term2::Components::List.new(["foo"], 10, 10)
    list.filter_state.should eq Term2::Components::List::FilterState::Unfiltered
    msg = Term2::KeyMsg.new(Term2::Key.new("/"))
    list, _ = list.update(msg)
    list.filter_state.should eq Term2::Components::List::FilterState::Filtering
  end

  it "moves between filter states" do
    list = Term2::Components::List.new([] of Term2::Components::List::Item, 10, 10)
    list.toggle_filter
    list.filter_state.should eq Term2::Components::List::FilterState::Filtering
    list.toggle_filter
    list.filter_state.should eq Term2::Components::List::FilterState::FilterApplied
    list.toggle_filter
    list.filter_state.should eq Term2::Components::List::FilterState::Unfiltered
  end

  it "filters visible items according to filter text and state" do
    items = ["foo", "bar", "baz"].map { |t| Term2::Components::List.item(t).as(Term2::Components::List::Item) }
    list = Term2::Components::List.new(items, 10, 10)

    list.filter_value = "ba"

    list.set_filter_state(Term2::Components::List::FilterState::Unfiltered)
    list.visible_items.map(&.as(Term2::Components::List::DefaultItem).title).should eq ["foo", "bar", "baz"]

    list.set_filter_state(Term2::Components::List::FilterState::Filtering)
    list.visible_items.map(&.as(Term2::Components::List::DefaultItem).title).should eq ["bar", "baz"]

    list.set_filter_state(Term2::Components::List::FilterState::FilterApplied)
    list.visible_items.map(&.as(Term2::Components::List::DefaultItem).title).should eq ["bar", "baz"]
  end

  it "supports set_filter_text and matches helper" do
    items = ["alpha", "beta", "alpine"].map { |t| Term2::Components::List.item(t).as(Term2::Components::List::Item) }
    list = Term2::Components::List.new(items, 10, 10)

    list.set_filter_text("alp")
    list.filter_state.should eq Term2::Components::List::FilterState::FilterApplied
    list.visible_items.map(&.as(Term2::Components::List::DefaultItem).title).should eq ["alpha", "alpine"]
    list.matches_for_item(0).should_not be_empty
  end

  it "orders fuzzy matches by span and start" do
    items = ["foo", "faoo", "bar"].map { |t| Term2::Components::List.item(t).as(Term2::Components::List::Item) }
    list = Term2::Components::List.new(items, 10, 10)

    list.set_filter_text("fo")
    list.visible_items.map(&.as(Term2::Components::List::DefaultItem).title).should eq ["foo", "faoo"]
    list.matches_for_item(0).should eq [0, 1]
  end

  it "renders status hints for filter states" do
    items = ["foo", "bar"].map { |t| Term2::Components::List.item(t).as(Term2::Components::List::Item) }
    list = Term2::Components::List.new(items, 10, 10)

    list.set_filter_state(Term2::Components::List::FilterState::Unfiltered)
    list.status_view.should contain("up")

    list.set_filter_state(Term2::Components::List::FilterState::Filtering)
    list.status_view.should contain("filter")

    list.set_filter_state(Term2::Components::List::FilterState::FilterApplied)
    list.status_view.should contain("clear filter")
  end

  it "clears filter via clear binding" do
    items = ["foo", "bar"].map { |t| Term2::Components::List.item(t).as(Term2::Components::List::Item) }
    list = Term2::Components::List.new(items, 10, 10)
    list.filter_value = "ba"
    list.set_filter_state(Term2::Components::List::FilterState::FilterApplied)
    list.visible_items.size.should eq 1

    esc = Term2::KeyMsg.new(Term2::Key.new("esc"))
    list, _ = list.update(esc)
    list.filter_state.should eq Term2::Components::List::FilterState::Unfiltered
    list.visible_items.size.should eq 2
  end

  it "applies filter via enter binding" do
    items = ["foo", "bar"].map { |t| Term2::Components::List.item(t).as(Term2::Components::List::Item) }
    list = Term2::Components::List.new(items, 10, 10)
    list.filter_value = "ba"
    list.set_filter_state(Term2::Components::List::FilterState::Filtering)
    list.filter_input.value = "ba"

    enter = Term2::KeyMsg.new(Term2::Key.new("enter"))
    list, _ = list.update(enter)
    list.filter_state.should eq Term2::Components::List::FilterState::FilterApplied
    list.visible_items.size.should eq 1
  end

  it "exits via quit binding" do
    list = Term2::Components::List.new(["foo"], 10, 10)
    q = Term2::KeyMsg.new(Term2::Key.new("q"))
    _, cmd = list.update(q)
    cmd.should_not be_nil
    cmd.try(&.call).should be_a(Term2::QuitMsg)
  end

  it "renders help view with bindings" do
    list = Term2::Components::List.new(["foo"], 40, 10)
    list.show_help = true
    list.help.show_all = false
    output = list.view
    output.should contain("up")
    output.should contain("filter")
  end

  it "hides filter help when filtering disabled" do
    list = Term2::Components::List.new(["foo"], 40, 10)
    list.filtering_enabled = false
    list.show_help = true
    output = list.view
    output.should_not contain("filter")
  end
end
