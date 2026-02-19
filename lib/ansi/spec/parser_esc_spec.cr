require "./parser_support_spec"

include ParserSpecSupport

describe "Ansi::Parser" do
  it "parses ESC sequences" do
    cases = [
      {
        name:     "reset",
        input:    "\e[3;1\e(A",
        expected: [
          'A'.ord | ('('.ord << Ansi::ParserTransition::IntermedShift),
        ] of DispatchItem,
      },
    ]

    cases.each do |test_case|
      dispatcher = TestDispatcher.new
      parser = ParserSpecSupport.test_parser(dispatcher)
      parser.parse(test_case[:input])
      dispatcher.dispatched.size.should eq(test_case[:expected].size)
      dispatcher.dispatched.should eq(test_case[:expected])
    end
  end
end
