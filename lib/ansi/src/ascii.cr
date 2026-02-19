module Ansi
  module ASCII
    # SP is the space character (Char: \x20).
    SP = 0x20_u8
    # DEL is the delete character (Caret: ^?, Char: \x7f).
    DEL = 0x7F_u8
  end

  # Constants for easy access at module top level
  SP  = ASCII::SP
  DEL = ASCII::DEL
end
