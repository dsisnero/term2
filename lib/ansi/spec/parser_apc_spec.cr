require "./parser_support_spec"

include ParserSpecSupport

describe "Ansi::Parser" do
  it "parses SOS/PM/APC sequences" do
    cases = [
      {
        name:     "apc7",
        input:    "\e_Gf=24,s=10,v=20,o=z;aGVsbG8gd29ybGQ=\e\\",
        expected: [
          "Gf=24,s=10,v=20,o=z;aGVsbG8gd29ybGQ=".to_slice,
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
