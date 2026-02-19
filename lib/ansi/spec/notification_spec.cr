require "./spec_helper"

describe "Ansi notification functions" do
  describe ".notify" do
    it "sends basic notification" do
      Ansi.notify("Hello, World!").should eq "\e]9;Hello, World!\a"
    end

    it "handles empty string" do
      Ansi.notify("").should eq "\e]9;\a"
    end

    it "handles special characters" do
      Ansi.notify("Line1\nLine2\tTabbed").should eq "\e]9;Line1\nLine2\tTabbed\a"
    end
  end

  describe ".desktop_notification" do
    it "sends basic notification" do
      Ansi.desktop_notification("Task Completed").should eq "\e]99;;Task Completed\a"
    end

    it "handles metadata" do
      result = Ansi.desktop_notification("New Message", "i=1", "a=focus")
      result.should eq "\e]99;i=1:a=focus;New Message\a"
    end

    it "handles empty payload with metadata" do
      Ansi.desktop_notification("", "i=2").should eq "\e]99;i=2;\a"
    end
  end
end
