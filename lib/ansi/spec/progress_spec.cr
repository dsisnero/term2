require "./spec_helper"

describe "Ansi progress bar functions" do
  describe ".set_progress_bar" do
    it "returns correct sequence for percentage 50" do
      Ansi.set_progress_bar(50).should eq "\e]9;4;1;50\a"
    end

    it "clamps negative percentage to 0" do
      Ansi.set_progress_bar(-2).should eq "\e]9;4;1;0\a"
    end

    it "clamps percentage above 100 to 100" do
      Ansi.set_progress_bar(200).should eq "\e]9;4;1;100\a"
    end
  end

  describe ".set_error_progress_bar" do
    it "returns correct sequence for percentage 50" do
      Ansi.set_error_progress_bar(50).should eq "\e]9;4;2;50\a"
    end

    it "clamps negative percentage to 0" do
      Ansi.set_error_progress_bar(-2).should eq "\e]9;4;2;0\a"
    end

    it "clamps percentage above 100 to 100" do
      Ansi.set_error_progress_bar(200).should eq "\e]9;4;2;100\a"
    end
  end

  describe ".set_warning_progress_bar" do
    it "returns correct sequence for percentage 50" do
      Ansi.set_warning_progress_bar(50).should eq "\e]9;4;4;50\a"
    end

    it "clamps negative percentage to 0" do
      Ansi.set_warning_progress_bar(-2).should eq "\e]9;4;4;0\a"
    end

    it "clamps percentage above 100 to 100" do
      Ansi.set_warning_progress_bar(200).should eq "\e]9;4;4;100\a"
    end
  end

  describe "constants" do
    it "ResetProgressBar is correct" do
      Ansi::ResetProgressBar.should eq "\e]9;4;0\a"
    end

    it "SetIndeterminateProgressBar is correct" do
      Ansi::SetIndeterminateProgressBar.should eq "\e]9;4;3\a"
    end
  end
end
