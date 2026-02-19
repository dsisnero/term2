require "./spec_helper"

struct ExpectedSequence
  getter seq : Bytes
  getter n : Int32
  getter width : Int32
  getter params : Array(Int32)
  getter data : Bytes
  getter cmd : Int32

  def initialize(
    @seq : Bytes,
    @n : Int32,
    @width : Int32 = 0,
    @params : Array(Int32) = [] of Int32,
    @data : Bytes = Bytes.new(0),
    @cmd : Int32 = 0,
  )
  end
end

describe "Ansi.decode_sequence" do
  it "decodes sequences" do
    array_to_bytes = ->(array : Array(UInt8)) { Bytes.new(array.size) { |i| array[i] } }
    cases = [
      {
        name:     "single byte",
        input:    Bytes[0x1b],
        expected: [ExpectedSequence.new(Bytes[0x1b], 1)],
      },
      {
        name:     "single byte 2",
        input:    Bytes[0x00],
        expected: [ExpectedSequence.new(Bytes[0x00], 1)],
      },
      {
        name:     "ASCII printable",
        input:    "a".to_slice,
        expected: [ExpectedSequence.new(Bytes['a'.ord.to_u8], 1, 1)],
      },
      {
        name:     "ASCII space",
        input:    " ".to_slice,
        expected: [ExpectedSequence.new(Bytes[' '.ord.to_u8], 1, 1)],
      },
      {
        name:     "ASCII DEL",
        input:    Bytes[Ansi::DEL],
        expected: [ExpectedSequence.new(Bytes[Ansi::DEL], 1)],
      },
      {
        name:     "DEL in the middle of UTF8 string",
        input:    Bytes['a'.ord.to_u8, Ansi::DEL, 'b'.ord.to_u8],
        expected: [
          ExpectedSequence.new(Bytes['a'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes[Ansi::DEL], 1),
          ExpectedSequence.new(Bytes['b'.ord.to_u8], 1, 1),
        ],
      },
      {
        name:     "DEL in the middle of DCS",
        input:    "\eP1;2+xa\x7fb\e\\".to_slice,
        expected: [
          ExpectedSequence.new(
            "\eP1;2+xa\x7fb\e\\".to_slice,
            12,
            0,
            [1, 2],
            Bytes['a'.ord.to_u8, Ansi::DEL, 'b'.ord.to_u8],
            'x'.ord | ('+'.ord << Ansi::ParserTransition::IntermedShift)
          ),
        ],
      },
      {
        name:     "ST in the middle of DCS",
        input:    "\eP1;2+xa\x9cb\e\\".to_slice,
        expected: [
          ExpectedSequence.new(
            "\eP1;2+xa\x9c".to_slice,
            9,
            0,
            [1, 2],
            Bytes['a'.ord.to_u8],
            'x'.ord | ('+'.ord << Ansi::ParserTransition::IntermedShift)
          ),
          ExpectedSequence.new(Bytes['b'.ord.to_u8], 1, 1),
          ExpectedSequence.new("\e\\".to_slice, 2, 0, [] of Int32, Bytes.new(0), '\\'.ord),
        ],
      },
      {
        name:     "CSI style sequence",
        input:    "\e[1;2;3m".to_slice,
        expected: [
          ExpectedSequence.new(
            "\e[1;2;3m".to_slice,
            8,
            0,
            [1, 2, 3],
            Bytes.new(0),
            'm'.ord
          ),
        ],
      },
      {
        name:     "invalid unterminated CSI sequence",
        input:    "\e[1;2;3".to_slice,
        expected: [
          ExpectedSequence.new(
            "\e[1;2;3".to_slice,
            7,
            0,
            [1, 2],
            Bytes.new(0),
            0
          ),
        ],
      },
      {
        name:     "set title OSC sequence",
        input:    "\e]2;charmbracelet: ~/Source/bubbletea\a".to_slice,
        expected: [
          ExpectedSequence.new(
            "\e]2;charmbracelet: ~/Source/bubbletea\a".to_slice,
            38,
            0,
            [] of Int32,
            "2;charmbracelet: ~/Source/bubbletea".to_slice,
            2
          ),
        ],
      },
      {
        name:     "set background OSC sequence with 7-bit ST terminator",
        input:    "\e]11;ff/00/ff\e\\".to_slice,
        expected: [
          ExpectedSequence.new(
            "\e]11;ff/00/ff\e\\".to_slice,
            15,
            0,
            [] of Int32,
            "11;ff/00/ff".to_slice,
            11
          ),
        ],
      },
      {
        name:     "set background OSC sequence with ST 8-bit terminator",
        input:    "\e]11;ff/00/ff\x9c\eaa\x8fa".to_slice,
        expected: [
          ExpectedSequence.new(
            "\e]11;ff/00/ff\x9c".to_slice,
            14,
            0,
            [] of Int32,
            "11;ff/00/ff".to_slice,
            11
          ),
          ExpectedSequence.new(Bytes[Ansi::ESC, 'a'.ord.to_u8], 2, 0, [] of Int32, Bytes.new(0), 'a'.ord),
          ExpectedSequence.new(Bytes['a'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes[Ansi::SS3], 1),
          ExpectedSequence.new(Bytes['a'.ord.to_u8], 1, 1),
        ],
      },
      {
        name:     "set background OSC sequence followed by ESC sequence",
        input:    "\e]11;ff/00/ff\e[1;2;3m".to_slice,
        expected: [
          ExpectedSequence.new(
            "\e]11;ff/00/ff".to_slice,
            13,
            0,
            [] of Int32,
            "11;ff/00/ff".to_slice,
            11
          ),
          ExpectedSequence.new(
            "\e[1;2;3m".to_slice,
            8,
            0,
            [1, 2, 3],
            Bytes.new(0),
            'm'.ord
          ),
        ],
      },
      {
        name:     "set background OSC ESC terminated",
        input:    "\e]11;ff/00/ff\e".to_slice,
        expected: [
          ExpectedSequence.new(
            "\e]11;ff/00/ff".to_slice,
            13,
            0,
            [] of Int32,
            "11;ff/00/ff".to_slice,
            11
          ),
          ExpectedSequence.new(Bytes[Ansi::ESC], 1),
        ],
      },
      {
        name:     "multiple sequences",
        input:    "\e[1;2;3m\e]2;charmbracelet: ~/Source/bubbletea\a\e]11;ff/00/ff\e\\".to_slice,
        expected: [
          ExpectedSequence.new("\e[1;2;3m".to_slice, 8, 0, [1, 2, 3], Bytes.new(0), 'm'.ord),
          ExpectedSequence.new("\e]2;charmbracelet: ~/Source/bubbletea\a".to_slice, 38, 0, [] of Int32, "2;charmbracelet: ~/Source/bubbletea".to_slice, 2),
          ExpectedSequence.new("\e]11;ff/00/ff\e\\".to_slice, 15, 0, [] of Int32, "11;ff/00/ff".to_slice, 11),
        ],
      },
      {
        name:     "double ESC",
        input:    "\e\e".to_slice,
        expected: [
          ExpectedSequence.new(Bytes[Ansi::ESC], 1),
          ExpectedSequence.new(Bytes[Ansi::ESC], 1),
        ],
      },
      {
        name:     "double ST",
        input:    "\e\\\e\\".to_slice,
        expected: [
          ExpectedSequence.new(Bytes[Ansi::ESC, '\\'.ord.to_u8], 2, 0, [] of Int32, Bytes.new(0), '\\'.ord),
          ExpectedSequence.new(Bytes[Ansi::ESC, '\\'.ord.to_u8], 2, 0, [] of Int32, Bytes.new(0), '\\'.ord),
        ],
      },
      {
        name:     "double ST 8-bit",
        input:    Bytes[Ansi::ST, Ansi::ST],
        expected: [
          ExpectedSequence.new(Bytes[Ansi::ST], 1),
          ExpectedSequence.new(Bytes[Ansi::ST], 1),
        ],
      },
      {
        name:     "ASCII printables",
        input:    "Hello, World!".to_slice,
        expected: [
          ExpectedSequence.new(Bytes['H'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['e'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['l'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['l'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['o'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes[','.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes[' '.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['W'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['o'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['r'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['l'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['d'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['!'.ord.to_u8], 1, 1),
        ],
      },
      {
        name:     "rune",
        input:    "👋".to_slice,
        expected: [ExpectedSequence.new("👋".to_slice, 4, 2)],
      },
      {
        name:     "inavlid rune",
        input:    Bytes[0xc3],
        expected: [ExpectedSequence.new(Bytes[0xc3], 1, 1)],
      },
      {
        name:     "multiple sequences with UTF8 and double ESC",
        input:    "👨🏿‍🌾\e\e \e[?1:2:3mÄabc\e\eP+q\e\\".to_slice,
        expected: [
          ExpectedSequence.new("👨🏿‍🌾".to_slice, 15, 2),
          ExpectedSequence.new(Bytes[Ansi::ESC], 1),
          ExpectedSequence.new(Bytes[Ansi::ESC, ' '.ord.to_u8], 2, 0, [] of Int32, Bytes.new(0), 0 | (' '.ord << Ansi::ParserTransition::IntermedShift)),
          ExpectedSequence.new(
            "\e[?1:2:3m".to_slice,
            9,
            0,
            [1 | Ansi::ParserTransition::HasMoreFlag, 2 | Ansi::ParserTransition::HasMoreFlag, 3],
            Bytes.new(0),
            'm'.ord | ('?'.ord << Ansi::ParserTransition::PrefixShift)
          ),
          ExpectedSequence.new("Ä".to_slice, 2, 1),
          ExpectedSequence.new(Bytes['a'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['b'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['c'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes[Ansi::ESC], 1),
          ExpectedSequence.new("\eP+q\e\\".to_slice, 6, 0, [] of Int32, Bytes.new(0), 'q'.ord | ('+'.ord << Ansi::ParserTransition::IntermedShift)),
        ],
      },
      {
        name:     "style sequences",
        input:    "hello, \e[1;2;3mworld\e[0m!".to_slice,
        expected: [
          ExpectedSequence.new(Bytes['h'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['e'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['l'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['l'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['o'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes[','.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes[' '.ord.to_u8], 1, 1),
          ExpectedSequence.new("\e[1;2;3m".to_slice, 8, 0, [1, 2, 3], Bytes.new(0), 'm'.ord),
          ExpectedSequence.new(Bytes['w'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['o'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['r'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['l'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['d'.ord.to_u8], 1, 1),
          ExpectedSequence.new("\e[0m".to_slice, 4, 0, [0], Bytes.new(0), 'm'.ord),
          ExpectedSequence.new(Bytes['!'.ord.to_u8], 1, 1),
        ],
      },
      {
        name:     "set background OSC with C1",
        input:    "\e]11;\x90?\e\\".to_slice,
        expected: [
          ExpectedSequence.new(
            "\e]11;\x90?\e\\".to_slice,
            9,
            0,
            [] of Int32,
            "11;\x90?".to_slice,
            11
          ),
        ],
      },
      {
        name:     "unterminated CSI with escape sequence",
        input:    "\e[1;2;3\eOa".to_slice,
        expected: [
          ExpectedSequence.new("\e[1;2;3".to_slice, 7, 0, [1, 2, 3], Bytes.new(0), 0),
          ExpectedSequence.new("\eO".to_slice, 2, 0, [] of Int32, Bytes.new(0), 'O'.ord),
          ExpectedSequence.new(Bytes['a'.ord.to_u8], 1, 1),
        ],
      },
      {
        name:     "SS3",
        input:    "\eOa".to_slice,
        expected: [
          ExpectedSequence.new("\eO".to_slice, 2, 0, [] of Int32, Bytes.new(0), 'O'.ord),
          ExpectedSequence.new(Bytes['a'.ord.to_u8], 1, 1),
        ],
      },
      {
        name:     "SS3 8-bit",
        input:    Bytes[Ansi::SS3, 'a'.ord.to_u8],
        expected: [
          ExpectedSequence.new(Bytes[Ansi::SS3], 1),
          ExpectedSequence.new(Bytes['a'.ord.to_u8], 1, 1),
        ],
      },
      {
        name:     "ESC sequence with intermediate",
        input:    "\e Q".to_slice,
        expected: [
          ExpectedSequence.new("\e Q".to_slice, 3, 0, [] of Int32, Bytes.new(0), 'Q'.ord | (' '.ord << Ansi::ParserTransition::IntermedShift)),
        ],
      },
      {
        name:     "ESC followed by C0",
        input:    Bytes[Ansi::ESC, '['.ord.to_u8, 0x00, 'a'.ord.to_u8],
        expected: [
          ExpectedSequence.new(Bytes[Ansi::ESC, '['.ord.to_u8], 2),
          ExpectedSequence.new(Bytes[0x00], 1),
          ExpectedSequence.new(Bytes['a'.ord.to_u8], 1, 1),
        ],
      },
      {
        name:     "unterminated DCS sequence",
        input:    "\eP1;2+xa".to_slice,
        expected: [
          ExpectedSequence.new("\eP1;2+xa".to_slice, 8, 0, [1, 2], Bytes['a'.ord.to_u8], 'x'.ord | ('+'.ord << Ansi::ParserTransition::IntermedShift)),
        ],
      },
      {
        name:     "invalid DCS sequence",
        input:    "\eP\e\\ab".to_slice,
        expected: [
          ExpectedSequence.new("\eP".to_slice, 2),
          ExpectedSequence.new("\e\\".to_slice, 2, 0, [] of Int32, Bytes.new(0), '\\'.ord),
          ExpectedSequence.new(Bytes['a'.ord.to_u8], 1, 1),
          ExpectedSequence.new(Bytes['b'.ord.to_u8], 1, 1),
        ],
      },
      {
        name:     "single param osc",
        input:    "\e]112\a".to_slice,
        expected: [
          ExpectedSequence.new("\e]112\a".to_slice, 6, 0, [] of Int32, "112".to_slice, 112),
        ],
      },
    ]

    cases.each do |test_case|
      parser = Ansi::Parser.new
      parser.set_params_size(32)
      parser.set_data_size(1024)

      state = 0_u8
      input = test_case[:input]
      results = [] of ExpectedSequence

      while input.size > 0
        seq, width, n, new_state = Ansi.decode_sequence(input, state, parser)
        params = parser.params[0, parser.params_len].dup
        data = if parser.data_len >= 0
                 array_to_bytes.call(parser.data[0, parser.data_len])
               else
                 array_to_bytes.call(parser.data)
               end
        results << ExpectedSequence.new(seq, n, width, params, data, parser.cmd)
        state = new_state
        input = input[n, input.size - n]
      end

      results.size.should eq(test_case[:expected].size)
      results.each_with_index do |result, index|
        expected = test_case[:expected][index]
        result.n.should eq(expected.n)
        result.width.should eq(expected.width)
        result.seq.should eq(expected.seq)
        result.cmd.should eq(expected.cmd)
        result.data.should eq(expected.data)
        result.params.size.should eq(expected.params.size)
        result.params.should eq(expected.params) if expected.params.size > 0
      end
    end
  end

  describe "Ansi.command" do
    it "computes command integers" do
      cases = [
        {
          name:     "CUU", # Cursor Up
          cmd:      'A'.ord.to_u8,
          prefix:   0_u8,
          inter:    0_u8,
          expected: 'A'.ord,
        },
        {
          name:     "DECAWM", # Auto Wrap Mode
          cmd:      'h'.ord.to_u8,
          prefix:   '?'.ord.to_u8,
          inter:    0_u8,
          expected: 'h'.ord | ('?'.ord << Ansi::ParserTransition::PrefixShift),
        },
        {
          name:     "DECSCUSR", # Set Cursor Style
          cmd:      'q'.ord.to_u8,
          prefix:   0_u8,
          inter:    ' '.ord.to_u8,
          expected: 'q'.ord | (' '.ord << Ansi::ParserTransition::IntermedShift),
        },
        {
          name:     "imaginary cmd with both prefix and intermed",
          cmd:      'x'.ord.to_u8,
          prefix:   '>'.ord.to_u8,
          inter:    '('.ord.to_u8,
          expected: 'x'.ord | ('>'.ord << Ansi::ParserTransition::PrefixShift) | ('('.ord << Ansi::ParserTransition::IntermedShift),
        },
        {
          name:     "OSC11", # Set background color
          cmd:      11_u8,
          prefix:   0_u8,
          inter:    0_u8,
          expected: 11,
        },
      ]

      cases.each do |test_case|
        result = Ansi.command(test_case[:prefix], test_case[:inter], test_case[:cmd])
        result.should eq(test_case[:expected])
      end
    end
  end

  describe "Ansi.parameter" do
    it "computes parameter integers" do
      cases = [
        {
          name:     "single param",
          param:    1,
          has_more: false,
          expected: 1,
        },
        {
          name:     "single param with hasMore",
          param:    1,
          has_more: true,
          expected: 1 | Ansi::ParserTransition::HasMoreFlag,
        },
        {
          name:     "negative param",
          param:    -1,
          has_more: false,
          expected: Ansi::ParserTransition::ParamMask,
        },
        {
          name:     "negative param has more",
          param:    -1,
          has_more: true,
          expected: -1,
        },
      ]

      cases.each do |test_case|
        result = Ansi.parameter(test_case[:param], test_case[:has_more])
        result.should eq(test_case[:expected])
      end
    end
  end
end
