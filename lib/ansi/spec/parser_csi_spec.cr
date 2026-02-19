require "./parser_support_spec"

include ParserSpecSupport

describe "Ansi::Parser" do
  it "parses CSI sequences" do
    cases = [
      {
        name:     "no_params",
        input:    "\e[m",
        expected: [CsiSequence.new('m'.ord, [] of Int32)] of DispatchItem,
      },
      {
        name:     "one_param",
        input:    "\e[7m",
        expected: [CsiSequence.new('m'.ord, [7])] of DispatchItem,
      },
      {
        name:     "param_reset",
        input:    "\e[0mabc\e[1;2m",
        expected: [
          CsiSequence.new('m'.ord, [0]),
          'a',
          'b',
          'c',
          CsiSequence.new('m'.ord, [1, 2]),
        ] of DispatchItem,
      },
      {
        name:     "max_params",
        input:    "\e[" + ("1;" * 31) + "p",
        expected: [
          CsiSequence.new('p'.ord, [
            1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1,
          ]),
        ] of DispatchItem,
      },
      {
        name:     "ignore_long",
        input:    "\e[" + ("1;" * 18) + "p",
        expected: [
          CsiSequence.new('p'.ord, [
            1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1,
          ]),
        ] of DispatchItem,
      },
      {
        name:     "trailing_semicolon",
        input:    "\e[4;m",
        expected: [
          CsiSequence.new('m'.ord, [4, Ansi::ParserTransition::MissingParam]),
        ] of DispatchItem,
      },
      {
        name:     "leading_semicolon",
        input:    "\e[;4m",
        expected: [
          CsiSequence.new('m'.ord, [Ansi::ParserTransition::MissingParam, 4]),
        ] of DispatchItem,
      },
      {
        name:     "long_param",
        input:    "\e[#{Ansi::ParserTransition::MaxParam}m",
        expected: [CsiSequence.new('m'.ord, [Ansi::ParserTransition::MaxParam])] of DispatchItem,
      },
      {
        name:     "reset",
        input:    "\e[3;1\e[?1049h",
        expected: [
          CsiSequence.new(
            'h'.ord | ('?'.ord << Ansi::ParserTransition::PrefixShift),
            [1049]
          ),
        ] of DispatchItem,
      },
      {
        name:     "subparams",
        input:    "\e[38:2:255:0:255;1m",
        expected: [
          CsiSequence.new('m'.ord, [
            38 | Ansi::ParserTransition::HasMoreFlag,
            2 | Ansi::ParserTransition::HasMoreFlag,
            255 | Ansi::ParserTransition::HasMoreFlag,
            0 | Ansi::ParserTransition::HasMoreFlag,
            255,
            1,
          ]),
        ] of DispatchItem,
      },
      {
        name:     "params_buffer_filled_with_subparams",
        input:    "\e[::::::::::::::::::::::::::::::::x\e",
        expected: [
          CsiSequence.new('x'.ord, [
            Ansi::ParserTransition::MissingParam | Ansi::ParserTransition::HasMoreFlag,
            Ansi::ParserTransition::MissingParam | Ansi::ParserTransition::HasMoreFlag,
            Ansi::ParserTransition::MissingParam | Ansi::ParserTransition::HasMoreFlag,
            Ansi::ParserTransition::MissingParam | Ansi::ParserTransition::HasMoreFlag,
            Ansi::ParserTransition::MissingParam | Ansi::ParserTransition::HasMoreFlag,
            Ansi::ParserTransition::MissingParam | Ansi::ParserTransition::HasMoreFlag,
            Ansi::ParserTransition::MissingParam | Ansi::ParserTransition::HasMoreFlag,
            Ansi::ParserTransition::MissingParam | Ansi::ParserTransition::HasMoreFlag,
            Ansi::ParserTransition::MissingParam | Ansi::ParserTransition::HasMoreFlag,
            Ansi::ParserTransition::MissingParam | Ansi::ParserTransition::HasMoreFlag,
            Ansi::ParserTransition::MissingParam | Ansi::ParserTransition::HasMoreFlag,
            Ansi::ParserTransition::MissingParam | Ansi::ParserTransition::HasMoreFlag,
            Ansi::ParserTransition::MissingParam | Ansi::ParserTransition::HasMoreFlag,
            Ansi::ParserTransition::MissingParam | Ansi::ParserTransition::HasMoreFlag,
            Ansi::ParserTransition::MissingParam | Ansi::ParserTransition::HasMoreFlag,
            Ansi::ParserTransition::MissingParam | Ansi::ParserTransition::HasMoreFlag,
          ]),
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
