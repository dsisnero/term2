module Ansi
  # Focus is an escape sequence to notify the terminal that it has focus.
  # This is used with [ModeFocusEvent].
  Focus = "\e[I"

  # Blur is an escape sequence to notify the terminal that it has lost focus.
  # This is used with [ModeFocusEvent].
  Blur = "\e[O"
end
