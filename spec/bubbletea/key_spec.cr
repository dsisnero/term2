require "../spec_helper"

def base_seq_tests : Array(NamedTuple(seq: Bytes, msg: Term2::Msg))
  tests = [] of NamedTuple(seq: Bytes, msg: Term2::Msg)
  Term2::KeySequences::SEQUENCES.each do |seq, key|
    tests << {seq: seq.to_slice, msg: Term2::KeyMsg.new(key)}
    unless key.alt?
      alt_key = Term2::Key.new(key.type, key.runes, alt: true)
      tests << {seq: "\e#{seq}".to_slice, msg: Term2::KeyMsg.new(alt_key)}
    end
  end

  (Term2::KeyType::CtrlAt.value + 1).upto(31) do |code|
    next if code == Term2::KeyType::Esc.value
    tests << {seq: Bytes[code.to_u8], msg: Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType.new(code)))}
    tests << {seq: Bytes[0x1b_u8, code.to_u8], msg: Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType.new(code), alt: true))}
  end
  tests << {seq: Bytes[Term2::KeyType::Backspace.value.to_u8], msg: Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Backspace))}
  tests << {seq: Bytes[0x1b_u8, Term2::KeyType::Backspace.value.to_u8], msg: Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Backspace, alt: true))}

  tests << {seq: Bytes[0x1b_u8, '['.ord.to_u8, '-'.ord.to_u8, '-'.ord.to_u8, '-'.ord.to_u8, '-'.ord.to_u8, 'X'.ord.to_u8], msg: Term2::UnknownCSISequenceMsg.new(Bytes[0x1b_u8, '['.ord.to_u8, '-'.ord.to_u8, '-'.ord.to_u8, '-'.ord.to_u8, '-'.ord.to_u8, 'X'.ord.to_u8])}
  tests << {seq: Bytes[0x20_u8], msg: Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Runes, runes: [' ']))}
  tests << {seq: Bytes[0x1b_u8, 0x20_u8], msg: Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Runes, runes: [' '], alt: true))}
  tests
end

describe "Bubbletea parity: key_test.go" do
  it "formats key msg strings" do
    Term2::KeyMsg.new(Term2::Key.new(type: Term2::KeyType::Space, alt: true)).to_s.should eq("alt+ ")
    Term2::KeyMsg.new(Term2::Key.new(runes: ['a'])).to_s.should eq("a")
    Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType.new(99999))).to_s.should eq("")
  end

  it "formats key type strings" do
    Term2::KeyType::Space.to_s.should eq(" ")
    Term2::KeyType.new(99999).to_s.should eq("")
  end

  it "detect_sequence matches Go cases" do
    base_seq_tests.each do |test_case|
      has_seq, width, msg = Term2::KeySequences.detect_sequence(test_case[:seq])
      has_seq.should be_true
      width.should eq(test_case[:seq].size)
      msg.should eq(test_case[:msg])
    end
  end

  it "detect_one_msg matches Go cases" do
    tests = base_seq_tests
    tests += [
      {seq: Term2::KeySequences::FOCUS_IN_SEQ.to_slice, msg: Term2::FocusMsg.new},
      {seq: Term2::KeySequences::FOCUS_OUT_SEQ.to_slice, msg: Term2::BlurMsg.new},
      {seq: Bytes['a'.ord.to_u8], msg: Term2::KeyMsg.new(Term2::Key.new(runes: ['a']))},
      {seq: Bytes[0x1b_u8, 'a'.ord.to_u8], msg: Term2::KeyMsg.new(Term2::Key.new(runes: ['a'], alt: true))},
      {seq: "☃".encode("UTF-8").to_slice, msg: Term2::KeyMsg.new(Term2::Key.new(runes: ['☃']))},
      {seq: Bytes[0x1b_u8], msg: Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Esc))},
      {seq: Bytes[Term2::KeyType::CtrlA.value.to_u8], msg: Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::CtrlA))},
      {seq: Bytes[0x1b_u8, Term2::KeyType::CtrlA.value.to_u8], msg: Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::CtrlA, alt: true))},
      {seq: Bytes[Term2::KeyType::Null.value.to_u8], msg: Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::CtrlAt))},
      {seq: Bytes[0x1b_u8, Term2::KeyType::Null.value.to_u8], msg: Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::CtrlAt, alt: true))},
    ]

    tests.each do |test_case|
      has_seq, width, msg = Term2::KeySequences.detect_one_msg(test_case[:seq])
      has_seq.should be_true
      width.should eq(test_case[:seq].size)
      msg.should eq(test_case[:msg])
    end
  end
end
