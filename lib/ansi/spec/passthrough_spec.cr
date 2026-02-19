require "./spec_helper"

describe Ansi do
  passthrough_cases = [
    {
      name:   "empty",
      seq:    "",
      limit:  0,
      screen: "\eP\e\\",
      tmux:   "\ePtmux;\e\\",
    },
    {
      name:   "short",
      seq:    "hello",
      limit:  0,
      screen: "\ePhello\e\\",
      tmux:   "\ePtmux;hello\e\\",
    },
    {
      name:   "limit",
      seq:    "foobarbaz",
      limit:  3,
      screen: "\ePfoo\e\\\ePbar\e\\\ePbaz\e\\",
      tmux:   "\ePtmux;foobarbaz\e\\",
    },
    {
      name:   "escaped",
      seq:    "\e]52;c;Zm9vYmFy\a",
      limit:  0,
      screen: "\eP\e]52;c;Zm9vYmFy\a\e\\",
      tmux:   "\ePtmux;\e\e]52;c;Zm9vYmFy\a\e\\",
    },
  ]

  describe ".screen_passthrough" do
    passthrough_cases.each_with_index do |test_case, index|
      it test_case[:name] do
        Ansi.screen_passthrough(test_case[:seq], test_case[:limit]).should eq(test_case[:screen]), "case: #{index + 1}"
      end
    end
  end

  describe ".tmux_passthrough" do
    passthrough_cases.each_with_index do |test_case, index|
      it test_case[:name] do
        Ansi.tmux_passthrough(test_case[:seq]).should eq(test_case[:tmux]), "case: #{index + 1}"
      end
    end
  end
end
