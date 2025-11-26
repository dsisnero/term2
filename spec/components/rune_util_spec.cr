require "../spec_helper"
require "../../src/components/rune_util"

describe Term2::Components::RuneUtil do
  it "calculates width" do
    Term2::Components::RuneUtil.term_width("hello").should eq 5
    Term2::Components::RuneUtil.term_width("hello\e[31m world\e[0m").should eq 11
  end

  it "sanitizes strings" do
    Term2::Components::RuneUtil.sanitize("hello\tworld\n").should eq "hello    world "
  end
end
