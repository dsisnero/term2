module Ansi
  # ResetInitialState (RIS) resets the terminal to its initial state.
  #
  #	ESC c
  #
  # See: https://vt100.net/docs/vt510-rm/RIS.html
  ResetInitialState = "\ec"
  RIS               = ResetInitialState
end
