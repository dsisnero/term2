require "./spec_helper"

describe "Ansi clipboard functions" do
  describe ".set_clipboard" do
    test_cases = [
      {
        name:   'c',
        data:   "Hello Test",
        expect: "\e]52;c;SGVsbG8gVGVzdA==\a",
      },
      {
        name:   'p',
        data:   "Ansi Test",
        expect: "\e]52;p;QW5zaSBUZXN0\a",
      },
      {
        name:   'c',
        data:   "",
        expect: "\e]52;c;\a",
      },
      {
        name:   'p',
        data:   "?",
        expect: "\e]52;p;Pw==\a",
      },
      {
        name:   Ansi::SystemClipboard,
        data:   "test",
        expect: "\e]52;c;dGVzdA==\a",
      },
    ]

    test_cases.each do |test_case|
      it "sets clipboard #{test_case[:name]} with data #{test_case[:data].inspect}" do
        Ansi.set_clipboard(test_case[:name], test_case[:data]).should eq test_case[:expect]
      end
    end
  end

  describe ".reset_clipboard" do
    it "resets primary clipboard" do
      Ansi.reset_clipboard(Ansi::PrimaryClipboard).should eq "\e]52;p;\a"
    end
  end

  describe ".request_clipboard" do
    it "requests primary clipboard" do
      Ansi.request_clipboard(Ansi::PrimaryClipboard).should eq "\e]52;p;?\a"
    end
  end

  describe "constants" do
    it "SystemClipboard is 'c'" do
      Ansi::SystemClipboard.should eq 'c'.ord.to_u8
    end

    it "PrimaryClipboard is 'p'" do
      Ansi::PrimaryClipboard.should eq 'p'.ord.to_u8
    end

    it "ResetSystemClipboard is correct" do
      Ansi::ResetSystemClipboard.should eq "\e]52;c;\a"
    end

    it "ResetPrimaryClipboard is correct" do
      Ansi::ResetPrimaryClipboard.should eq "\e]52;p;\a"
    end

    it "RequestSystemClipboard is correct" do
      Ansi::RequestSystemClipboard.should eq "\e]52;c;?\a"
    end

    it "RequestPrimaryClipboard is correct" do
      Ansi::RequestPrimaryClipboard.should eq "\e]52;p;?\a"
    end
  end
end
