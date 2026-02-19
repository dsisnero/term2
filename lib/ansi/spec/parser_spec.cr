require "./parser_support_spec"

include ParserSpecSupport

describe "Ansi::Parser" do
  it "parses control sequences" do
    cases = [
      {
        name:     "just_esc",
        input:    "\e",
        expected: ([] of DispatchItem),
      },
      {
        name:     "double_esc",
        input:    "\e\e",
        expected: [0x1b_u8] of DispatchItem,
      },
      {
        name:     "csi plus text",
        input:    "Hello, \e[31mWorld!\e[0m",
        expected: [
          'H',
          'e',
          'l',
          'l',
          'o',
          ',',
          ' ',
          CsiSequence.new('m'.ord, [31]),
          'W',
          'o',
          'r',
          'l',
          'd',
          '!',
          CsiSequence.new('m'.ord, [0]),
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
