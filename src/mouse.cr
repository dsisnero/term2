require "./base_types"

# Mouse event handling for terminal applications
module Term2
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
    # Deprecated: legacy type for compatibility
    getter type : String

    def initialize(@x : Int32, @y : Int32, @button : Button, @action : Action, @alt : Bool = false, @ctrl : Bool = false, @shift : Bool = false, @type : String = "")
    end

    def ==(other : MouseEvent) : Bool
      @x == other.x &&
        @y == other.y &&
        @button == other.button &&
        @action == other.action &&
        @alt == other.alt? &&
        @ctrl == other.ctrl? &&
        @shift == other.shift?
    end

    def to_s : String
      mods = [] of String
      mods << "ctrl" if @ctrl
      mods << "alt" if @alt
      mods << "shift" if @shift

      btn_str = case @button
                when Button::None
                  if @action == Action::Move || @action == Action::Release
                    action_to_s(@action)
                  else
                    "unknown"
                  end
                when Button::WheelUp    then "wheel up"
                when Button::WheelDown  then "wheel down"
                when Button::WheelLeft  then "wheel left"
                when Button::WheelRight then "wheel right"
                when Button::Left       then "left"
                when Button::Right      then "right"
                when Button::Middle     then "middle"
                else
                  "unknown"
                end

      action_part = ""
      if @button != Button::None && !wheel_button?(@button)
        act = action_to_s(@action)
        action_part = act unless act.empty?
      end

      base_parts = [] of String
      base_parts << btn_str unless btn_str.empty?
      base_parts << action_part unless action_part.empty?
      base = base_parts.join(" ").strip

      if mods.empty?
        base
      else
        "#{mods.join("+")}+#{base}"
      end
    end

    private def wheel_button?(btn : Button) : Bool
      {Button::WheelUp, Button::WheelDown, Button::WheelLeft, Button::WheelRight}.includes?(btn)
    end

    private def action_to_s(action : Action) : String
      case action
      when Action::Press   then "press"
      when Action::Release then "release"
      when Action::Move    then "motion"
      when Action::Drag    then "press"
      else                      ""
      end
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
          return Mouse.decode_sgr(code, x, y, final_char)
        elsif @buffer =~ /\e\[M([\x20-\x3f])([\x20-\x7e])([\x20-\x7e])\z/
          # Parse legacy mouse sequence
          button_code = $1.bytes[0]
          x_code = $2.bytes[0]
          y_code = $3.bytes[0]

          @buffer = ""
          return Mouse.decode_x10(button_code - 32, x_code, y_code)
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
        # SGR format: \e[<code;x;yM or \e[<code;x;ym
        if buffer =~ /\e\[<(\d+);(\d+);(\d+)([Mm])\z/
          # Parse SGR mouse sequence
          code = $1.to_i
          x = $2.to_i
          y = $3.to_i
          final_char = $4

          return Mouse.decode_sgr(code, x, y, final_char)
        elsif buffer =~ /\e\[M([\x20-\xff])([\x20-\xff])([\x20-\xff])\z/
          # Parse legacy mouse sequence
          button_code = $1.bytes[0]
          x_code = $2.bytes[0]
          y_code = $3.bytes[0]

          return Mouse.decode_x10(button_code - 32, x_code, y_code)
        end
      end

      nil
    end
  end

  # Mouse support utilities
  module Mouse
    # Parse a legacy X10 mouse event from a raw byte slice.
    # Returns nil if the buffer is not a valid X10 sequence.
    def self.parse_x10(buf : Bytes) : MouseEvent?
      return nil unless buf.size >= 6
      return nil unless buf[0] == 0x1b_u8 && buf[1] == '['.ord.to_u8 && buf[2] == 'M'.ord.to_u8

      button_code = buf[3].to_i - 32
      x_code = buf[4].to_i
      y_code = buf[5].to_i

      decode_x10(button_code, x_code, y_code)
    end

    # Parse an SGR mouse event from a raw byte slice.
    # Returns nil if the buffer is not a valid SGR sequence.
    def self.parse_sgr(buf : Bytes) : MouseEvent?
      str = String.new(buf)
      if match = /\e\[<(\d+);(\d+);(\d+)([Mm])/.match(str)
        code = match[1].to_i
        x = match[2].to_i
        y = match[3].to_i
        final_char = match[4]

        decode_sgr(code, x, y, final_char)
      end
    end

    # Decode an SGR mouse event given the parsed codes from the terminal sequence.
    def self.decode_sgr(code : Int32, x : Int32, y : Int32, final_char : String) : MouseEvent?
      motion_bit = (code & 32) != 0
      wheel_bit = (code & 64) != 0
      button_bits = code & 3

      button = decode_button(wheel_bit, motion_bit, button_bits)
      action = decode_action(wheel_bit, motion_bit, button_bits, final_char)

      shift = (code & 4) != 0
      alt = (code & 8) != 0
      ctrl = (code & 16) != 0

      MouseEvent.new(x - 1, y - 1, button, action, alt, ctrl, shift)
    end

    # Decode an X10 mouse event given the raw codes (with the 32 offset removed from button_code).
    def self.decode_x10(button_code : Int32, x_code : Int32, y_code : Int32) : MouseEvent?
      shift = (button_code & 4) != 0
      alt = (button_code & 8) != 0
      ctrl = (button_code & 16) != 0

      motion_bit = (button_code & 32) != 0
      wheel_bit = (button_code & 64) != 0
      button_bits = button_code & 3

      button = decode_button(wheel_bit, motion_bit, button_bits)
      action = if motion_bit && !wheel_bit
                 MouseEvent::Action::Move
               elsif button_bits == 3 && !wheel_bit
                 MouseEvent::Action::Release
               else
                 MouseEvent::Action::Press
               end

      # Legacy mouse coordinates are offset by 32, and origin is 1-based.
      x = x_code - 33
      y = y_code - 33

      MouseEvent.new(x, y, button, action, alt, ctrl, shift)
    end

    private def self.decode_button(wheel_bit : Bool, motion_bit : Bool, button_bits : Int32) : MouseEvent::Button
      if wheel_bit
        case button_bits
        when 0 then MouseEvent::Button::WheelUp
        when 1 then MouseEvent::Button::WheelDown
        when 2 then MouseEvent::Button::WheelLeft
        when 3 then MouseEvent::Button::WheelRight
        else        MouseEvent::Button::None
        end
      elsif motion_bit && button_bits == 3
        MouseEvent::Button::None
      else
        case button_bits
        when 0 then MouseEvent::Button::Left
        when 1 then MouseEvent::Button::Middle
        when 2 then MouseEvent::Button::Right
        else        MouseEvent::Button::None
        end
      end
    end

    private def self.decode_action(wheel_bit : Bool, motion_bit : Bool, button_bits : Int32, final_char : String) : MouseEvent::Action
      if wheel_bit
        MouseEvent::Action::Press
      elsif motion_bit
        MouseEvent::Action::Move
      elsif final_char == "m"
        MouseEvent::Action::Release
      else
        MouseEvent::Action::Press
      end
    end

    # Enable mouse tracking (clicks and drags)
    def self.enable_tracking(io : IO = STDOUT)
      # Enable SGR mouse mode (preferred - extended coordinates)
      io.print "\e[?1006h"
      # Enable basic mouse tracking (clicks)
      io.print "\e[?1000h"
      # Enable button-event tracking (drags)
      io.print "\e[?1002h"
      io.flush
    end

    # Disable mouse tracking
    def self.disable_tracking(io : IO = STDOUT)
      # Disable all mouse modes
      io.print "\e[?1006l"
      io.print "\e[?1000l"
      io.print "\e[?1002l"
      io.print "\e[?1003l"
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
      # Enable SGR extended mode and any-event tracking. Also enable click/drag
      # reporting to match Bubble Tea defaults so terminals consistently emit
      # motion and button events.
      io.print "\e[?1006h" # SGR mode for extended coordinates
      io.print "\e[?1000h" # Enable basic button tracking
      io.print "\e[?1002h" # Enable button-drag tracking
      io.print "\e[?1003h" # Any-event tracking (all motion)
      io.flush
    end

    # Disable mouse move reporting
    def self.disable_move_reporting(io : IO = STDOUT)
      io.print "\e[?1003l"
      io.print "\e[?1002l"
      io.print "\e[?1000l"
      io.flush
    end
  end
end
