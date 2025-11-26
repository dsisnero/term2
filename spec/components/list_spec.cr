require "../spec_helper"
require "../../src/components/list"

describe Term2::Components::List do
  it "initializes with items" do
    items = [
      Term2::Components::List::DefaultItem.new("Item 1"),
      Term2::Components::List::DefaultItem.new("Item 2"),
    ] of Term2::Components::List::Item

    list = Term2::Components::List.new(items)
    list.items.size.should eq 2
    list.index.should eq 0
  end

  it "initializes with string array" do
    list = Term2::Components::List.new(["Item 1", "Item 2"])
    list.items.size.should eq 2
    list.items[0].title.should eq "Item 1"
    list.items[1].title.should eq "Item 2"
  end

  it "initializes with tuple array" do
    list = Term2::Components::List.new([{"Item 1", "Desc 1"}, {"Item 2", "Desc 2"}])
    list.items.size.should eq 2
    list.items[0].title.should eq "Item 1"
    list.items[0].description.should eq "Desc 1"
  end

  it "navigates" do
    items = [
      Term2::Components::List::DefaultItem.new("Item 1"),
      Term2::Components::List::DefaultItem.new("Item 2"),
    ] of Term2::Components::List::Item

    list = Term2::Components::List.new(items)

    # Down
    msg = Term2::KeyMsg.new(Term2::Key.new("down"))
    list, _ = list.update(msg)
    list.index.should eq 1

    # Down (clamped)
    msg = Term2::KeyMsg.new(Term2::Key.new("down"))
    list, _ = list.update(msg)
    list.index.should eq 1

    # Up
    msg = Term2::KeyMsg.new(Term2::Key.new("up"))
    list, _ = list.update(msg)
    list.index.should eq 0
  end

  it "renders" do
    items = [
      Term2::Components::List::DefaultItem.new("Item 1", "Desc 1"),
      Term2::Components::List::DefaultItem.new("Item 2", "Desc 2"),
    ] of Term2::Components::List::Item

    list = Term2::Components::List.new(items, width: 20, height: 10)

    view = list.view
    view.should contain "Item 1"
    view.should contain "Desc 1"
    view.should contain "Item 2"

    # Selected item should have cursor
    view.should contain "> Item 1"
    view.should contain "  Item 2"
  end
end
