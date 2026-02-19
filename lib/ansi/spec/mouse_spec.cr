require "./spec_helper"

describe "Ansi mouse helpers" do
  describe ".encode_mouse_button" do
    cases = [
      {"mouse release", Ansi::MouseNone, false, false, false, false, 0b0000_0011_u8},
      {"mouse release with ctrl", Ansi::MouseNone, false, false, false, true, 0b0001_0011_u8},
      {"mouse left", Ansi::MouseLeft, false, false, false, false, 0b0000_0000_u8},
      {"mouse right", Ansi::MouseRight, false, false, false, false, 0b0000_0010_u8},
      {"mouse wheel up", Ansi::MouseWheelUp, false, false, false, false, 0b0100_0000_u8},
      {"mouse wheel right", Ansi::MouseWheelRight, false, false, false, false, 0b0100_0011_u8},
      {"mouse backward", Ansi::MouseBackward, false, false, false, false, 0b1000_0000_u8},
      {"mouse forward", Ansi::MouseForward, false, false, false, false, 0b1000_0001_u8},
      {"mouse button 10", Ansi::MouseButton10, false, false, false, false, 0b1000_0010_u8},
      {"mouse button 11", Ansi::MouseButton11, false, false, false, false, 0b1000_0011_u8},
      {"mouse middle with motion", Ansi::MouseMiddle, true, false, false, false, 0b0010_0001_u8},
      {"mouse middle with shift", Ansi::MouseMiddle, false, true, false, false, 0b0000_0101_u8},
      {"mouse middle with motion and alt", Ansi::MouseMiddle, true, false, true, false, 0b0010_1001_u8},
      {"mouse right with shift, alt, and ctrl", Ansi::MouseRight, false, true, true, true, 0b0001_1110_u8},
      {"mouse button 10 with motion, shift, alt, and ctrl", Ansi::MouseButton10, true, true, true, true, 0b1011_1110_u8},
      {"mouse left with motion, shift, and ctrl", Ansi::MouseLeft, true, true, false, true, 0b0011_0100_u8},
      {"invalid mouse button", Ansi::MouseButton.new(0xff_u8), false, false, false, false, 0b1111_1111_u8},
      {"mouse wheel down with motion", Ansi::MouseWheelDown, true, false, false, false, 0b0110_0001_u8},
      {"mouse wheel down with shift and ctrl", Ansi::MouseWheelDown, false, true, false, true, 0b0101_0101_u8},
      {"mouse wheel left with alt", Ansi::MouseWheelLeft, false, false, true, false, 0b0100_1010_u8},
      {"mouse middle with all modifiers", Ansi::MouseMiddle, true, true, true, true, 0b0011_1101_u8},
    ]

    cases.each do |name, btn, motion, shift, alt, ctrl, want|
      it name do
        got = Ansi.encode_mouse_button(btn, motion, shift, alt, ctrl)
        got.should eq want
      end
    end
  end

  describe ".mouse_sgr" do
    cases = [
      {"mouse left", Ansi.encode_mouse_button(Ansi::MouseLeft, false, false, false, false), 0, 0, false},
      {"wheel down", Ansi.encode_mouse_button(Ansi::MouseWheelDown, false, false, false, false), 1, 10, false},
      {"mouse right with shift, alt, and ctrl", Ansi.encode_mouse_button(Ansi::MouseRight, false, true, true, true), 10, 1, false},
      {"mouse release", Ansi.encode_mouse_button(Ansi::MouseNone, false, false, false, false), 5, 5, true},
      {"mouse button 10 with motion, shift, alt, and ctrl", Ansi.encode_mouse_button(Ansi::MouseButton10, true, true, true, true), 10, 10, false},
      {"mouse wheel up with motion", Ansi.encode_mouse_button(Ansi::MouseWheelUp, true, false, false, false), 15, 15, false},
      {"mouse middle with all modifiers", Ansi.encode_mouse_button(Ansi::MouseMiddle, true, true, true, true), 20, 20, false},
      {"mouse wheel left at max coordinates", Ansi.encode_mouse_button(Ansi::MouseWheelLeft, false, false, false, false), 223, 223, false},
      {"mouse forward release", Ansi.encode_mouse_button(Ansi::MouseForward, false, false, false, false), 100, 100, true},
      {"mouse backward with shift and ctrl", Ansi.encode_mouse_button(Ansi::MouseBackward, false, true, false, true), 50, 50, false},
    ]

    cases.each do |name, btn, x, y, release|
      it name do
        m = Ansi.mouse_sgr(btn, x, y, release)
        action = release ? 'm' : 'M'
        want = "\e[<#{btn};#{x + 1};#{y + 1}#{action}"
        m.should eq want
      end
    end
  end
end
