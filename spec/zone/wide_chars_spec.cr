require "../spec_helper"

describe "Term2::Zone wide character geometry" do
  it "accounts for wide chars when computing x positions" do
    Term2::Zone.reset

    # '你' is a wide character in terminal cell width calculations.
    input = "a你" + Term2::Zone.mark("w", "b") + "c"
    Term2::Zone.scan(input)

    zone = Term2::Zone.get("w")
    zone.zero?.should be_false

    # 'a'(1) + '你'(2) => zone starts at x=3.
    zone.start_x.should eq 3
    zone.end_x.should eq 3
  end
end
