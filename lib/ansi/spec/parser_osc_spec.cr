require "./parser_support_spec"

include ParserSpecSupport

describe "Ansi::Parser" do
  it "parses OSC sequences" do
    max_buffer_size = 1024
    cases = [
      {
        name:     "parse",
        input:    "\e]2;charmbracelet: ~/Source/bubbletea\a",
        expected: ["2;charmbracelet: ~/Source/bubbletea".to_slice] of DispatchItem,
      },
      {
        name:     "empty",
        input:    "\e]\a",
        expected: [Bytes.empty] of DispatchItem,
      },
      {
        name:     "max_params",
        input:    "\e]#{";" * 17}\e\\",
        expected: [
          (";" * 17).to_slice,
          '\\'.ord,
        ] of DispatchItem,
      },
      {
        name:     "bell_terminated",
        input:    "\e]11;ff/00/ff\a",
        expected: ["11;ff/00/ff".to_slice] of DispatchItem,
      },
      {
        name:     "esc_st_terminated",
        input:    "\e]11;ff/00/ff\e\\",
        expected: [
          "11;ff/00/ff".to_slice,
          '\\'.ord,
        ] of DispatchItem,
      },
      {
        name:  "utf8",
        input: String.new(Bytes[
          0x1b, 0x5d, 0x32, 0x3b, 0x65, 0x63, 0x68, 0x6f, 0x20, 0x27,
          0xc2, 0xaf, 0x5c, 0x5f, 0x28, 0xe3, 0x83, 0x84, 0x29, 0x5f,
          0x2f, 0xc2, 0xaf, 0x27, 0x20, 0x26, 0x26, 0x20, 0x73, 0x6c,
          0x65, 0x65, 0x70, 0x20, 0x31, 0x9c,
        ]),
        expected: ["2;echo '¯\\_(ツ)_/¯' && sleep 1".to_slice] of DispatchItem,
      },
      {
        name:     "string_terminator",
        input:    "\e]2;\xe6\x9c\xab\e\\",
        expected: [
          Bytes[0x32, 0x3b, 0xe6],
          '\\'.ord,
        ] of DispatchItem,
      },
      {
        name:     "exceed_max_buffer_size",
        input:    "\e]52;s#{"a" * max_buffer_size}\a",
        expected: [
          ("52;s" + ("a" * (max_buffer_size - 4))).to_slice,
        ] of DispatchItem,
      },
      {
        name:     "title_empty_params_esc",
        input:    "\e]0;abc\e\\\e]#{";" * 45}\a",
        expected: [
          "0;abc".to_slice,
          '\\'.ord,
          (";" * 45).to_slice,
        ] of DispatchItem,
      },
      {
        name:     "just command",
        input:    "\e]112\a",
        expected: ["112".to_slice] of DispatchItem,
      },
    ]

    cases.each do |test_case|
      dispatcher = TestDispatcher.new
      parser = ParserSpecSupport.test_parser(dispatcher)
      parser.data = Array(UInt8).new(max_buffer_size, 0_u8)
      parser.data_len = max_buffer_size
      parser.parse(test_case[:input])
      dispatcher.dispatched.size.should eq(test_case[:expected].size)
      dispatcher.dispatched.should eq(test_case[:expected])
    end
  end
end
