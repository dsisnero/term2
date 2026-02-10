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
    list.items[0].as(Term2::Components::List::DefaultItem).description.should eq "Desc 1"
  end

  it "navigates" do
    items = [
      Term2::Components::List::DefaultItem.new("Item 1"),
      Term2::Components::List::DefaultItem.new("Item 2"),
    ] of Term2::Components::List::Item

    list = Term2::Components::List.new(items)

    # Down
    msg = Term2::TestHelpers.key_msg(Term2::TestHelpers.uv_key("down"))
    list, _ = list.update(msg)
    list.index.should eq 1

    # Down (clamped)
    msg = Term2::TestHelpers.key_msg(Term2::TestHelpers.uv_key("down"))
    list, _ = list.update(msg)
    list.index.should eq 1

    # Up
    msg = Term2::TestHelpers.key_msg(Term2::TestHelpers.uv_key("up"))
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
    view.content.should contain "Item 1"
    view.content.should contain "Desc 1"
    view.content.should contain "Item 2"

    # Selected item should have cursor
    view.content.should contain "│ "
    view.content.should contain "  Item 2"
  end

  it "supports mouse-style cursor movement and selection helpers" do
    items = [
      Term2::Components::List::DefaultItem.new("Item 1", "Desc 1"),
      Term2::Components::List::DefaultItem.new("Item 2", "Desc 2"),
      Term2::Components::List::DefaultItem.new("Item 3", "Desc 3"),
    ] of Term2::Components::List::Item

    list = Term2::Components::List.new(items, width: 20, height: 0)
    list.index.should eq 0

    list.cursor_down
    list.index.should eq 1

    list.cursor_up
    list.index.should eq 0

    list.select(2)
    list.index.should eq 2
  end
end
