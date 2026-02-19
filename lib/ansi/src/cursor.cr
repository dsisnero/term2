module Ansi
  # SaveCursor (DECSC) is an escape sequence that saves the current cursor
  # position.
  #
  #	ESC 7
  #
  # See: https://vt100.net/docs/vt510-rm/DECSC.html
  SaveCursor = "\e7"
  DECSC      = SaveCursor

  # RestoreCursor (DECRC) is an escape sequence that restores the cursor
  # position.
  #
  #	ESC 8
  #
  # See: https://vt100.net/docs/vt510-rm/DECRC.html
  RestoreCursor = "\e8"
  DECRC         = RestoreCursor

  # RequestCursorPosition is an escape sequence that requests the current cursor
  # position.
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
  #
  # Deprecated: use [RequestCursorPositionReport] instead.
  RequestCursorPosition = "\e[6n"

  # RequestExtendedCursorPosition (DECXCPR) is a sequence for requesting the
  # cursor position report including the current page number.
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
  #
  # Deprecated: use [RequestExtendedCursorPositionReport] instead.
  RequestExtendedCursorPosition = "\e[?6n"

  # CursorUp (CUU) returns a sequence for moving the cursor up n cells.
  #
  #	CSI n A
  #
  # See: https://vt100.net/docs/vt510-rm/CUU.html
  def self.cursor_up(n : Int32) : String
    s = n > 1 ? n.to_s : ""
    "\e[#{s}A"
  end

  # CUU is an alias for [cursor_up].
  def self.cuu(n : Int32) : String
    cursor_up(n)
  end

  # CUU1 is a sequence for moving the cursor up one cell.
  CUU1 = "\e[A"

  # CursorUp1 is a sequence for moving the cursor up one cell.
  #
  # This is equivalent to CursorUp(1).
  #
  # Deprecated: use [CUU1] instead.
  CursorUp1 = "\e[A"

  # CursorDown (CUD) returns a sequence for moving the cursor down n cells.
  #
  #	CSI n B
  #
  # See: https://vt100.net/docs/vt510-rm/CUD.html
  def self.cursor_down(n : Int32) : String
    s = n > 1 ? n.to_s : ""
    "\e[#{s}B"
  end

  # CUD is an alias for [cursor_down].
  def self.cud(n : Int32) : String
    cursor_down(n)
  end

  # CUD1 is a sequence for moving the cursor down one cell.
  CUD1 = "\e[B"

  # CursorDown1 is a sequence for moving the cursor down one cell.
  #
  # This is equivalent to CursorDown(1).
  #
  # Deprecated: use [CUD1] instead.
  CursorDown1 = "\e[B"

  # CursorForward (CUF) returns a sequence for moving the cursor right n cells.
  #
  # # CSI n C
  #
  # See: https://vt100.net/docs/vt510-rm/CUF.html
  def self.cursor_forward(n : Int32) : String
    s = n > 1 ? n.to_s : ""
    "\e[#{s}C"
  end

  # CUF is an alias for [cursor_forward].
  def self.cuf(n : Int32) : String
    cursor_forward(n)
  end

  # CUF1 is a sequence for moving the cursor right one cell.
  CUF1 = "\e[C"

  # CursorRight (CUF) returns a sequence for moving the cursor right n cells.
  #
  #	CSI n C
  #
  # See: https://vt100.net/docs/vt510-rm/CUF.html
  #
  # Deprecated: use [cursor_forward] instead.
  def self.cursor_right(n : Int32) : String
    cursor_forward(n)
  end

  # CursorRight1 is a sequence for moving the cursor right one cell.
  #
  # This is equivalent to CursorRight(1).
  #
  # Deprecated: use [CUF1] instead.
  CursorRight1 = CUF1

  # CursorBackward (CUB) returns a sequence for moving the cursor left n cells.
  #
  # # CSI n D
  #
  # See: https://vt100.net/docs/vt510-rm/CUB.html
  def self.cursor_backward(n : Int32) : String
    s = n > 1 ? n.to_s : ""
    "\e[#{s}D"
  end

  # CUB is an alias for [cursor_backward].
  def self.cub(n : Int32) : String
    cursor_backward(n)
  end

  # CUB1 is a sequence for moving the cursor left one cell.
  CUB1 = "\e[D"

  # CursorLeft (CUB) returns a sequence for moving the cursor left n cells.
  #
  #	CSI n D
  #
  # See: https://vt100.net/docs/vt510-rm/CUB.html
  #
  # Deprecated: use [cursor_backward] instead.
  def self.cursor_left(n : Int32) : String
    cursor_backward(n)
  end

  # CursorLeft1 is a sequence for moving the cursor left one cell.
  #
  # This is equivalent to CursorLeft(1).
  #
  # Deprecated: use [CUB1] instead.
  CursorLeft1 = CUB1

  # CursorNextLine (CNL) returns a sequence for moving the cursor to the
  # beginning of the next line n times.
  #
  #	CSI n E
  #
  # See: https://vt100.net/docs/vt510-rm/CNL.html
  def self.cursor_next_line(n : Int32) : String
    s = n > 1 ? n.to_s : ""
    "\e[#{s}E"
  end

  # CNL is an alias for [cursor_next_line].
  def self.cnl(n : Int32) : String
    cursor_next_line(n)
  end

  # CursorPreviousLine (CPL) returns a sequence for moving the cursor to the
  # beginning of the previous line n times.
  #
  #	CSI n F
  #
  # See: https://vt100.net/docs/vt510-rm/CPL.html
  def self.cursor_previous_line(n : Int32) : String
    s = n > 1 ? n.to_s : ""
    "\e[#{s}F"
  end

  # CPL is an alias for [cursor_previous_line].
  def self.cpl(n : Int32) : String
    cursor_previous_line(n)
  end

  # CursorHorizontalAbsolute (CHA) returns a sequence for moving the cursor to
  # the given column.
  #
  # Default is 1.
  #
  #	CSI n G
  #
  # See: https://vt100.net/docs/vt510-rm/CHA.html
  def self.cursor_horizontal_absolute(col : Int32) : String
    s = col > 0 ? col.to_s : ""
    "\e[#{s}G"
  end

  # CHA is an alias for [cursor_horizontal_absolute].
  def self.cha(col : Int32) : String
    cursor_horizontal_absolute(col)
  end

  # CursorPosition (CUP) returns a sequence for setting the cursor to the
  # given row and column.
  #
  # Default is 1,1.
  #
  #	CSI n ; m H
  #
  # See: https://vt100.net/docs/vt510-rm/CUP.html
  def self.cursor_position(col : Int32, row : Int32) : String
    if row <= 1 && col <= 1
      return CursorHomePosition
    end

    r = row > 0 ? row.to_s : ""
    c = col > 0 ? col.to_s : ""
    "\e[#{r};#{c}H"
  end

  # CUP is an alias for [cursor_position].
  def self.cup(col : Int32, row : Int32) : String
    cursor_position(col, row)
  end

  # CursorHomePosition is a sequence for moving the cursor to the upper left
  # corner of the scrolling region.
  #
  # This is equivalent to [cursor_position](1, 1).
  CursorHomePosition = "\e[H"

  # SetCursorPosition (CUP) returns a sequence for setting the cursor to the
  # given row and column.
  #
  #	CSI n ; m H
  #
  # See: https://vt100.net/docs/vt510-rm/CUP.html
  #
  # Deprecated: use [cursor_position] instead.
  def self.set_cursor_position(col : Int32, row : Int32) : String
    if row <= 0 && col <= 0
      return HomeCursorPosition
    end

    r = row > 0 ? row.to_s : ""
    c = col > 0 ? col.to_s : ""
    "\e[#{r};#{c}H"
  end

  # HomeCursorPosition is a sequence for moving the cursor to the upper left
  # corner of the scrolling region. This is equivalent to `set_cursor_position(1, 1)`.
  #
  # Deprecated: use [CursorHomePosition] instead.
  HomeCursorPosition = CursorHomePosition

  # MoveCursor (CUP) returns a sequence for setting the cursor to the
  # given row and column.
  #
  #	CSI n ; m H
  #
  # See: https://vt100.net/docs/vt510-rm/CUP.html
  #
  # Deprecated: use [cursor_position] instead.
  def self.move_cursor(col : Int32, row : Int32) : String
    set_cursor_position(col, row)
  end

  # CursorOrigin is a sequence for moving the cursor to the upper left corner of
  # the display. This is equivalent to `set_cursor_position(1, 1)`.
  #
  # Deprecated: use [CursorHomePosition] instead.
  CursorOrigin = "\e[1;1H"

  # MoveCursorOrigin is a sequence for moving the cursor to the upper left
  # corner of the display. This is equivalent to `set_cursor_position(1, 1)`.
  #
  # Deprecated: use [CursorHomePosition] instead.
  MoveCursorOrigin = CursorOrigin

  # CursorHorizontalForwardTab (CHT) returns a sequence for moving the cursor to
  # the next tab stop n times.
  #
  # Default is 1.
  #
  #	CSI n I
  #
  # See: https://vt100.net/docs/vt510-rm/CHT.html
  def self.cursor_horizontal_forward_tab(n : Int32) : String
    s = n > 1 ? n.to_s : ""
    "\e[#{s}I"
  end

  # CHT is an alias for [cursor_horizontal_forward_tab].
  def self.cht(n : Int32) : String
    cursor_horizontal_forward_tab(n)
  end

  # EraseCharacter (ECH) returns a sequence for erasing n characters from the
  # screen. This doesn't affect other cell attributes.
  #
  # Default is 1.
  #
  #	CSI n X
  #
  # See: https://vt100.net/docs/vt510-rm/ECH.html
  def self.erase_character(n : Int32) : String
    s = n > 1 ? n.to_s : ""
    "\e[#{s}X"
  end

  # ECH is an alias for [erase_character].
  def self.ech(n : Int32) : String
    erase_character(n)
  end

  # CursorBackwardTab (CBT) returns a sequence for moving the cursor to the
  # previous tab stop n times.
  #
  # Default is 1.
  #
  #	CSI n Z
  #
  # See: https://vt100.net/docs/vt510-rm/CBT.html
  def self.cursor_backward_tab(n : Int32) : String
    s = n > 1 ? n.to_s : ""
    "\e[#{s}Z"
  end

  # CBT is an alias for [cursor_backward_tab].
  def self.cbt(n : Int32) : String
    cursor_backward_tab(n)
  end

  # VerticalPositionAbsolute (VPA) returns a sequence for moving the cursor to
  # the given row.
  #
  # Default is 1.
  #
  #	CSI n d
  #
  # See: https://vt100.net/docs/vt510-rm/VPA.html
  def self.vertical_position_absolute(row : Int32) : String
    s = row > 0 ? row.to_s : ""
    "\e[#{s}d"
  end

  # VPA is an alias for [vertical_position_absolute].
  def self.vpa(row : Int32) : String
    vertical_position_absolute(row)
  end

  # VerticalPositionRelative (VPR) returns a sequence for moving the cursor down
  # n rows relative to the current position.
  #
  # Default is 1.
  #
  #	CSI n e
  #
  # See: https://vt100.net/docs/vt510-rm/VPR.html
  def self.vertical_position_relative(n : Int32) : String
    s = n > 1 ? n.to_s : ""
    "\e[#{s}e"
  end

  # VPR is an alias for [vertical_position_relative].
  def self.vpr(n : Int32) : String
    vertical_position_relative(n)
  end

  # HorizontalVerticalPosition (HVP) returns a sequence for moving the cursor to
  # the given row and column.
  #
  # Default is 1,1.
  #
  #	CSI n ; m f
  #
  # This has the same effect as [cursor_position].
  #
  # See: https://vt100.net/docs/vt510-rm/HVP.html
  def self.horizontal_vertical_position(col : Int32, row : Int32) : String
    r = row > 0 ? row.to_s : ""
    c = col > 0 ? col.to_s : ""
    "\e[#{r};#{c}f"
  end

  # HVP is an alias for [horizontal_vertical_position].
  def self.hvp(col : Int32, row : Int32) : String
    horizontal_vertical_position(col, row)
  end

  # HorizontalVerticalHomePosition is a sequence for moving the cursor to the
  # upper left corner of the scrolling region. This is equivalent to
  # `horizontal_vertical_position(1, 1)`.
  HorizontalVerticalHomePosition = "\e[f"

  # SaveCurrentCursorPosition (SCOSC) is a sequence for saving the current cursor
  # position for SCO console mode.
  #
  #	CSI s
  #
  # This acts like [DECSC], except the page number where the cursor is located
  # is not saved.
  #
  # See: https://vt100.net/docs/vt510-rm/SCOSC.html
  SaveCurrentCursorPosition = "\e[s"
  SCOSC                     = SaveCurrentCursorPosition

  # SaveCursorPosition (SCP or SCOSC) is a sequence for saving the cursor
  # position.
  #
  #	CSI s
  #
  # This acts like Save, except the page number where the cursor is located is
  # not saved.
  #
  # See: https://vt100.net/docs/vt510-rm/SCOSC.html
  #
  # Deprecated: use [SaveCurrentCursorPosition] instead.
  SaveCursorPosition = "\e[s"

  # RestoreCurrentCursorPosition (SCORC) is a sequence for restoring the current
  # cursor position for SCO console mode.
  #
  #	CSI u
  #
  # This acts like [DECRC], except the page number where the cursor was saved is
  # not restored.
  #
  # See: https://vt100.net/docs/vt510-rm/SCORC.html
  RestoreCurrentCursorPosition = "\e[u"
  SCORC                        = RestoreCurrentCursorPosition

  # RestoreCursorPosition (RCP or SCORC) is a sequence for restoring the cursor
  # position.
  #
  #	CSI u
  #
  # This acts like Restore, except the cursor stays on the same page where the
  # cursor was saved.
  #
  # See: https://vt100.net/docs/vt510-rm/SCORC.html
  #
  # Deprecated: use [RestoreCurrentCursorPosition] instead.
  RestoreCursorPosition = "\e[u"

  # SetCursorStyle (DECSCUSR) returns a sequence for changing the cursor style.
  #
  # Default is 1.
  #
  #	CSI Ps SP q
  #
  # Where Ps is the cursor style:
  #
  #	0: Blinking block
  #	1: Blinking block (default)
  #	2: Steady block
  #	3: Blinking underline
  #	4: Steady underline
  #	5: Blinking bar (xterm)
  #	6: Steady bar (xterm)
  #
  # See: https://vt100.net/docs/vt510-rm/DECSCUSR.html
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h4-Functions-using-CSI-_-ordered-by-the-final-character-lparen-s-rparen:CSI-Ps-SP-q.1D81
  # ameba:disable Naming/AccessorMethodName
  def self.set_cursor_style(style : Int32) : String
    style = 0 if style < 0
    "\e[#{style} q"
  end

  # DECSCUSR is an alias for [set_cursor_style].
  def self.decscusr(style : Int32) : String
    set_cursor_style(style)
  end

  # SetPointerShape returns a sequence for changing the mouse pointer cursor
  # shape. Use "default" for the default pointer shape.
  #
  #	OSC 22 ; Pt ST
  #	OSC 22 ; Pt BEL
  #
  # Where Pt is the pointer shape name. The name can be anything that the
  # operating system can understand. Some common names are:
  #
  #   - copy
  #   - crosshair
  #   - default
  #   - ew-resize
  #   - n-resize
  #   - text
  #   - wait
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h2-Operating-System-Commands
  # ameba:disable Naming/AccessorMethodName
  def self.set_pointer_shape(shape : String) : String
    "\e]22;#{shape}\a"
  end

  # ReverseIndex (RI) is an escape sequence for moving the cursor up one line in
  # the same column. If the cursor is at the top margin, the screen scrolls
  # down.
  #
  # This has the same effect as [RI].
  ReverseIndex = "\eM"

  # HorizontalPositionAbsolute (HPA) returns a sequence for moving the cursor to
  # the given column. This has the same effect as [CUP].
  #
  # Default is 1.
  #
  #	CSI n `
  #
  # See: https://vt100.net/docs/vt510-rm/HPA.html
  def self.horizontal_position_absolute(col : Int32) : String
    s = col > 0 ? col.to_s : ""
    "\e[#{s}`"
  end

  # HPA is an alias for [horizontal_position_absolute].
  def self.hpa(col : Int32) : String
    horizontal_position_absolute(col)
  end

  # HorizontalPositionRelative (HPR) returns a sequence for moving the cursor
  # right n columns relative to the current position. This has the same effect
  # as [CUP].
  #
  # Default is 1.
  #
  #	CSI n a
  #
  # See: https://vt100.net/docs/vt510-rm/HPR.html
  def self.horizontal_position_relative(n : Int32) : String
    s = n > 0 ? n.to_s : ""
    "\e[#{s}a"
  end

  # HPR is an alias for [horizontal_position_relative].
  def self.hpr(n : Int32) : String
    horizontal_position_relative(n)
  end

  # Index (IND) is an escape sequence for moving the cursor down one line in the
  # same column. If the cursor is at the bottom margin, the screen scrolls up.
  # This has the same effect as [IND].
  Index = "\eD"
end
