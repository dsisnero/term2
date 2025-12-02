# Terminal control utilities for advanced terminal features
module Term2
  {% if flag?(:unix) %}
    lib LibC
      struct Winsize
        ws_row : UInt16
        ws_col : UInt16
        ws_xpixel : UInt16
        ws_ypixel : UInt16
      end

      {% if flag?(:darwin) %}
        TIOCGWINSZ = 0x40087468_u64
      {% else %}
        TIOCGWINSZ = 0x5413_u64
      {% end %}

      fun ioctl(fd : Int32, request : UInt64, ...) : Int32
    end
  {% end %}

  # Terminal provides utilities for controlling terminal behavior
  module Terminal
    # Enable raw mode on an IO (typically STDIN)
    # Returns a block that can be used to restore the original mode
    # Typically you should use the block form: raw(io) { ... }
    def self.raw(io : IO, &)
      if io.responds_to?(:raw)
        io.raw do
          yield
        end
      else
        yield
      end
    end

    # Check if IO supports raw mode
    def self.supports_raw?(io : IO) : Bool
      io.responds_to?(:raw)
    end

    # Enter alternate screen mode
    def self.enter_alt_screen(io : IO = STDOUT)
      io.print "\033[?1049h"
    end

    # Exit alternate screen mode
    def self.exit_alt_screen(io : IO = STDOUT)
      io.print "\033[?1049l"
    end

    # Clear the screen and move cursor to home position
    def self.clear(io : IO = STDOUT)
      io.print "\033[2J\033[H"
    end

    # Hide the cursor
    def self.hide_cursor(io : IO = STDOUT)
      io.print "\033[?25l"
    end

    # Show the cursor
    def self.show_cursor(io : IO = STDOUT)
      io.print "\033[?25h"
    end

    # Set the terminal window title
    def self.set_window_title(io : IO, title : String)
      io.print "\033]2;#{title}\033\\"
      io.flush
    end

    # Move cursor to specific position (1-based row, col)
    def self.move_to(row : Int32, col : Int32, io : IO = STDOUT)
      io.print "\e[#{row};#{col}H"
    end

    # Move cursor to home position (top-left)
    def self.home(io : IO = STDOUT)
      io.print "\e[H"
    end

    # Move cursor up n lines
    def self.move_up(n : Int32 = 1, io : IO = STDOUT)
      io.print "\e[#{n}A"
    end

    # Move cursor down n lines
    def self.move_down(n : Int32 = 1, io : IO = STDOUT)
      io.print "\e[#{n}B"
    end

    # Move cursor right n columns
    def self.move_right(n : Int32 = 1, io : IO = STDOUT)
      io.print "\e[#{n}C"
    end

    # Move cursor left n columns
    def self.move_left(n : Int32 = 1, io : IO = STDOUT)
      io.print "\e[#{n}D"
    end

    # Save cursor position
    def self.save_cursor(io : IO = STDOUT)
      io.print "\e[s"
    end

    # Restore cursor position
    def self.restore_cursor(io : IO = STDOUT)
      io.print "\e[u"
    end

    # Clear from cursor to end of line
    def self.clear_line(io : IO = STDOUT)
      io.print "\e[K"
    end

    # Clear entire line
    def self.clear_entire_line(io : IO = STDOUT)
      io.print "\e[2K"
    end

    # Clear from cursor to end of screen
    def self.clear_to_end(io : IO = STDOUT)
      io.print "\e[J"
    end

    # Enable bracketed paste mode
    def self.enable_bracketed_paste(io : IO = STDOUT)
      io.print "\033[?2004h"
    end

    # Disable bracketed paste mode
    def self.disable_bracketed_paste(io : IO = STDOUT)
      io.print "\033[?2004l"
    end

    # Enable focus reporting
    def self.enable_focus_reporting(io : IO = STDOUT)
      io.print "\033[?1004h"
    end

    # Disable focus reporting
    def self.disable_focus_reporting(io : IO = STDOUT)
      io.print "\033[?1004l"
    end

    # Save terminal state (cursor position, attributes, etc.)
    def self.save_state(io : IO = STDOUT)
      io.print "\e7"
    end

    # Restore terminal state
    def self.restore_state(io : IO = STDOUT)
      io.print "\e8"
    end

    # Release terminal (restore original state)
    def self.release_terminal(io : IO = STDOUT)
      show_cursor(io)
      exit_alt_screen(io)
      disable_focus_reporting(io)
      enable_bracketed_paste(io)
      io.print "\033[0m" # Reset all attributes
    end

    # Restore terminal to program state
    def self.restore_terminal(io : IO = STDOUT)
      hide_cursor(io)
      clear(io)
    end

    # Get terminal size using ioctl
    def self.size : {Int32, Int32}
      {% if flag?(:unix) %}
        # Use ioctl to get terminal size on Unix systems
        if STDOUT.tty?
          begin
            ws = uninitialized LibC::Winsize
            if LibC.ioctl(STDOUT.fd, LibC::TIOCGWINSZ, pointerof(ws)) == 0
              return {ws.ws_col.to_i32, ws.ws_row.to_i32}
            end
          rescue
            # Fall through to default
          end
        end
      {% end %}
      # Default fallback
      {80, 24}
    end

    # Check if output is a terminal
    def self.tty?(io : IO = STDOUT) : Bool
      io.tty?
    end
  end

  # Cursor module provides escape sequence strings for cursor control.
  # Unlike Terminal module methods which print directly, these return strings
  # that can be used in string building/concatenation.
  #
  # Example:
  # ```
  # io << Cursor.move_to(1, 1) << "Hello" << Cursor.move_to(2, 1) << "World"
  # ```
  module Cursor
    # Move cursor to specific position (row, col are 1-based)
    def self.move_to(row : Int32, col : Int32) : String
      "\e[#{row};#{col}H"
    end

    # Move cursor to home position (top-left)
    def self.home : String
      "\e[H"
    end

    # Move cursor up n lines
    def self.up(n : Int32 = 1) : String
      "\e[#{n}A"
    end

    # Move cursor down n lines
    def self.down(n : Int32 = 1) : String
      "\e[#{n}B"
    end

    # Move cursor right n columns
    def self.right(n : Int32 = 1) : String
      "\e[#{n}C"
    end

    # Move cursor left n columns
    def self.left(n : Int32 = 1) : String
      "\e[#{n}D"
    end

    # Move cursor to beginning of line n lines down
    def self.next_line(n : Int32 = 1) : String
      "\e[#{n}E"
    end

    # Move cursor to beginning of line n lines up
    def self.prev_line(n : Int32 = 1) : String
      "\e[#{n}F"
    end

    # Move cursor to column n
    def self.column(n : Int32) : String
      "\e[#{n}G"
    end

    # Save cursor position
    def self.save : String
      "\e[s"
    end

    # Restore cursor position
    def self.restore : String
      "\e[u"
    end

    # Hide cursor
    def self.hide : String
      "\e[?25l"
    end

    # Show cursor
    def self.show : String
      "\e[?25h"
    end

    # Request cursor position (terminal will respond with position)
    def self.request_position : String
      "\e[6n"
    end

    # Erase from cursor to end of line
    def self.erase_line_right : String
      "\e[K"
    end

    # Erase from start of line to cursor
    def self.erase_line_left : String
      "\e[1K"
    end

    # Erase entire line
    def self.erase_line : String
      "\e[2K"
    end

    # Erase from cursor to end of screen
    def self.erase_screen_below : String
      "\e[J"
    end

    # Erase from start of screen to cursor
    def self.erase_screen_above : String
      "\e[1J"
    end

    # Erase entire screen
    def self.erase_screen : String
      "\e[2J"
    end

    # Clear screen and move to home (convenience)
    def self.clear : String
      "\e[2J\e[H"
    end

    # Enter alternate screen buffer
    def self.enter_alt_screen : String
      "\e[?1049h"
    end

    # Exit alternate screen buffer
    def self.exit_alt_screen : String
      "\e[?1049l"
    end

    # Set window title
    def self.set_title(title : String) : String
      "\e]2;#{title}\e\\"
    end

    # Reset all attributes
    def self.reset : String
      "\e[0m"
    end
  end
end
