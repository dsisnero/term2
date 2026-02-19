module Ansi
  # KeyModifierOptions (XTMODKEYS) sets/resets xterm key modifier options.
  #
  # Default is 0.
  #
  #	CSI > Pp m
  #	CSI > Pp ; Pv m
  #
  # If Pv is omitted, the resource is reset to its initial value.
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Functions-using-CSI-_-ordered-by-the-final-character_s_
  def self.key_modifier_options(p : Int32, *vs : Int32) : String
    pp = p > 0 ? p.to_s : ""

    if vs.empty?
      return "\e[>#{p}m"
    end

    v = vs[0]
    if v > 0
      return "\e[>#{pp};#{v}m"
    end

    "\e[>#{pp}m"
  end

  # XTMODKEYS is an alias for [key_modifier_options].
  def self.xtmodkeys(p : Int32, *vs : Int32) : String
    key_modifier_options(p, *vs)
  end

  # SetKeyModifierOptions sets xterm key modifier options.
  # This is an alias for [key_modifier_options].
  def self.set_key_modifier_options(pp : Int32, pv : Int32) : String
    key_modifier_options(pp, pv)
  end

  # ResetKeyModifierOptions resets xterm key modifier options.
  # This is an alias for [key_modifier_options].
  def self.reset_key_modifier_options(pp : Int32) : String
    key_modifier_options(pp)
  end

  # QueryKeyModifierOptions (XTQMODKEYS) requests xterm key modifier options.
  #
  # Default is 0.
  #
  #	CSI ? Pp m
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Functions-using-CSI-_-ordered-by-the-final-character_s_
  def self.query_key_modifier_options(pp : Int32) : String
    p = pp > 0 ? pp.to_s : ""
    "\e[?#{p}m"
  end

  # XTQMODKEYS is an alias for [query_key_modifier_options].
  def self.xtqmodkeys(pp : Int32) : String
    query_key_modifier_options(pp)
  end

  # Modify Other Keys (modifyOtherKeys) is an xterm feature that allows the
  # terminal to modify the behavior of certain keys to send different escape
  # sequences when pressed.
  #
  # See: https://invisible-island.net/xterm/manpage/xterm.html#VT100-Widget-Resources:modifyOtherKeys
  SetModifyOtherKeys1  = "\e[>4;1m"
  SetModifyOtherKeys2  = "\e[>4;2m"
  ResetModifyOtherKeys = "\e[>4m"
  QueryModifyOtherKeys = "\e[?4m"

  # ModifyOtherKeys returns a sequence that sets XTerm modifyOtherKeys mode.
  # The mode argument specifies the mode to set.
  #
  #	0: Disable modifyOtherKeys mode.
  #	1: Enable modifyOtherKeys mode 1.
  #	2: Enable modifyOtherKeys mode 2.
  #
  #	CSI > 4 ; mode m
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Functions-using-CSI-_-ordered-by-the-final-character_s_
  # See: https://invisible-island.net/xterm/manpage/xterm.html#VT100-Widget-Resources:modifyOtherKeys
  #
  # Deprecated: use [SetModifyOtherKeys1] or [SetModifyOtherKeys2] instead.
  def self.modify_other_keys(mode : Int32) : String
    "\e[>4;#{mode}m"
  end

  # DisableModifyOtherKeys disables the modifyOtherKeys mode.
  #
  #	CSI > 4 ; 0 m
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Functions-using-CSI-_-ordered-by-the-final-character_s_
  # See: https://invisible-island.net/xterm/manpage/xterm.html#VT100-Widget-Resources:modifyOtherKeys
  #
  # Deprecated: use [ResetModifyOtherKeys] instead.
  DisableModifyOtherKeys = "\e[>4;0m"

  # EnableModifyOtherKeys1 enables the modifyOtherKeys mode 1.
  #
  #	CSI > 4 ; 1 m
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Functions-using-CSI-_-ordered-by-the-final-character_s_
  # See: https://invisible-island.net/xterm/manpage/xterm.html#VT100-Widget-Resources:modifyOtherKeys
  #
  # Deprecated: use [SetModifyOtherKeys1] instead.
  EnableModifyOtherKeys1 = "\e[>4;1m"

  # EnableModifyOtherKeys2 enables the modifyOtherKeys mode 2.
  #
  #	CSI > 4 ; 2 m
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Functions-using-CSI-_-ordered-by-the-final-character_s_
  # See: https://invisible-island.net/xterm/manpage/xterm.html#VT100-Widget-Resources:modifyOtherKeys
  #
  # Deprecated: use [SetModifyOtherKeys2] instead.
  EnableModifyOtherKeys2 = "\e[>4;2m"

  # RequestModifyOtherKeys requests the modifyOtherKeys mode.
  #
  #	CSI ? 4  m
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Functions-using-CSI-_-ordered-by-the-final-character_s_
  # See: https://invisible-island.net/xterm/manpage/xterm.html#VT100-Widget-Resources:modifyOtherKeys
  #
  # Deprecated: use [QueryModifyOtherKeys] instead.
  RequestModifyOtherKeys = "\e[?4m"
end
