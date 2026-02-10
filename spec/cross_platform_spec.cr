require "./spec_helper"

private def decode_one(seq : Bytes) : UV::Event?
  decoder = UV::EventDecoder.new
  _consumed, event = decoder.decode(seq)
  event
end

describe "Cross-Platform Compatibility (UV events)" do
  describe "Terminal escape sequences" do
    it "generates valid ANSI escape sequences for cursor control" do
      output = IO::Memory.new
      Term2::Terminal.hide_cursor(output)
      output.rewind
      output.gets_to_end.should eq("\e[?25l")

      output = IO::Memory.new
      Term2::Terminal.show_cursor(output)
      output.rewind
      output.gets_to_end.should eq("\e[?25h")
    end

    it "generates valid alternate screen sequences" do
      output = IO::Memory.new
      Term2::Terminal.enter_alt_screen(output)
      output.rewind
      output.gets_to_end.should eq("\e[?1049h")

      output = IO::Memory.new
      Term2::Terminal.exit_alt_screen(output)
      output.rewind
      output.gets_to_end.should eq("\e[?1049l")
    end
  end

  describe "Key sequence decoding" do
    it "decodes arrow keys" do
      decode_one("\e[A".to_slice).should eq(UV::Key.new(code: UV::KeyUp))
      decode_one("\e[B".to_slice).should eq(UV::Key.new(code: UV::KeyDown))
      decode_one("\e[C".to_slice).should eq(UV::Key.new(code: UV::KeyRight))
      decode_one("\e[D".to_slice).should eq(UV::Key.new(code: UV::KeyLeft))
    end

    it "decodes focus sequences" do
      decode_one("\e[I".to_slice).should be_a(Term2::FocusMsg)
      decode_one("\e[O".to_slice).should be_a(Term2::BlurMsg)
    end
  end

  describe "Mouse protocol decoding" do
    it "decodes SGR mouse press events" do
      event = decode_one("\e[<0;10;20M".to_slice)
      event.should be_a(UV::MouseClickEvent)
      mouse = event.as(UV::MouseClickEvent).mouse
      mouse.x.should eq(9)
      mouse.y.should eq(19)
      mouse.button.should eq(UV::MouseButton::Left)
    end
  end

  describe "UTF-8 handling" do
    it "handles ASCII characters" do
      key = Term2::TestHelpers.uv_key('a')
      key.text.should eq("a")
      key.string.should eq("a")
    end

    it "handles multi-byte UTF-8 characters" do
      key = Term2::TestHelpers.uv_key('日')
      key.text.should eq("日")
      key.string.should eq("日")
    end
  end
end
