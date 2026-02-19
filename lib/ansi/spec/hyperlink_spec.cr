require "./spec_helper"

describe "Ansi hyperlink functions" do
  describe ".set_hyperlink" do
    it "generates hyperlink with no params" do
      result = Ansi.set_hyperlink("https://example.com")
      result.should eq "\e]8;;https://example.com\a"
    end

    it "generates hyperlink with params" do
      result = Ansi.set_hyperlink("https://example.com", "color=blue", "size=12")
      result.should eq "\e]8;color=blue:size=12;https://example.com\a"
    end

    it "generates hyperlink reset with empty URI" do
      result = Ansi.set_hyperlink("")
      result.should eq "\e]8;;\a"
    end
  end

  describe ".reset_hyperlink" do
    it "generates hyperlink reset" do
      result = Ansi.reset_hyperlink
      result.should eq "\e]8;;\a"
    end

    it "generates hyperlink reset with params" do
      result = Ansi.reset_hyperlink("color=blue", "size=12")
      result.should eq "\e]8;color=blue:size=12;\a"
    end
  end
end
