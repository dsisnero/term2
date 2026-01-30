require "../spec_helper"

describe "Bubbletea parity: mouse_test.go" do
  it "formats mouse event strings" do
    cases = [
      {name: "unknown", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::None, Term2::MouseEvent::Action::Press), expected: "unknown"},
      {name: "left", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press), expected: "left press"},
      {name: "right", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Right, Term2::MouseEvent::Action::Press), expected: "right press"},
      {name: "middle", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Middle, Term2::MouseEvent::Action::Press), expected: "middle press"},
      {name: "release", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::None, Term2::MouseEvent::Action::Release), expected: "release"},
      {name: "wheel up", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::WheelUp, Term2::MouseEvent::Action::Press), expected: "wheel up"},
      {name: "wheel down", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::WheelDown, Term2::MouseEvent::Action::Press), expected: "wheel down"},
      {name: "wheel left", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::WheelLeft, Term2::MouseEvent::Action::Press), expected: "wheel left"},
      {name: "wheel right", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::WheelRight, Term2::MouseEvent::Action::Press), expected: "wheel right"},
      {name: "motion", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::None, Term2::MouseEvent::Action::Move), expected: "motion"},
      {name: "shift+left release", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Release, shift: true), expected: "shift+left release"},
      {name: "shift+left", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, shift: true), expected: "shift+left press"},
      {name: "ctrl+shift+left", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, shift: true, ctrl: true), expected: "ctrl+shift+left press"},
      {name: "alt+left", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, alt: true), expected: "alt+left press"},
      {name: "ctrl+left", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, ctrl: true), expected: "ctrl+left press"},
      {name: "ctrl+alt+left", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, alt: true, ctrl: true), expected: "ctrl+alt+left press"},
      {name: "ctrl+alt+shift+left", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, alt: true, ctrl: true, shift: true), expected: "ctrl+alt+shift+left press"},
      {name: "ignore coordinates", event: Term2::MouseEvent.new(100, 200, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press), expected: "left press"},
    ]

    cases.each do |tc|
      tc[:event].to_s.should eq(tc[:expected])
    end
  end

  it "parses x10 mouse events" do
    encode = ->(b : UInt8, x : Int32, y : Int32) {
      Bytes[0x1b_u8, '['.ord.to_u8, 'M'.ord.to_u8, ((32 + b).to_i % 256).to_u8, ((x + 33) % 256).to_u8, ((y + 33) % 256).to_u8]
    }

    cases = [
      {name: "zero position", buf: encode.call(0b0000_0000_u8, 0, 0), expected: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)},
      {name: "max position", buf: encode.call(0b0000_0000_u8, 222, 222), expected: Term2::MouseEvent.new(222, 222, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)},
      {name: "left", buf: encode.call(0b0000_0000_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)},
      {name: "left in motion", buf: encode.call(0b0010_0000_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Move)},
      {name: "middle", buf: encode.call(0b0000_0001_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Middle, Term2::MouseEvent::Action::Press)},
      {name: "middle in motion", buf: encode.call(0b0010_0001_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Middle, Term2::MouseEvent::Action::Move)},
      {name: "right", buf: encode.call(0b0000_0010_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Right, Term2::MouseEvent::Action::Press)},
      {name: "right in motion", buf: encode.call(0b0010_0010_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Right, Term2::MouseEvent::Action::Move)},
      {name: "motion", buf: encode.call(0b0010_0011_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::None, Term2::MouseEvent::Action::Move)},
      {name: "wheel up", buf: encode.call(0b0100_0000_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::WheelUp, Term2::MouseEvent::Action::Press)},
      {name: "wheel down", buf: encode.call(0b0100_0001_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::WheelDown, Term2::MouseEvent::Action::Press)},
      {name: "wheel left", buf: encode.call(0b0100_0010_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::WheelLeft, Term2::MouseEvent::Action::Press)},
      {name: "wheel right", buf: encode.call(0b0100_0011_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::WheelRight, Term2::MouseEvent::Action::Press)},
      {name: "release", buf: encode.call(0b0000_0011_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::None, Term2::MouseEvent::Action::Release)},
      {name: "backward", buf: encode.call(0b1000_0000_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Backward, Term2::MouseEvent::Action::Press)},
      {name: "forward", buf: encode.call(0b1000_0001_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Forward, Term2::MouseEvent::Action::Press)},
      {name: "button10", buf: encode.call(0b1000_0010_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Button10, Term2::MouseEvent::Action::Press)},
      {name: "button11", buf: encode.call(0b1000_0011_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Button11, Term2::MouseEvent::Action::Press)},
      {name: "alt+right", buf: encode.call(0b0000_1010_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Right, Term2::MouseEvent::Action::Press, alt: true)},
      {name: "ctrl+right", buf: encode.call(0b0001_0010_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Right, Term2::MouseEvent::Action::Press, ctrl: true)},
      {name: "ctrl+alt+right", buf: encode.call(0b0001_1010_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Right, Term2::MouseEvent::Action::Press, alt: true, ctrl: true)},
      {name: "ctrl+wheel up", buf: encode.call(0b0101_0000_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::WheelUp, Term2::MouseEvent::Action::Press, ctrl: true)},
      {name: "alt+wheel down", buf: encode.call(0b0100_1001_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::WheelDown, Term2::MouseEvent::Action::Press, alt: true)},
      {name: "ctrl+alt+wheel down", buf: encode.call(0b0101_1001_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::WheelDown, Term2::MouseEvent::Action::Press, alt: true, ctrl: true)},
      {name: "overflow position", buf: encode.call(0b0010_0000_u8, 250, 223), expected: Term2::MouseEvent.new(-6, -33, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Move)},
    ]

    cases.each do |tc|
      Term2::Mouse.parse_x10(tc[:buf]).should eq(tc[:expected])
    end
  end

  it "parses SGR mouse events" do
    encode = ->(b : Int32, x : Int32, y : Int32, release : Bool) {
      term = release ? 'm' : 'M'
      String.build do |str|
        str << "\x1b[<"
        str << b
        str << ';'
        str << (x + 1)
        str << ';'
        str << (y + 1)
        str << term
      end.to_slice
    }

    cases = [
      {name: "zero position", buf: encode.call(0, 0, 0, false), expected: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)},
      {name: "225 position", buf: encode.call(0, 225, 225, false), expected: Term2::MouseEvent.new(225, 225, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)},
      {name: "left", buf: encode.call(0, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)},
      {name: "left in motion", buf: encode.call(32, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Move)},
      {name: "left release", buf: encode.call(0, 32, 16, true), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Release)},
      {name: "middle", buf: encode.call(1, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Middle, Term2::MouseEvent::Action::Press)},
      {name: "middle in motion", buf: encode.call(33, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Middle, Term2::MouseEvent::Action::Move)},
      {name: "middle release", buf: encode.call(1, 32, 16, true), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Middle, Term2::MouseEvent::Action::Release)},
      {name: "right", buf: encode.call(2, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Right, Term2::MouseEvent::Action::Press)},
      {name: "right release", buf: encode.call(2, 32, 16, true), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Right, Term2::MouseEvent::Action::Release)},
      {name: "motion", buf: encode.call(35, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::None, Term2::MouseEvent::Action::Move)},
      {name: "wheel up", buf: encode.call(64, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::WheelUp, Term2::MouseEvent::Action::Press)},
      {name: "wheel down", buf: encode.call(65, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::WheelDown, Term2::MouseEvent::Action::Press)},
      {name: "wheel left", buf: encode.call(66, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::WheelLeft, Term2::MouseEvent::Action::Press)},
      {name: "wheel right", buf: encode.call(67, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::WheelRight, Term2::MouseEvent::Action::Press)},
      {name: "backward", buf: encode.call(128, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Backward, Term2::MouseEvent::Action::Press)},
      {name: "backward in motion", buf: encode.call(160, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Backward, Term2::MouseEvent::Action::Move)},
      {name: "forward", buf: encode.call(129, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Forward, Term2::MouseEvent::Action::Press)},
      {name: "forward in motion", buf: encode.call(161, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Forward, Term2::MouseEvent::Action::Move)},
      {name: "alt+right", buf: encode.call(10, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Right, Term2::MouseEvent::Action::Press, alt: true)},
      {name: "ctrl+right", buf: encode.call(18, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Right, Term2::MouseEvent::Action::Press, ctrl: true)},
      {name: "ctrl+alt+right", buf: encode.call(26, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Right, Term2::MouseEvent::Action::Press, alt: true, ctrl: true)},
      {name: "alt+wheel press", buf: encode.call(73, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::WheelDown, Term2::MouseEvent::Action::Press, alt: true)},
      {name: "ctrl+wheel press", buf: encode.call(81, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::WheelDown, Term2::MouseEvent::Action::Press, ctrl: true)},
      {name: "ctrl+alt+wheel press", buf: encode.call(89, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::WheelDown, Term2::MouseEvent::Action::Press, alt: true, ctrl: true)},
      {name: "ctrl+alt+shift+wheel press", buf: encode.call(93, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::WheelDown, Term2::MouseEvent::Action::Press, alt: true, ctrl: true, shift: true)},
    ]

    cases.each do |tc|
      Term2::Mouse.parse_sgr(tc[:buf]).should eq(tc[:expected])
    end
  end
end
