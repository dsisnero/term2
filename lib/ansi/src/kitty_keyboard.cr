module Ansi
  # Kitty keyboard protocol progressive enhancement flags.
  # See: https://sw.kovidgoyal.net/kitty/keyboard-protocol/#progressive-enhancement
  KittyDisambiguateEscapeCodes    = 1
  KittyReportEventTypes           = 1 << 1
  KittyReportAlternateKeys        = 1 << 2
  KittyReportAllKeysAsEscapeCodes = 1 << 3
  KittyReportAssociatedKeys       = 1 << 4

  KittyAllFlags = KittyDisambiguateEscapeCodes | KittyReportEventTypes |
                  KittyReportAlternateKeys | KittyReportAllKeysAsEscapeCodes | KittyReportAssociatedKeys

  # RequestKittyKeyboard is a sequence to request the terminal Kitty keyboard
  # protocol enabled flags.
  #
  # See: https://sw.kovidgoyal.net/kitty/keyboard-protocol/
  RequestKittyKeyboard = "\e[?u"

  # KittyKeyboard returns a sequence to request keyboard enhancements from the terminal.
  # The flags argument is a bitmask of the Kitty keyboard protocol flags. While
  # mode specifies how the flags should be interpreted.
  #
  # Possible values for flags mask:
  #
  #	1:  Disambiguate escape codes
  #	2:  Report event types
  #	4:  Report alternate keys
  #	8:  Report all keys as escape codes
  #	16: Report associated text
  #
  # Possible values for mode:
  #
  #	1: Set given flags and unset all others
  #	2: Set given flags and keep existing flags unchanged
  #	3: Unset given flags and keep existing flags unchanged
  #
  # See https://sw.kovidgoyal.net/kitty/keyboard-protocol/#progressive-enhancement
  def self.kitty_keyboard(flags : Int32, mode : Int32) : String
    "\e[=#{flags};#{mode}u"
  end

  # PushKittyKeyboard returns a sequence to push the given flags to the terminal
  # Kitty Keyboard stack.
  #
  # Possible values for flags mask:
  #
  #	0:  Disable all features
  #	1:  Disambiguate escape codes
  #	2:  Report event types
  #	4:  Report alternate keys
  #	8:  Report all keys as escape codes
  #	16: Report associated text
  #
  #	CSI > flags u
  #
  # See https://sw.kovidgoyal.net/kitty/keyboard-protocol/#progressive-enhancement
  def self.push_kitty_keyboard(flags : Int32) : String
    f = flags > 0 ? flags.to_s : ""
    "\e[>#{f}u"
  end

  # DisableKittyKeyboard is a sequence to push zero into the terminal Kitty
  # Keyboard stack to disable the protocol.
  #
  # This is equivalent to PushKittyKeyboard(0).
  DisableKittyKeyboard = "\e[>u"

  # PopKittyKeyboard returns a sequence to pop n number of flags from the
  # terminal Kitty Keyboard stack.
  #
  #	CSI < flags u
  #
  # See https://sw.kovidgoyal.net/kitty/keyboard-protocol/#progressive-enhancement
  def self.pop_kitty_keyboard(n : Int32) : String
    num = n > 0 ? n.to_s : ""
    "\e[<#{num}u"
  end
end
