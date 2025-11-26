require "./base_types"

# Mouse event handling for terminal applications
module Term2
  # MouseEvent represents a mouse action in the terminal.
  #
  # Mouse events are sent when mouse tracking is enabled via
  # `ProgramOptions#with_mouse_all_motion` or similar options.
  #
  # ```crystal
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
    # Mouse button types
    enum Button
      Left       # Primary mouse button
      Right      # Secondary mouse button
      Middle     # Middle/wheel button
      WheelUp    # Scroll wheel up
      WheelDown  # Scroll wheel down
      WheelLeft  # Horizontal scroll left
      WheelRight # Horizontal scroll right
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

    # X coordinate (1-based, from left)
    getter x : Int32
    # Y coordinate (1-based, from top)
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

    def to_s : String
      modifiers = [] of String
      modifiers << "alt" if @alt
      modifiers << "ctrl" if @ctrl
      modifiers << "shift" if @shift
      mod_str = modifiers.empty? ? "" : " #{modifiers.join("+")}"
      "MouseEvent(#{@button} #{@action} at #{@x},#{@y}#{mod_str})"
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
      return nil unless char

      @buffer += char.to_s

      # Check for mouse escape sequences
      if @buffer.starts_with?("\e[")
        # Look for complete mouse sequences
        if @buffer =~ /\e\[<(\d+);(\d+);(\d+)([Mm])\)?\z/
          # Parse SGR mouse sequence
          code = $1.to_i
          x = $2.to_i
          y = $3.to_i
          final_char = $4

          @buffer = ""
          return parse_sgr_mouse(code, x, y, final_char)
        elsif @buffer =~ /\e\[M([\x20-\x3f])([\x20-\x7e])([\x20-\x7e])\z/
          # Parse legacy mouse sequence
          button_code = $1.bytes[0]
          x_code = $2.bytes[0]
          y_code = $3.bytes[0]

          @buffer = ""
          return parse_legacy_mouse(button_code, x_code, y_code)
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
      # Check for mouse escape sequences
      if buffer.starts_with?("\e[")
        # Look for complete mouse sequences
        if buffer =~ /\e\[<(\d+);(\d+);(\d+)([Mm])\)?\z/
          # Parse SGR mouse sequence
          code = $1.to_i
          x = $2.to_i
          y = $3.to_i
          final_char = $4

          return parse_sgr_mouse(code, x, y, final_char)
        elsif buffer =~ /\e\[M([\x20-\x3f])([\x20-\x7e])([\x20-\x7e])\z/
          # Parse legacy mouse sequence
          button_code = $1.bytes[0]
          x_code = $2.bytes[0]
          y_code = $3.bytes[0]

          return parse_legacy_mouse(button_code, x_code, y_code)
        end
      end

      nil
    end

    private def parse_sgr_mouse(code : Int32, x : Int32, y : Int32, final_char : String) : MouseEvent?
      # Parse SGR mouse event
      # Bit layout:
      # - Bits 0-1: button (0=left, 1=middle, 2=right, 3=release)
      # - Bit 2: shift
      # - Bit 3: alt (meta)
      # - Bit 4: ctrl
      # - Bit 5: motion (drag)
      # - Bit 6: wheel
      motion_bit = (code & 0x20) != 0 # Bit 5 indicates motion

      button = case
               when (code & 64) != 0 # Wheel events
                 case code & 3
                 when 0 then MouseEvent::Button::WheelUp
                 when 1 then MouseEvent::Button::WheelDown
                 when 2 then MouseEvent::Button::WheelLeft
                 when 3 then MouseEvent::Button::WheelRight
                 else        MouseEvent::Button::None
                 end
               when motion_bit # Motion events (button held)
                 case code & 3
                 when 0 then MouseEvent::Button::Left
                 when 1 then MouseEvent::Button::Middle
                 when 2 then MouseEvent::Button::Right
                 else        MouseEvent::Button::None
                 end
               else # Regular button events
                 case code & 3
                 when 0 then MouseEvent::Button::Left
                 when 1 then MouseEvent::Button::Middle
                 when 2 then MouseEvent::Button::Right
                 when 3 then MouseEvent::Button::Release
                 else        MouseEvent::Button::None
                 end
               end

      action = case
               when (code & 64) != 0 # Wheel events are always press
                 MouseEvent::Action::Press
               when motion_bit
                 MouseEvent::Action::Drag
               when (code & 3) == 3
                 MouseEvent::Action::Release
               else
                 final_char == "M" ? MouseEvent::Action::Press : MouseEvent::Action::Release
               end

      alt = (code & 8) != 0
      ctrl = (code & 16) != 0
      shift = (code & 4) != 0

      MouseEvent.new(x, y, button, action, alt, ctrl, shift)
    end

    private def parse_legacy_mouse(button_code : Int32, x_code : Int32, y_code : Int32) : MouseEvent?
      # Parse legacy mouse event (xterm)
      button = case button_code
               when 32
                 MouseEvent::Button::Left
               when 33
                 MouseEvent::Button::Middle
               when 34
                 MouseEvent::Button::Right
               when 35
                 MouseEvent::Button::Release
               when 64, 65
                 MouseEvent::Button::WheelUp
               when 66, 67
                 MouseEvent::Button::WheelDown
               else
                 MouseEvent::Button::None
               end

      action = case button_code
               when 32, 33, 34
                 MouseEvent::Action::Press
               when 35
                 MouseEvent::Action::Release
               when 64, 65, 66, 67
                 MouseEvent::Action::Press
               else
                 MouseEvent::Action::Move
               end

      # Legacy mouse coordinates are offset by 32
      x = x_code - 32
      y = y_code - 32

      MouseEvent.new(x, y, button, action)
    end
  end

  # Mouse support utilities
  module Mouse
    # Enable mouse tracking
    def self.enable_tracking(io : IO = STDOUT)
      # Enable SGR mouse mode (preferred)
      io.print "\e[?1006h"
      # Enable mouse tracking
      io.print "\e[?1000h"
      # Enable extended mouse mode
      io.print "\e[?1002h"
    end

    # Disable mouse tracking
    def self.disable_tracking(io : IO = STDOUT)
      # Disable all mouse modes
      io.print "\e[?1006l"
      io.print "\e[?1000l"
      io.print "\e[?1002l"
    end

    # Enable mouse click reporting
    def self.enable_click_reporting(io : IO = STDOUT)
      io.print "\e[?1000h"
    end

    # Disable mouse click reporting
    def self.disable_click_reporting(io : IO = STDOUT)
      io.print "\e[?1000l"
    end

    # Enable mouse drag reporting
    def self.enable_drag_reporting(io : IO = STDOUT)
      io.print "\e[?1002h"
    end

    # Disable mouse drag reporting
    def self.disable_drag_reporting(io : IO = STDOUT)
      io.print "\e[?1002l"
    end

    # Enable mouse move reporting
    def self.enable_move_reporting(io : IO = STDOUT)
      io.print "\e[?1003h"
    end

    # Disable mouse move reporting
    def self.disable_move_reporting(io : IO = STDOUT)
      io.print "\e[?1003l"
    end
  end
end
