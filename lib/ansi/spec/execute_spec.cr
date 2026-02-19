require "./spec_helper"

describe "Ansi.execute" do
  it "writes to io and returns byte count" do
    io = IO::Memory.new
    count = Ansi.execute(io, "abc")
    count.should eq 3
    io.to_s.should eq "abc"
  end
end
