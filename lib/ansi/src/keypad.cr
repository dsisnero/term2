module Ansi
  # Keypad Application Mode (DECKPAM) is a mode that determines whether the
  # keypad sends application sequences or ANSI sequences.
  #
  # This works like enabling [DECNKM].
  # Use [ModeNumericKeypad] to set the numeric keypad mode.
  #
  #	ESC =
  #
  # See: https://vt100.net/docs/vt510-rm/DECKPAM.html
  KeypadApplicationMode = "\e="
  DECKPAM               = KeypadApplicationMode

  # Keypad Numeric Mode (DECKPNM) is a mode that determines whether the keypad
  # sends application sequences or ANSI sequences.
  #
  # This works the same as disabling [DECNKM].
  #
  #	ESC >
  #
  # See: https://vt100.net/docs/vt510-rm/DECKPNM.html
  KeypadNumericMode = "\e>"
  DECKPNM           = KeypadNumericMode
end
