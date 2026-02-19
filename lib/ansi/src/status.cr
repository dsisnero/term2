module Ansi
  module StatusReport
    abstract def status_report : Int32
  end

  # ANSIStatusReport represents an ANSI terminal status report.
  struct ANSIStatusReport
    include StatusReport
    getter value : Int32

    def initialize(@value : Int32)
    end

    def status_report : Int32
      @value
    end
  end

  # DECStatusReport represents a DEC terminal status report.
  struct DECStatusReport
    include StatusReport
    getter value : Int32

    def initialize(@value : Int32)
    end

    def status_report : Int32
      @value
    end
  end

  # DeviceStatusReport (DSR) is a control sequence that reports the terminal's
  # status.
  # The terminal responds with a DSR sequence.
  #
  #	CSI Ps n
  #	CSI ? Ps n
  #
  # If one of the statuses is a [DECStatusReport], the sequence will use the DEC
  # format.
  #
  # See also https://vt100.net/docs/vt510-rm/DSR.html
  def self.device_status_report(*statuses : StatusReport) : String
    dec = false
    list = statuses.map do |status|
      dec = true if status.is_a?(DECStatusReport)
      status.status_report.to_s
    end
    prefix = dec ? "?" : ""
    "\e[#{prefix}#{list.join(";")}n"
  end

  # DSR is an alias for [device_status_report].
  def self.dsr(status : StatusReport) : String
    device_status_report(status)
  end

  # RequestCursorPositionReport is an escape sequence that requests the current
  # cursor position.
  #
  #	CSI 6 n
  #
  # The terminal will report the cursor position as a CSI sequence in the
  # following format:
  #
  #	CSI Pl ; Pc R
  #
  # Where Pl is the line number and Pc is the column number.
  # See: https://vt100.net/docs/vt510-rm/CPR.html
  RequestCursorPositionReport = "\e[6n"

  # RequestExtendedCursorPositionReport (DECXCPR) is a sequence for requesting
  # the cursor position report including the current page number.
  #
  #	CSI ? 6 n
  #
  # The terminal will report the cursor position as a CSI sequence in the
  # following format:
  #
  #	CSI ? Pl ; Pc ; Pp R
  #
  # Where Pl is the line number, Pc is the column number, and Pp is the page
  # number.
  # See: https://vt100.net/docs/vt510-rm/DECXCPR.html
  RequestExtendedCursorPositionReport = "\e[?6n"

  # RequestLightDarkReport is a control sequence that requests the terminal to
  # report its operating system light/dark color preference. Supported terminals
  # should respond with a [LightDarkReport] sequence as follows:
  #
  #	CSI ? 997 ; 1 n   for dark mode
  #	CSI ? 997 ; 2 n   for light mode
  #
  # See: https://contour-terminal.org/vt-extensions/color-palette-update-notifications/
  RequestLightDarkReport = "\e[?996n"

  # CursorPositionReport (CPR) is a control sequence that reports the cursor's
  # position.
  #
  #	CSI Pl ; Pc R
  #
  # Where Pl is the line number and Pc is the column number.
  #
  # See also https://vt100.net/docs/vt510-rm/CPR.html
  def self.cursor_position_report(line : Int32, column : Int32) : String
    line = 1 if line < 1
    column = 1 if column < 1
    "\e[#{line};#{column}R"
  end

  # CPR is an alias for [cursor_position_report].
  def self.cpr(line : Int32, column : Int32) : String
    cursor_position_report(line, column)
  end

  # ExtendedCursorPositionReport (DECXCPR) is a control sequence that reports the
  # cursor's position along with the page number (optional).
  #
  #	CSI ? Pl ; Pc R
  #	CSI ? Pl ; Pc ; Pv R
  #
  # Where Pl is the line number, Pc is the column number, and Pv is the page
  # number.
  #
  # If the page number is zero or negative, the returned sequence won't include
  # the page number.
  #
  # See also https://vt100.net/docs/vt510-rm/DECXCPR.html
  def self.extended_cursor_position_report(line : Int32, column : Int32, page : Int32) : String
    line = 1 if line < 1
    column = 1 if column < 1
    if page < 1
      return "\e[?#{line};#{column}R"
    end
    "\e[?#{line};#{column};#{page}R"
  end

  # DECXCPR is an alias for [extended_cursor_position_report].
  def self.decxcpr(line : Int32, column : Int32, page : Int32) : String
    extended_cursor_position_report(line, column, page)
  end

  # LightDarkReport is a control sequence that reports the terminal's operating
  # system light/dark color preference.
  #
  #	CSI ? 997 ; 1 n   for dark mode
  #	CSI ? 997 ; 2 n   for light mode
  #
  # See: https://contour-terminal.org/vt-extensions/color-palette-update-notifications/
  def self.light_dark_report(dark : Bool) : String
    dark ? "\e[?997;1n" : "\e[?997;2n"
  end
end
