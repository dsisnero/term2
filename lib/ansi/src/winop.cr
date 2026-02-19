module Ansi
  # ResizeWindowWinOp is a window operation that resizes the terminal
  # window.
  #
  # Deprecated: Use constant number directly with [window_op].
  ResizeWindowWinOp = 4

  # RequestWindowSizeWinOp is a window operation that requests a report of
  # the size of the terminal window in pixels. The response is in the form:
  #  CSI 4 ; height ; width t
  #
  # Deprecated: Use constant number directly with [window_op].
  RequestWindowSizeWinOp = 14

  # RequestCellSizeWinOp is a window operation that requests a report of
  # the size of the terminal cell size in pixels. The response is in the form:
  #  CSI 6 ; height ; width t
  #
  # Deprecated: Use constant number directly with [window_op].
  RequestCellSizeWinOp = 16

  # WindowOp (XTWINOPS) is a sequence that manipulates the terminal window.
  #
  #	CSI Ps ; Ps ; Ps t
  #
  # Ps is a semicolon-separated list of parameters.
  # See https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h4-Functions-using-CSI-_-ordered-by-the-final-character-lparen-s-rparen:CSI-Ps;Ps;Ps-t.1EB0
  def self.window_op(p : Int32, *ps : Int32) : String
    return "" if p <= 0

    if ps.empty?
      return "\e[#{p}t"
    end

    params = [p.to_s]
    ps.each do |value|
      params << value.to_s if value >= 0
    end

    "\e[#{params.join(";")}t"
  end

  # XTWINOPS is an alias for [window_op].
  def self.xtwinops(p : Int32, *ps : Int32) : String
    window_op(p, *ps)
  end
end
