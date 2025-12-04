require "../spec_helper"
require "../../src/components/paginator"

describe Term2::Components::Paginator do
  it "initializes with defaults or custom settings" do
    model = Term2::Components::Paginator.new
    model.per_page.should eq 1
    model.total_pages.should eq 1

    per_page = 42
    total_pages = 42
    model = Term2::Components::Paginator.new(per_page: per_page, total_pages: total_pages)
    model.per_page.should eq per_page
    model.total_pages.should eq total_pages
  end

  it "calculates total pages from item count" do
    tests = [
      {name: "Less than one page", items: 5, initial_total: 1, expected: 5},
      {name: "Exactly one page", items: 10, initial_total: 1, expected: 10},
      {name: "More than one page", items: 15, initial_total: 1, expected: 15},
      {name: "negative value for page", items: -10, initial_total: 1, expected: 1},
    ]

    tests.each do |t|
      model = Term2::Components::Paginator.new(total_pages: t[:initial_total])
      model.set_total_pages(t[:items])
      model.total_pages.should eq t[:expected]
    end
  end

  it "moves to previous page when available" do
    tests = [
      {name: "Go to previous page", total_pages: 10, page: 1, expected: 0},
      {name: "Stay on first page", total_pages: 5, page: 0, expected: 0},
    ]

    tests.each do |t|
      model = Term2::Components::Paginator.new
      model.total_pages = t[:total_pages]
      model.page = t[:page]

      msg = Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Left))
      model, _ = model.update(msg)
      model.page.should eq t[:expected]
    end
  end

  it "moves to next page when available" do
    tests = [
      {name: "Go to next page", total_pages: 2, page: 0, expected: 1},
      {name: "Stay on last page", total_pages: 2, page: 1, expected: 1},
    ]

    tests.each do |t|
      model = Term2::Components::Paginator.new
      model.total_pages = t[:total_pages]
      model.page = t[:page]

      msg = Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Right))
      model, _ = model.update(msg)
      model.page.should eq t[:expected]
    end
  end

  it "reports page edges" do
    model = Term2::Components::Paginator.new
    model.total_pages = 2
    model.page = 1
    model.on_last_page?.should be_true
    model.on_first_page?.should be_false

    model.page = 0
    model.on_first_page?.should be_true
    model.on_last_page?.should be_false
  end

  it "reports items on page" do
    test_cases = [
      {current_page: 1, total_pages: 10, total_items: 10, expected_items: 1},
      {current_page: 3, total_pages: 10, total_items: 10, expected_items: 1},
      {current_page: 7, total_pages: 10, total_items: 10, expected_items: 1},
    ]

    test_cases.each do |tc|
      model = Term2::Components::Paginator.new
      model.page = tc[:current_page]
      model.total_pages = tc[:total_pages]
      model.items_on_page(tc[:total_items]).should eq tc[:expected_items]
    end
  end
end
