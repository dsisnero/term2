module Ansi
  # SelectCharacterSet sets the G-set character designator to the specified
  # character set.
  #
  #	ESC Ps Pd
  #
  # Where Ps is the G-set character designator, and Pd is the identifier.
  # For 94-character sets, the designator can be one of:
  #   - ( G0
  #   - ) G1
  #   - * G2
  #   - + G3
  #
  # For 96-character sets, the designator can be one of:
  #   - - G1
  #   - . G2
  #   - / G3
  #
  # Some common 94-character sets are:
  #   - 0 DEC Special Drawing Set
  #   - A United Kingdom (UK)
  #   - B United States (USASCII)
  #
  # Examples:
  #
  #	ESC ( B  Select character set G0 = United States (USASCII)
  #	ESC ( 0  Select character set G0 = Special Character and Line Drawing Set
  #	ESC ) 0  Select character set G1 = Special Character and Line Drawing Set
  #	ESC * A  Select character set G2 = United Kingdom (UK)
  #
  # See: https://vt100.net/docs/vt510-rm/SCS.html
  def self.select_character_set(gset : Char, charset : Char) : String
    "\e#{gset}#{charset}"
  end

  # SCS is an alias for SelectCharacterSet.
  def self.scs(gset : Char, charset : Char) : String
    select_character_set(gset, charset)
  end

  # LS1R (Locking Shift 1 Right) shifts G1 into GR character set.
  LS1R = "\e~"

  # LS2 (Locking Shift 2) shifts G2 into GL character set.
  LS2 = "\en"

  # LS2R (Locking Shift 2 Right) shifts G2 into GR character set.
  LS2R = "\e}"

  # LS3 (Locking Shift 3) shifts G3 into GL character set.
  LS3 = "\eo"

  # LS3R (Locking Shift 3 Right) shifts G3 into GR character set.
  LS3R = "\e|"
end
