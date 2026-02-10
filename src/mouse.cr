module Term2
  # Mouse support utilities (tracking enable/disable only).
  module Mouse
    # Enable mouse tracking (clicks and drags).
    def self.enable_tracking(io : IO = STDOUT)
      # Bubble Tea parity: enable cell-motion tracking and SGR mode.
      io.print "\e[?1002h"
      io.print "\e[?1006h"
      io.flush
    end

    # Disable mouse tracking.
    def self.disable_tracking(io : IO = STDOUT)
      # Bubble Tea parity: disable mouse tracking modes on exit.
      io.print "\e[?1002l"
      io.print "\e[?1003l"
      io.print "\e[?1006l"
      io.flush
    end

    # Enable mouse click reporting.
    def self.enable_click_reporting(io : IO = STDOUT)
      io.print "\e[?1006h" # SGR mode for extended coordinates
      io.print "\e[?1000h"
      io.flush
    end

    # Disable mouse click reporting.
    def self.disable_click_reporting(io : IO = STDOUT)
      io.print "\e[?1000l"
      io.flush
    end

    # Enable mouse drag reporting.
    def self.enable_drag_reporting(io : IO = STDOUT)
      io.print "\e[?1006h" # SGR mode for extended coordinates
      io.print "\e[?1002h"
      io.flush
    end

    # Disable mouse drag reporting.
    def self.disable_drag_reporting(io : IO = STDOUT)
      io.print "\e[?1002l"
      io.flush
    end

    # Enable mouse move reporting (all motion including hover).
    def self.enable_move_reporting(io : IO = STDOUT)
      # Bubble Tea parity: enable any-event tracking and SGR mode.
      io.print "\e[?1003h"
      io.print "\e[?1006h"
      io.flush
    end

    # Disable mouse move reporting.
    def self.disable_move_reporting(io : IO = STDOUT)
      io.print "\e[?1003l"
      io.flush
    end
  end
end
