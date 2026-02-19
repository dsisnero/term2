require "./spec_helper"

describe "Ansi title functions" do
  describe ".set_icon_name_window_title" do
    it "returns correct escape sequence" do
      Ansi.set_icon_name_window_title("hello").should eq "\e]0;hello\a"
    end
  end

  describe ".set_icon_name" do
    it "returns correct escape sequence" do
      Ansi.set_icon_name("hello").should eq "\e]1;hello\a"
    end
  end

  describe ".set_window_title" do
    it "returns correct escape sequence" do
      Ansi.set_window_title("hello").should eq "\e]2;hello\a"
    end
  end

  describe ".decswt" do
    it "returns DECSWT sequence" do
      Ansi.decswt("term").should eq "\e]2;1;term\a"
    end
  end

  describe ".decsin" do
    it "returns DECSIN sequence" do
      Ansi.decsin("icon").should eq "\e]2;L;icon\a"
    end
  end
end
