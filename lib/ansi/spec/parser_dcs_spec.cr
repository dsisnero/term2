require "./parser_support_spec"

include ParserSpecSupport

describe "Ansi::Parser" do
  it "parses DCS sequences" do
    cases = [
      {
        name:     "max_params",
        input:    "\eP#{"1;" * 33}p\e\\",
        expected: [
          DcsSequence.new('p'.ord, [
            1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1,
          ], Bytes.empty),
          '\\'.ord,
        ] of DispatchItem,
      },
      {
        name:     "reset",
        input:    "\e[3;1\eP1$tx\x9c",
        expected: [
          DcsSequence.new(
            't'.ord | ('$'.ord << Ansi::ParserTransition::IntermedShift),
            [1],
            Bytes['x'.ord.to_u8]
          ),
        ] of DispatchItem,
      },
      {
        name:     "parse",
        input:    "\eP0;1|17/ab\x9c",
        expected: [
          DcsSequence.new(
            '|'.ord,
            [0, 1],
            "17/ab".to_slice
          ),
        ] of DispatchItem,
      },
      {
        name:     "intermediate_reset_on_exit",
        input:    "\eP=1sZZZ\e+\\",
        expected: [
          DcsSequence.new(
            's'.ord | ('='.ord << Ansi::ParserTransition::PrefixShift),
            [1],
            "ZZZ".to_slice
          ),
          '\\'.ord | ('+'.ord << Ansi::ParserTransition::IntermedShift),
        ] of DispatchItem,
      },
      {
        name:     "put_utf8",
        input:    "\eP+r😃\e\\",
        expected: [
          DcsSequence.new(
            'r'.ord | ('+'.ord << Ansi::ParserTransition::IntermedShift),
            [] of Int32,
            "😃".to_slice
          ),
          '\\'.ord,
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
