require "./spec_helper"

describe "Ansi.notify_working_directory" do
  it "generates local file URL" do
    result = Ansi.notify_working_directory("localhost", "path", "to", "file")
    result.should eq "\e]7;file://localhost/path/to/file\a"
  end

  it "generates remote file URL" do
    result = Ansi.notify_working_directory("example.com", "path", "to", "file")
    result.should eq "\e]7;file://example.com/path/to/file\a"
  end
end
