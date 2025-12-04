require "../spec_helper"
require "../../src/logging"

describe "Bubbletea parity: logging_test.go" do
  it "log_to_file writes prefixed log" do
    path = File.join(Dir.tempdir, "log_test.txt")
    prefix = "logprefix"
    file = Term2.log_to_file(path, prefix)
    Log.info { "some test log" }
    file.close
    out = File.read(path)
    out.should eq("#{prefix} some test log\n")
  end
end
