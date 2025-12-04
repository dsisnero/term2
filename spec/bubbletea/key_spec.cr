require "../spec_helper"

describe "Bubbletea parity: key_test.go" do
  it "key msg string formatting" do
    Term2::KeyMsg.new(Term2::Key.new(type: Term2::KeyType::Space, alt: true)).to_s.should eq("alt+ ")
    Term2::KeyMsg.new(Term2::Key.new(runes: ['a'])).to_s.should eq("a")
    Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType.new(99999))).to_s.should eq("")
  end

  it "key type string formatting" do
    Term2::KeyType::Space.to_s.should eq(" ")
    Term2::KeyType.new(99999).to_s.should eq("")
  end

  it "detect_sequence matches known sequences and alt variants" do
    Term2::KeySequences::SEQUENCES.each do |seq, key|
      has_seq, width, msg = Term2::KeySequences.detect_sequence(seq.to_slice)
      has_seq.should be_true
      width.should eq(seq.bytesize)
      msg.should eq(Term2::KeyMsg.new(key))

      unless key.alt?
        alt_seq = "\e#{seq}"
        has_seq, width, msg = Term2::KeySequences.detect_sequence(alt_seq.to_slice)
        has_seq.should be_true
        width.should eq(alt_seq.bytesize)
        msg.should eq(Term2::KeyMsg.new(Term2::Key.new(key.type, key.runes, alt: true)))
      end
    end
  end

  it "detect_sequence handles control chars and space with alt" do
    has_seq, width, msg = Term2::KeySequences.detect_sequence(Bytes[0x20]) # space
    has_seq.should be_true
    msg.should eq(Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Runes, runes: [' '])))
    width.should eq(1)

    has_seq, width, msg = Term2::KeySequences.detect_sequence(Bytes[0x1b, 0x20]) # alt+space
    has_seq.should be_true
    msg.should eq(Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Runes, runes: [' '], alt: true)))
    width.should eq(2)

    has_seq, width, msg = Term2::KeySequences.detect_sequence(Bytes[0x1b]) # esc
    has_seq.should be_true
    msg.should eq(Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Esc)))
    width.should eq(1)
  end

  it "detect_one_msg parses focus/blur and runes" do
    has_seq, width, msg = Term2::KeySequences.detect_one_msg(Term2::KeySequences::FOCUS_IN_SEQ.to_slice)
    has_seq.should be_true
    width.should eq(Term2::KeySequences::FOCUS_IN_SEQ.bytesize)
    msg.should be_a(Term2::FocusMsg)

    has_seq, width, msg = Term2::KeySequences.detect_one_msg(Term2::KeySequences::FOCUS_OUT_SEQ.to_slice)
    has_seq.should be_true
    width.should eq(Term2::KeySequences::FOCUS_OUT_SEQ.bytesize)
    msg.should be_a(Term2::BlurMsg)

    has_seq, width, msg = Term2::KeySequences.detect_one_msg(Bytes[('a'.ord.to_u8)])
    has_seq.should be_true
    msg.should eq(Term2::KeyMsg.new(Term2::Key.new(runes: ['a'])))
    width.should eq(1)

    has_seq, width, msg = Term2::KeySequences.detect_one_msg(Bytes[0x1b_u8, 'a'.ord.to_u8])
    has_seq.should be_true
    msg.should eq(Term2::KeyMsg.new(Term2::Key.new(runes: ['a'], alt: true)))
    width.should eq(2)
  end
end
