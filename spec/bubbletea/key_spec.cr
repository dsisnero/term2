require "../spec_helper"

private def decode_one(seq : Bytes) : UV::Event?
  decoder = UV::EventDecoder.new
  _consumed, event = decoder.decode(seq)
  event
end

describe "Bubbletea parity: key_test.go (UV events)" do
  it "formats key strings via ultraviolet" do
    Term2::TestHelpers.uv_key("space").string.should eq("space")
    Term2::TestHelpers.uv_key("a").string.should eq("a")
  end

  it "decodes basic escape sequences" do
    decode_one("\e[A".to_slice).should eq(UV::Key.new(code: UV::KeyUp))
    decode_one("\e[B".to_slice).should eq(UV::Key.new(code: UV::KeyDown))
    decode_one("\e[C".to_slice).should eq(UV::Key.new(code: UV::KeyRight))
    decode_one("\e[D".to_slice).should eq(UV::Key.new(code: UV::KeyLeft))
  end

  it "decodes focus sequences" do
    decode_one("\e[I".to_slice).should be_a(Term2::FocusMsg)
    decode_one("\e[O".to_slice).should be_a(Term2::BlurMsg)
  end

  it "decodes CSI-u sequences" do
    repeat_event = decode_one("\e[97;1:2u".to_slice).as(UV::Key)
    repeat_event.code.should eq('a'.ord)
    repeat_event.is_repeat?.should be_true

    release_event = decode_one("\e[97;1:3u".to_slice).as(UV::Key)
    release_event.code.should eq('a'.ord)
    release_event.is_repeat?.should be_false
  end
end
