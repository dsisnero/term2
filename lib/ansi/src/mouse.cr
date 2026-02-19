module Ansi
  struct MouseButton
    getter value : UInt8

    def initialize(@value : UInt8)
    end

    # ameba:disable Metrics/CyclomaticComplexity
    def to_s : String
      case @value
      when MouseNone.value
        "none"
      when MouseLeft.value
        "left"
      when MouseMiddle.value
        "middle"
      when MouseRight.value
        "right"
      when MouseWheelUp.value
        "wheelup"
      when MouseWheelDown.value
        "wheeldown"
      when MouseWheelLeft.value
        "wheelleft"
      when MouseWheelRight.value
        "wheelright"
      when MouseBackward.value
        "backward"
      when MouseForward.value
        "forward"
      when MouseButton10.value
        "button10"
      when MouseButton11.value
        "button11"
      else
        ""
      end
    end

    def_equals @value
    def_hash @value
  end

  MouseNone     = MouseButton.new(0_u8)
  MouseButton1  = MouseButton.new(1_u8)
  MouseButton2  = MouseButton.new(2_u8)
  MouseButton3  = MouseButton.new(3_u8)
  MouseButton4  = MouseButton.new(4_u8)
  MouseButton5  = MouseButton.new(5_u8)
  MouseButton6  = MouseButton.new(6_u8)
  MouseButton7  = MouseButton.new(7_u8)
  MouseButton8  = MouseButton.new(8_u8)
  MouseButton9  = MouseButton.new(9_u8)
  MouseButton10 = MouseButton.new(10_u8)
  MouseButton11 = MouseButton.new(11_u8)

  MouseLeft       = MouseButton1
  MouseMiddle     = MouseButton2
  MouseRight      = MouseButton3
  MouseWheelUp    = MouseButton4
  MouseWheelDown  = MouseButton5
  MouseWheelLeft  = MouseButton6
  MouseWheelRight = MouseButton7
  MouseBackward   = MouseButton8
  MouseForward    = MouseButton9
  MouseRelease    = MouseNone

  def self.encode_mouse_button(b : MouseButton, motion : Bool, shift : Bool, alt : Bool, ctrl : Bool) : UInt8
    bit_shift = 0b0000_0100_u8
    bit_alt = 0b0000_1000_u8
    bit_ctrl = 0b0001_0000_u8
    bit_motion = 0b0010_0000_u8
    bit_wheel = 0b0100_0000_u8
    bit_add = 0b1000_0000_u8
    bits_mask = 0b0000_0011_u8

    m = if b == MouseNone
          bits_mask
        elsif b.value >= MouseLeft.value && b.value <= MouseRight.value
          (b.value - MouseLeft.value).to_u8
        elsif b.value >= MouseWheelUp.value && b.value <= MouseWheelRight.value
          ((b.value - MouseWheelUp.value).to_u8 | bit_wheel)
        elsif b.value >= MouseBackward.value && b.value <= MouseButton11.value
          ((b.value - MouseBackward.value).to_u8 | bit_add)
        else
          0xff_u8
        end

    m |= bit_shift if shift
    m |= bit_alt if alt
    m |= bit_ctrl if ctrl
    m |= bit_motion if motion

    m
  end

  X10Offset = 32_u8

  def self.mouse_x10(b : UInt8, x : Int32, y : Int32) : String
    "\e[M#{(b + X10Offset).chr}#{(x.to_u8 + X10Offset + 1).chr}#{(y.to_u8 + X10Offset + 1).chr}"
  end

  def self.mouse_sgr(b : UInt8, x : Int32, y : Int32, release : Bool) : String
    action = release ? 'm' : 'M'
    x = -x if x < 0
    y = -y if y < 0
    "\e[<#{b};#{x + 1};#{y + 1}#{action}"
  end
end
