module Ansi
  # XTGETTCAP (RequestTermcap) requests Termcap/Terminfo strings.
  #
  #	DCS + q <Pt> ST
  #
  # Where <Pt> is a list of Termcap/Terminfo capabilities, encoded in 2-digit
  # hexadecimals, separated by semicolons.
  #
  # See: https://man7.org/linux/man-pages/man5/terminfo.5.html
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
  def self.xtgettcap(*caps : String) : String
    return "" if caps.empty?

    encoded = caps.map do |cap|
      cap.bytes.map(&.to_s(16).rjust(2, '0')).join.upcase
    end

    "\eP+q#{encoded.join(";")}\e\\"
  end

  # RequestTermcap is an alias for [xtgettcap].
  def self.request_termcap(*caps : String) : String
    xtgettcap(*caps)
  end

  # RequestTerminfo is an alias for [xtgettcap].
  def self.request_terminfo(*caps : String) : String
    xtgettcap(*caps)
  end
end
