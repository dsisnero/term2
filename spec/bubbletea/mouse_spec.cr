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
      {name: "shift+left press", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, shift: true), expected: "shift+left press"},
      {name: "ctrl+shift+left", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, shift: true, ctrl: true), expected: "ctrl+shift+left press"},
      {name: "alt+left", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, alt: true), expected: "alt+left press"},
      {name: "ctrl+left", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, ctrl: true), expected: "ctrl+left press"},
      {name: "ctrl+alt+left", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, alt: true, ctrl: true), expected: "ctrl+alt+left press"},
      {name: "ctrl+alt+shift+left", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, alt: true, ctrl: true, shift: true), expected: "ctrl+alt+shift+left press"},
      {name: "ignore coords", event: Term2::MouseEvent.new(100, 200, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press), expected: "left press"},
      {name: "broken type", event: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::None, Term2::MouseEvent::Action::Press, type: "unknown"), expected: "unknown"},
    ]

    cases.each do |tc|
      tc[:event].to_s.should eq(tc[:expected])
    end
  end

  it "parses x10 mouse events" do
    encode = ->(b : UInt8, x : Int32, y : Int32) {
      button_code = ((32 + b).to_i % 256).to_u8
      x_code = ((x + 33) % 256).to_u8
      y_code = ((y + 33) % 256).to_u8
      Bytes[0x1b_u8, '['.ord.to_u8, 'M'.ord.to_u8, button_code, x_code, y_code]
    }

    cases = [
      {buf: encode.call(0b0000_0000_u8, 0, 0), expected: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)},
      {buf: encode.call(0b0000_0000_u8, 222, 222), expected: Term2::MouseEvent.new(222, 222, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)},
      {buf: encode.call(0b0000_0000_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)},
      {buf: encode.call(0b0010_0000_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Move)},
      {buf: encode.call(0b0100_0000_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::WheelUp, Term2::MouseEvent::Action::Press)},
      {buf: encode.call(0b0000_0011_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::None, Term2::MouseEvent::Action::Release)},
      {buf: encode.call(0b0000_1010_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Right, Term2::MouseEvent::Action::Press, alt: true)},
      {buf: encode.call(0b0001_1100_u8, 32, 16), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, alt: true, ctrl: true, shift: true)},
      {buf: encode.call(0b0010_0000_u8, 250, 223), expected: Term2::MouseEvent.new(-6, -33, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Move)},
    ]

    cases.each do |tc|
      Term2::Mouse.parse_x10(tc[:buf]).should eq(tc[:expected])
    end
  end

  it "parses SGR mouse events" do
    encode = ->(b : Int32, x : Int32, y : Int32, release : Bool) {
      term = release ? 'm' : 'M'
      str = sprintf("\x1b[<%d;%d;%d%c", b, x + 1, y + 1, term)
      str.to_slice
    }

    cases = [
      {buf: encode.call(0, 0, 0, false), expected: Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)},
      {buf: encode.call(0, 225, 225, false), expected: Term2::MouseEvent.new(225, 225, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)},
      {buf: encode.call(0, 32, 16, true), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Release)},
      {buf: encode.call(33, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::Middle, Term2::MouseEvent::Action::Move)},
      {buf: encode.call(65, 32, 16, false), expected: Term2::MouseEvent.new(32, 16, Term2::MouseEvent::Button::WheelDown, Term2::MouseEvent::Action::Press)},
    ]

    cases.each do |tc|
      Term2::Mouse.parse_sgr(tc[:buf]).should eq(tc[:expected])
    end
  end
end
