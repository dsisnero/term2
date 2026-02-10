ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"

private def decode_one(seq : Bytes) : UV::Event?
  decoder = UV::EventDecoder.new
  _consumed, event = decoder.decode(seq)
  event
end

describe "Ultraviolet mouse decoding" do
  it "decodes SGR mouse sequences" do
    event = decode_one("\e[<0;45;3M".to_slice)
    event.should be_a(UV::MouseClickEvent)
    mouse = event.as(UV::MouseClickEvent).mouse
    mouse.x.should eq(44) # SGR uses 1-based; UV normalizes to 0-based
    mouse.y.should eq(2)
    mouse.button.should eq(UV::MouseButton::Left)
  end
end
