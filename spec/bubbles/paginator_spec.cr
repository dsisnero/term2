require "../spec_helper"
require "../../src/bubbles/paginator"

describe Term2::Bubbles::Paginator do
  it "calculates total pages correctly" do
    p = Term2::Bubbles::Paginator.new
    p.per_page = 10
    p.total_pages = 25
    p.total_pages.should eq 3
  end

  it "handles page navigation" do
    p = Term2::Bubbles::Paginator.new
    p.per_page = 10
    p.total_pages = 25

    p.page.should eq 0
    p.on_last_page?.should be_false
    p.next_page
    p.page.should eq 1
    p.next_page
    p.page.should eq 2
    p.next_page
    p.page.should eq 2 # Clamped

    p.prev_page
    p.page.should eq 1
  end

  it "renders dots correctly" do
    p = Term2::Bubbles::Paginator.new
    p.type = Term2::Bubbles::Paginator::Type::Dots
    p.per_page = 10
    p.total_pages = 25

    # Page 0: •○○
    p.view.should contain "•"
    p.view.should contain "○"
  end

  it "renders arabic correctly" do
    p = Term2::Bubbles::Paginator.new
    p.type = Term2::Bubbles::Paginator::Type::Arabic
    p.per_page = 10
    p.total_pages = 25

    # Page 0: 1/3
    p.view.should contain "1/3"
  end
end
