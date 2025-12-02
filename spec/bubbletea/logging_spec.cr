require "../spec_helper"
require "../../src/logging"
require "file_utils"

describe "BubbleTea parity: logging" do
  it "logs to file with prefix" do
    path = File.join(Dir.tempdir, "log_test_#{Time.utc.to_unix}.txt")
    prefix = "logprefix"
    file = Term2.log_to_file(path, prefix)
    Log.info { "some test log" }
    file.close
    out = File.read(path)
    out.should eq("#{prefix} some test log\n")
    FileUtils.rm(path)
  end
end