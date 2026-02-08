require "./base_types"
require "./view"

# Mouse event handling for terminal applications
module Term2
  # MouseMsg represents any mouse-related message type.
  # It mirrors Bubble Tea's MouseMsg interface.
  module MouseMsg
    abstract def mouse : MouseEvent
  end

  # MouseEvent represents a mouse action in the terminal.
  #
  # Mouse events are sent when mouse tracking is enabled via
  # `ProgramOptions#with_mouse_all_motion` or similar options.
  #
  # ```
  # def update(model : MyModel, msg : Term2::Message) : {MyModel, Term2::Cmd?}
  #   case msg
  #   when Term2::MouseEvent
  #     puts "Mouse #{msg.action} at #{msg.x}, #{msg.y}"
  #     puts "Button: #{msg.button}"
  #     puts "Modifiers: ctrl=#{msg.ctrl?}, alt=#{msg.alt?}, shift=#{msg.shift?}"
  #   end
  #   {model, nil}
  # end
  # ```
  class MouseEvent < Message
    include MouseMsg
    # Mouse button types
    enum Button
      Left       # Primary mouse button
      Right      # Secondary mouse button
      Middle     # Middle/wheel button
      WheelUp    # Scroll wheel up
      WheelDown  # Scroll wheel down
      WheelLeft  # Horizontal scroll left
      WheelRight # Horizontal scroll right
      Backward   # Browser back button (button 8)
      Forward    # Browser forward button (button 9)
      Button10   # Extra mouse button 10
      Button11   # Extra mouse button 11
      Release    # Button release (no specific button)
      None       # No button (for motion events)
    end

    # Mouse action types
    enum Action
      Press   # Button pressed down
      Release # Button released
      Drag    # Movement while button held
      Move    # Movement without button (motion tracking)
    end

    # X coordinate (0-based, from left)
    getter x : Int32
    # Y coordinate (0-based, from top)
    getter y : Int32
    # Which button is involved
    getter button : Button
    # What action occurred
    getter action : Action
    # Whether Alt was held
    getter? alt : Bool
    # Whether Ctrl was held
    getter? ctrl : Bool
    # Whether Shift was held
    getter? shift : Bool

    def initialize(@x : Int32, @y : Int32, @button : Button, @action : Action, @alt : Bool = false, @ctrl : Bool = false, @shift : Bool = false)
    end

    def ==(other : self)
      x == other.x &&
        y == other.y &&
        button == other.button &&
        action == other.action &&
        alt? == other.alt? &&
        ctrl? == other.ctrl? &&
        shift? == other.shift?
    end

    def to_s : String
      mods = [] of String
      mods << "ctrl" if @ctrl
      mods << "alt" if @alt
      mods << "shift" if @shift

      button_name = case @button
                    when Button::Left       then "left"
                    when Button::Right      then "right"
                    when Button::Middle     then "middle"
                    when Button::WheelUp    then "wheel up"
                    when Button::WheelDown  then "wheel down"
                    when Button::WheelLeft  then "wheel left"
                    when Button::WheelRight then "wheel right"
                    when Button::Backward   then "backward"
                    when Button::Forward    then "forward"
                    when Button::Button10   then "button10"
                    when Button::Button11   then "button11"
                    else                         ""
                    end

      base = case @action
             when Action::Move
               @button == Button::None ? "motion" : "#{button_name} move"
             when Action::Drag
               @button == Button::None ? "unknown" : "#{button_name} drag"
             when Action::Release
               @button == Button::None ? "release" : "#{button_name} release"
             else
               # Press
               case @button
               when Button::WheelUp, Button::WheelDown, Button::WheelLeft, Button::WheelRight
                 button_name
               else
                 @button == Button::None ? "unknown" : "#{button_name} press"
               end
             end

      return base if mods.empty?
      "#{mods.join("+")}+#{base}"
    end

    def mouse : MouseEvent
      self
    end

    # Returns a new MouseEvent with coordinates relative to the given view.
    # The view's offset_x and offset_y are subtracted from the coordinates.
    def relative_to(view : View) : MouseEvent
      MouseEvent.new(
        x: @x - view.offset_x,
        y: @y - view.offset_y,
        button: @button,
        action: @action,
        alt: @alt,
        ctrl: @ctrl,
        shift: @shift
      )
    end
  end

  # MouseReader handles parsing mouse events from terminal input.
  #
  # This class parses both SGR (modern) and legacy X10 mouse protocols.
  # SGR format: `\e[<code;x;y[Mm]`
  # Legacy format: `\e[Mbxy`
  #
  # The reader maintains an internal buffer to handle partial sequences.
  class MouseReader
    @buffer : String = ""

    # Read a mouse event from the given IO.
    #
    # Returns `nil` if no complete mouse event is available.

    def read_mouse_event(io : IO) : MouseEvent?
      char = io.read_char
      return unless char

      @buffer += char.to_s

      # Check for mouse escape sequences
      if @buffer.starts_with?("\e[")
        if event = Mouse.parse_sgr(@buffer)
          @buffer = ""
          return event
        elsif event = Mouse.parse_x10(@buffer)
          @buffer = ""
          return event
        elsif @buffer.size > 20
          # Buffer too long, clear it
          @buffer = ""
        end

        # Partial match, need more data
        nil
      else
        # Not a mouse sequence
        @buffer = ""
        nil
      end
    rescue IO::EOFError
      nil
    end

    # Check if the given buffer contains a complete mouse event
    def check_mouse_event(buffer : String) : MouseEvent?
      Mouse.parse_sgr(buffer) || Mouse.parse_x10(buffer)
    end
  end

  # Mouse support utilities
  module Mouse
    BUTTON_MASK       = 0b0000_0011
    SHIFT_MASK        = 0b0000_0100
    ALT_MASK          = 0b0000_1000
    CTRL_MASK         = 0b0001_0000
    MOTION_MASK       = 0b0010_0000
    WHEEL_MASK        = 0b0100_0000
    EXTRA_BUTTON_MASK = 0b1000_0000

    # Parse a legacy X10 mouse event buffer.
    def self.parse_x10(buffer : String | Bytes | Slice(UInt8)) : MouseEvent?
      slice = buffer.is_a?(String) ? buffer.to_slice : buffer
      return unless slice.size >= 6
      return unless slice[0] == 0x1b && slice[1] == '['.ord.to_u8 && slice[2] == 'M'.ord.to_u8

      code = slice[3].to_i - 32
      # X10 reports positions as (1,1) upper-left. Normalize to (0,0).
      x = slice[4].to_i - 33
      y = slice[5].to_i - 33

      release = (code & BUTTON_MASK) == 3 && (code & MOTION_MASK) == 0 && (code & WHEEL_MASK) == 0 && (code & EXTRA_BUTTON_MASK) == 0
      decode_mouse_event(code, x, y, release: release)
    end

    # Parse an SGR mouse event buffer.
    def self.parse_sgr(buffer : String | Bytes | Slice(UInt8)) : MouseEvent?
      str = buffer.is_a?(String) ? buffer : String.new(buffer)
      return unless str =~ /\e\[<(\d+);(\d+);(\d+)([Mm])\z/

      code = $1.to_i
      # SGR reports positions as (1,1) upper-left. Normalize to (0,0).
      x = $2.to_i - 1
      y = $3.to_i - 1
      release = $4 == "m"

      decode_mouse_event(code, x, y, release: release)
    end

    private def self.decode_mouse_event(code : Int32, x : Int32, y : Int32, release : Bool) : MouseEvent
      button_bits = code & BUTTON_MASK
      wheel = (code & WHEEL_MASK) != 0
      motion = (code & MOTION_MASK) != 0
      extra = (code & EXTRA_BUTTON_MASK) != 0

      button = decode_button(button_bits, wheel, extra, motion)
      if release && button == MouseEvent::Button::Release
        button = MouseEvent::Button::None
      end

      action = case {release, motion}
               when {true, _}
                 MouseEvent::Action::Release
               when {_, true}
                 MouseEvent::Action::Move
               else
                 MouseEvent::Action::Press
               end

      shift = (code & SHIFT_MASK) != 0
      alt = (code & ALT_MASK) != 0
      ctrl = (code & CTRL_MASK) != 0

      MouseEvent.new(x, y, button, action, alt, ctrl, shift)
    end

    private def self.decode_button(button_bits : Int32, wheel : Bool, extra : Bool, motion : Bool) : MouseEvent::Button
      if extra
        case button_bits
        when 0 then MouseEvent::Button::Backward
        when 1 then MouseEvent::Button::Forward
        when 2 then MouseEvent::Button::Button10
        when 3 then MouseEvent::Button::Button11
        else        MouseEvent::Button::None
        end
      elsif wheel
        case button_bits
        when 0 then MouseEvent::Button::WheelUp
        when 1 then MouseEvent::Button::WheelDown
        when 2 then MouseEvent::Button::WheelLeft
        when 3 then MouseEvent::Button::WheelRight
        else        MouseEvent::Button::None
        end
      else
        case button_bits
        when 0 then MouseEvent::Button::Left
        when 1 then MouseEvent::Button::Middle
        when 2 then MouseEvent::Button::Right
        when 3
          motion ? MouseEvent::Button::None : MouseEvent::Button::Release
        else
          MouseEvent::Button::None
        end
      end
    end

    # Enable mouse tracking (clicks and drags)
    def self.enable_tracking(io : IO = STDOUT)
      # Bubble Tea parity: enable cell-motion tracking and SGR mode.
      io.print "\e[?1002h"
      io.print "\e[?1006h"
      io.flush
    end

    # Disable mouse tracking
    def self.disable_tracking(io : IO = STDOUT)
      # Bubble Tea parity: disable mouse tracking modes on exit.
      io.print "\e[?1002l"
      io.print "\e[?1003l"
      io.print "\e[?1006l"
      io.flush
    end

    # Enable mouse click reporting
    def self.enable_click_reporting(io : IO = STDOUT)
      io.print "\e[?1006h" # SGR mode for extended coordinates
      io.print "\e[?1000h"
      io.flush
    end

    # Disable mouse click reporting
    def self.disable_click_reporting(io : IO = STDOUT)
      io.print "\e[?1000l"
      io.flush
    end

    # Enable mouse drag reporting
    def self.enable_drag_reporting(io : IO = STDOUT)
      io.print "\e[?1006h" # SGR mode for extended coordinates
      io.print "\e[?1002h"
      io.flush
    end

    # Disable mouse drag reporting
    def self.disable_drag_reporting(io : IO = STDOUT)
      io.print "\e[?1002l"
      io.flush
    end

    # Enable mouse move reporting (all motion including hover)
    def self.enable_move_reporting(io : IO = STDOUT)
      # Bubble Tea parity: enable any-event tracking and SGR mode.
      io.print "\e[?1003h"
      io.print "\e[?1006h"
      io.flush
    end

    # Disable mouse move reporting
    def self.disable_move_reporting(io : IO = STDOUT)
      io.print "\e[?1003l"
      io.flush
    end
  end
end
