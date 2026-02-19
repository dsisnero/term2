module Ansi
  # EraseDisplay (ED) clears the display or parts of the display. A screen is
  # the shown part of the terminal display excluding the scrollback buffer.
  # Possible values:
  #
  # Default is 0.
  #
  #	 0: Clear from cursor to end of screen.
  #	 1: Clear from cursor to beginning of the screen.
  #	 2: Clear entire screen (and moves cursor to upper left on DOS).
  #	 3: Clear entire display which delete all lines saved in the scrollback buffer (xterm).
  #
  #	CSI <n> J
  #
  # See: https://vt100.net/docs/vt510-rm/ED.html
  def self.erase_display(n : Int32) : String
    s = n > 0 ? n.to_s : ""
    "\e[#{s}J"
  end

  # ED is an alias for [erase_display].
  def self.ed(n : Int32) : String
    erase_display(n)
  end

  # EraseDisplay constants.
  # These are the possible values for the EraseDisplay function.
  EraseScreenBelow   = "\e[J"
  EraseScreenAbove   = "\e[1J"
  EraseEntireScreen  = "\e[2J"
  EraseEntireDisplay = "\e[3J"

  # EraseLine (EL) clears the current line or parts of the line. Possible values:
  #
  #	0: Clear from cursor to end of line.
  #	1: Clear from cursor to beginning of the line.
  #	2: Clear entire line.
  #
  # The cursor position is not affected.
  #
  #	CSI <n> K
  #
  # See: https://vt100.net/docs/vt510-rm/EL.html
  def self.erase_line(n : Int32) : String
    s = n > 0 ? n.to_s : ""
    "\e[#{s}K"
  end

  # EL is an alias for [erase_line].
  def self.el(n : Int32) : String
    erase_line(n)
  end

  # EraseLine constants.
  # These are the possible values for the EraseLine function.
  EraseLineRight  = "\e[K"
  EraseLineLeft   = "\e[1K"
  EraseEntireLine = "\e[2K"

  # ScrollUp (SU) scrolls the screen up n lines. New lines are added at the
  # bottom of the screen.
  #
  #	CSI Pn S
  #
  # See: https://vt100.net/docs/vt510-rm/SU.html
  def self.scroll_up(n : Int32) : String
    s = n > 1 ? n.to_s : ""
    "\e[#{s}S"
  end

  # PanDown is an alias for [scroll_up].
  def self.pan_down(n : Int32) : String
    scroll_up(n)
  end

  # SU is an alias for [scroll_up].
  def self.su(n : Int32) : String
    scroll_up(n)
  end

  # ScrollDown (SD) scrolls the screen down n lines. New lines are added at the
  # top of the screen.
  #
  #	CSI Pn T
  #
  # See: https://vt100.net/docs/vt510-rm/SD.html
  def self.scroll_down(n : Int32) : String
    s = n > 1 ? n.to_s : ""
    "\e[#{s}T"
  end

  # PanUp is an alias for [scroll_down].
  def self.pan_up(n : Int32) : String
    scroll_down(n)
  end

  # SD is an alias for [scroll_down].
  def self.sd(n : Int32) : String
    scroll_down(n)
  end

  # InsertLine (IL) inserts n blank lines at the current cursor position.
  # Existing lines are moved down.
  #
  #	CSI Pn L
  #
  # See: https://vt100.net/docs/vt510-rm/IL.html
  def self.insert_line(n : Int32) : String
    s = n > 1 ? n.to_s : ""
    "\e[#{s}L"
  end

  # IL is an alias for [insert_line].
  def self.il(n : Int32) : String
    insert_line(n)
  end

  # DeleteLine (DL) deletes n lines at the current cursor position. Existing
  # lines are moved up.
  #
  #	CSI Pn M
  #
  # See: https://vt100.net/docs/vt510-rm/DL.html
  def self.delete_line(n : Int32) : String
    s = n > 1 ? n.to_s : ""
    "\e[#{s}M"
  end

  # DL is an alias for [delete_line].
  def self.dl(n : Int32) : String
    delete_line(n)
  end

  # SetTopBottomMargins (DECSTBM) sets the top and bottom margins for the scrolling
  # region. The default is the entire screen.
  #
  # Default is 1 and the bottom of the screen.
  #
  #	CSI Pt ; Pb r
  #
  # See: https://vt100.net/docs/vt510-rm/DECSTBM.html
  def self.set_top_bottom_margins(top : Int32, bot : Int32) : String
    t = top > 0 ? top.to_s : ""
    b = bot > 0 ? bot.to_s : ""
    "\e[#{t};#{b}r"
  end

  # DECSTBM is an alias for [set_top_bottom_margins].
  def self.decstbm(top : Int32, bot : Int32) : String
    set_top_bottom_margins(top, bot)
  end

  # SetLeftRightMargins (DECSLRM) sets the left and right margins for the scrolling
  # region.
  #
  # Default is 1 and the right of the screen.
  #
  #	CSI Pl ; Pr s
  #
  # See: https://vt100.net/docs/vt510-rm/DECSLRM.html
  def self.set_left_right_margins(left : Int32, right : Int32) : String
    l = left > 0 ? left.to_s : ""
    r = right > 0 ? right.to_s : ""
    "\e[#{l};#{r}s"
  end

  # DECSLRM is an alias for [set_left_right_margins].
  def self.decslrm(left : Int32, right : Int32) : String
    set_left_right_margins(left, right)
  end

  # SetScrollingRegion (DECSTBM) sets the top and bottom margins for the scrolling
  # region. The default is the entire screen.
  #
  #	CSI <top> ; <bottom> r
  #
  # See: https://vt100.net/docs/vt510-rm/DECSTBM.html
  #
  # Deprecated: use [set_top_bottom_margins] instead.
  def self.set_scrolling_region(t : Int32, b : Int32) : String
    t = 0 if t < 0
    b = 0 if b < 0
    "\e[#{t};#{b}r"
  end

  # InsertCharacter (ICH) inserts n blank characters at the current cursor
  # position. Existing characters move to the right. Characters moved past the
  # right margin are lost. ICH has no effect outside the scrolling margins.
  #
  # Default is 1.
  #
  #	CSI Pn @
  #
  # See: https://vt100.net/docs/vt510-rm/ICH.html
  def self.insert_character(n : Int32) : String
    s = n > 1 ? n.to_s : ""
    "\e[#{s}@"
  end

  # ICH is an alias for [insert_character].
  def self.ich(n : Int32) : String
    insert_character(n)
  end

  # DeleteCharacter (DCH) deletes n characters at the current cursor position.
  # As the characters are deleted, the remaining characters move to the left and
  # the cursor remains at the same position.
  #
  # Default is 1.
  #
  #	CSI Pn P
  #
  # See: https://vt100.net/docs/vt510-rm/DCH.html
  def self.delete_character(n : Int32) : String
    s = n > 1 ? n.to_s : ""
    "\e[#{s}P"
  end

  # DCH is an alias for [delete_character].
  def self.dch(n : Int32) : String
    delete_character(n)
  end

  # SetTabEvery8Columns (DECST8C) sets the tab stops at every 8 columns.
  #
  #	CSI ? 5 W
  #
  # See: https://vt100.net/docs/vt510-rm/DECST8C.html
  SetTabEvery8Columns = "\e[?5W"
  DECST8C             = SetTabEvery8Columns

  # HorizontalTabSet (HTS) sets a horizontal tab stop at the current cursor
  # column.
  #
  # This is equivalent to [HTS].
  #
  #	ESC H
  #
  # See: https://vt100.net/docs/vt510-rm/HTS.html
  HorizontalTabSet = "\eH"

  # TabClear (TBC) clears tab stops.
  #
  # Default is 0.
  #
  # Possible values:
  # 0: Clear tab stop at the current column. (default)
  # 3: Clear all tab stops.
  #
  #	CSI Pn g
  #
  # See: https://vt100.net/docs/vt510-rm/TBC.html
  def self.tab_clear(n : Int32) : String
    s = n > 0 ? n.to_s : ""
    "\e[#{s}g"
  end

  # TBC is an alias for [tab_clear].
  def self.tbc(n : Int32) : String
    tab_clear(n)
  end

  # RequestPresentationStateReport (DECRQPSR) requests the terminal to send a
  # report of the presentation state. This includes the cursor information [DECCIR],
  # and tab stop [DECTABSR] reports.
  #
  # Default is 0.
  #
  # Possible values:
  # 0: Error, request ignored.
  # 1: Cursor information report [DECCIR].
  # 2: Tab stop report [DECTABSR].
  #
  #	CSI Ps $ w
  #
  # See: https://vt100.net/docs/vt510-rm/DECRQPSR.html
  def self.request_presentation_state_report(n : Int32) : String
    s = n > 0 ? n.to_s : ""
    "\e[#{s}$w"
  end

  # DECRQPSR is an alias for [request_presentation_state_report].
  def self.decrqpsr(n : Int32) : String
    request_presentation_state_report(n)
  end

  # TabStopReport (DECTABSR) is the response to a tab stop report request.
  # It reports the tab stops set in the terminal.
  #
  # The response is a list of tab stops separated by a slash (/) character.
  #
  #	DCS 2 $ u D ... D ST
  #
  # Where D is a decimal number representing a tab stop.
  #
  # See: https://vt100.net/docs/vt510-rm/DECTABSR.html
  def self.tab_stop_report(*stops : Int32) : String
    parts = [] of String
    stops.each { |v| parts << v.to_s }
    "\eP2$u#{parts.join("/")}\e\\"
  end

  # DECTABSR is an alias for [tab_stop_report].
  def self.dectabsr(*stops : Int32) : String
    tab_stop_report(*stops)
  end

  # CursorInformationReport (DECCIR) is the response to a cursor information
  # report request. It reports the cursor position, visual attributes, and
  # character protection attributes. It also reports the status of origin mode
  # [DECOM] and the current active character set.
  #
  # The response is a list of values separated by a semicolon (;) character.
  #
  #	DCS 1 $ u D ... D ST
  #
  # Where D is a decimal number representing a value.
  #
  # See: https://vt100.net/docs/vt510-rm/DECCIR.html
  def self.cursor_information_report(*values : Int32) : String
    parts = [] of String
    values.each { |v| parts << v.to_s }
    "\eP1$u#{parts.join(";")}\e\\"
  end

  # DECCIR is an alias for [cursor_information_report].
  def self.deccir(*values : Int32) : String
    cursor_information_report(*values)
  end

  # RepeatPreviousCharacter (REP) repeats the previous character n times.
  # This is identical to typing the same character n times.
  #
  # Default is 1.
  #
  #	CSI Pn b
  #
  # See: ECMA-48 § 8.3.103.
  def self.repeat_previous_character(n : Int32) : String
    s = n > 1 ? n.to_s : ""
    "\e[#{s}b"
  end

  # REP is an alias for [repeat_previous_character].
  def self.rep(n : Int32) : String
    repeat_previous_character(n)
  end
end
