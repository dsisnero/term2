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
    list = Term2::Components::List.new([] of Term2::Components::List::Item, 10, 10)
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
end
