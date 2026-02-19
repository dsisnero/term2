require "./spec_helper"

describe "Ansi URxvt" do
  it "builds URxvt extension sequences" do
    cases = [
      {"foo", ["bar", "baz"], "\e]777;foo;bar;baz\a"},
      {"test", [] of String, "\e]777;test;\a"},
      {"example", ["param1"], "\e]777;example;param1\a"},
      {"notify", ["message", "info"], "\e]777;notify;message;info\a"},
    ]

    cases.each do |extension, params, expected|
      Ansi.urxvt_ext(extension, params).should eq expected
    end
  end
end
