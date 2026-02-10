require "../spec_helper"

private def decode_one(seq : Bytes) : UV::Event?
  decoder = UV::EventDecoder.new
  _consumed, event = decoder.decode(seq)
  event
end

describe "Bubbletea parity: mouse_test.go (UV events)" do
  it "formats mouse event strings via ultraviolet" do
    mouse = UV::Mouse.new(x: 0, y: 0, button: UV::MouseButton::Left, mod: 0)
    mouse.string.should eq("left")
  end

  it "decodes SGR mouse press events" do
    event = decode_one("\e[<0;10;20M".to_slice)
    event.should be_a(UV::MouseClickEvent)
    mouse = event.as(UV::MouseClickEvent).mouse
    mouse.x.should eq(9)
    mouse.y.should eq(19)
    mouse.button.should eq(UV::MouseButton::Left)
  end
end
