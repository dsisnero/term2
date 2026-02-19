module Ansi
  # RequestNameVersion (XTVERSION) is a control sequence that requests the
  # terminal's name and version. It responds with a DSR sequence identifying the
  # terminal.
  #
  #	CSI > 0 q
  #	DCS > | text ST
  #
  # See https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-PC-Style-Function-Keys
  RequestNameVersion = "\e[>q"
  XTVERSION          = RequestNameVersion

  # RequestXTVersion is a control sequence that requests the terminal's XTVERSION. It responds with a DSR sequence identifying the version.
  #
  #	CSI > Ps q
  #	DCS > | text ST
  #
  # See https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-PC-Style-Function-Keys
  #
  # Deprecated: use [RequestNameVersion] instead.
  RequestXTVersion = RequestNameVersion

  # PrimaryDeviceAttributes (DA1) is a control sequence that reports the
  # terminal's primary device attributes.
  #
  #	CSI c
  #	CSI 0 c
  #	CSI ? Ps ; ... c
  #
  # If no attributes are given, or if the attribute is 0, this function returns
  # the request sequence. Otherwise, it returns the response sequence.
  #
  # Common attributes include:
  #   - 1	132 columns
  #   - 2	Printer port
  #   - 4	Sixel
  #   - 6	Selective erase
  #   - 7	Soft character set (DRCS)
  #   - 8	User-defined keys (UDKs)
  #   - 9	National replacement character sets (NRCS) (International terminal only)
  #   - 12	Yugoslavian (SCS)
  #   - 15	Technical character set
  #   - 18	Windowing capability
  #   - 21	Horizontal scrolling
  #   - 23	Greek
  #   - 24	Turkish
  #   - 42	ISO Latin-2 character set
  #   - 44	PCTerm
  #   - 45	Soft key map
  #   - 46	ASCII emulation
  #
  # See https://vt100.net/docs/vt510-rm/DA1.html
  def self.primary_device_attributes(*attrs) : String
    args = attrs.to_a
    if args.empty?
      return RequestPrimaryDeviceAttributes
    elsif args.size == 1 && args[0] == 0
      return "\e[0c"
    end

    "\e[?#{args.join(';')}c"
  end

  # DA1 is an alias for [primary_device_attributes].
  def self.da1(*attrs) : String
    primary_device_attributes(*attrs)
  end

  # RequestPrimaryDeviceAttributes is a control sequence that requests the
  # terminal's primary device attributes (DA1).
  #
  #	CSI c
  #
  # See https://vt100.net/docs/vt510-rm/DA1.html
  RequestPrimaryDeviceAttributes = "\e[c"

  # SecondaryDeviceAttributes (DA2) is a control sequence that reports the
  # terminal's secondary device attributes.
  #
  #	CSI > c
  #	CSI > 0 c
  #	CSI > Ps ; ... c
  #
  # See https://vt100.net/docs/vt510-rm/DA2.html
  def self.secondary_device_attributes(*attrs) : String
    args = attrs.to_a
    if args.empty?
      return RequestSecondaryDeviceAttributes
    end

    "\e[>#{args.join(';')}c"
  end

  # DA2 is an alias for [secondary_device_attributes].
  def self.da2(*attrs) : String
    secondary_device_attributes(*attrs)
  end

  # RequestSecondaryDeviceAttributes is a control sequence that requests the
  # terminal's secondary device attributes (DA2).
  #
  #	CSI > c
  #
  # See https://vt100.net/docs/vt510-rm/DA2.html
  RequestSecondaryDeviceAttributes = "\e[>c"

  # TertiaryDeviceAttributes (DA3) is a control sequence that reports the
  # terminal's tertiary device attributes.
  #
  #	CSI = c
  #	CSI = 0 c
  #	DCS ! | Text ST
  #
  # Where Text is the unit ID for the terminal.
  #
  # If no unit ID is given, or if the unit ID is 0, this function returns the
  # request sequence. Otherwise, it returns the response sequence.
  #
  # See https://vt100.net/docs/vt510-rm/DA3.html
  def self.tertiary_device_attributes(unit_id : String) : String
    case unit_id
    when ""
      return RequestTertiaryDeviceAttributes
    when "0"
      return "\e[=0c"
    end

    "\eP!|#{unit_id}\e\\"
  end

  # DA3 is an alias for [tertiary_device_attributes].
  def self.da3(unit_id : String) : String
    tertiary_device_attributes(unit_id)
  end

  # RequestTertiaryDeviceAttributes is a control sequence that requests the
  # terminal's tertiary device attributes (DA3).
  #
  #	CSI = c
  #
  # See https://vt100.net/docs/vt510-rm/DA3.html
  RequestTertiaryDeviceAttributes = "\e[=c"
end
