require "../spec_helper"
require "../../src/components/memoization"

alias Memo = Term2::Components::Memoization

describe Memo::MemoCache do
  it "creates cache and supports get on empty" do
    cache = Memo::MemoCache(Memo::HString, String?).new(5)
    value, ok = cache.get(Memo::HString.new("missing"))
    ok.should be_false
    value.should be_nil
  end

  it "sets and gets values" do
    cache = Memo::MemoCache(Memo::HString, String?).new(10)
    cache.set(Memo::HString.new("key1"), "value1")
    value, ok = cache.get(Memo::HString.new("key1"))
    ok.should be_true
    value.should eq "value1"

    cache.set(Memo::HString.new("key1"), "newValue1")
    value, ok = cache.get(Memo::HString.new("key1"))
    ok.should be_true
    value.should eq "newValue1"

    missing, ok = cache.get(Memo::HString.new("nonExistentKey"))
    ok.should be_false
    missing.should be_nil

    cache.set(Memo::HString.new("nilKey"), "")
    value, ok = cache.get(Memo::HString.new("nilKey"))
    ok.should be_true
    value.should eq ""
  end

  it "stores nil values" do
    cache = Memo::MemoCache(Memo::HString, String?).new(10)
    cache.set(Memo::HString.new("nilKey"), nil)
    value, ok = cache.get(Memo::HString.new("nilKey"))
    ok.should be_true
    value.should be_nil
  end

  it "evicts when capacity exceeded" do
    cache = Memo::MemoCache(Memo::HInt, Int32?).new(2)
    cache.set(Memo::HInt.new(1), 1)
    cache.set(Memo::HInt.new(2), 2)
    cache.set(Memo::HInt.new(3), 3)

    missing, ok = cache.get(Memo::HInt.new(1))
    ok.should be_false
    missing.should be_nil

    value, ok = cache.get(Memo::HInt.new(2))
    ok.should be_true
    value.should eq 2
  end

  it "respects LRU order" do
    cache = Memo::MemoCache(Memo::HInt, Int32?).new(2)
    cache.set(Memo::HInt.new(1), 1)
    cache.set(Memo::HInt.new(2), 2)

    cache.get(Memo::HInt.new(1))
    cache.set(Memo::HInt.new(3), 3)

    cache.get(Memo::HInt.new(1)).last.should be_true
    cache.get(Memo::HInt.new(3)).last.should be_true
    cache.get(Memo::HInt.new(2)).last.should be_false
  end

  it "handles varying accesses with larger capacity" do
    cache = Memo::MemoCache(Memo::HInt, Int32?).new(3)
    cache.set(Memo::HInt.new(1), 1)
    cache.set(Memo::HInt.new(2), 2)
    cache.set(Memo::HInt.new(3), 3)

    cache.get(Memo::HInt.new(1))
    cache.get(Memo::HInt.new(2))
    cache.set(Memo::HInt.new(4), 4)

    cache.get(Memo::HInt.new(3)).last.should be_false
    cache.get(Memo::HInt.new(1)).last.should be_true
    cache.get(Memo::HInt.new(2)).last.should be_true
    cache.get(Memo::HInt.new(4)).last.should be_true
  end

  it "handles simple fuzz style sequences" do
    cache = Memo::MemoCache(Memo::HInt, Int32?).new(3)
    sequences = [
      [[:set, 0, 0], [:get, 0], [:set, 1, 1], [:get, 1]],
      [[:set, 0, 1], [:set, 1, 2], [:set, 2, 3], [:get, 0], [:get, 3]],
      [[:set, 5, 5], [:set, 6, 6], [:get, 5], [:set, 7, 7], [:get, 6]],
    ]

    sequences.each do |ops|
      ops.each do |op|
        case op[0]
        when :set
          cache.set(Memo::HInt.new(op[1].to_i), op[2].to_i)
        when :get
          cache.get(Memo::HInt.new(op[1].to_i))
        end
      end
    end
  end
end
