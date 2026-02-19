require "./color"
require "./style"
require "./image"
require "./iterm2"
require "./kitty"
require "./kitty_keyboard"
require "./sixel"
require "./mode"
require "./mode_deprecated"
require "./modes"
require "./mouse"
require "./urxvt"
require "./focus"
require "./parser_transition"
require "./parser_handler"
require "./parser"
require "./parser_decode"
require "./parser_sync"
require "./method"
require "./width"
require "./wrap"
require "./truncate"
require "./c0"
require "./ascii"
require "./c1"
require "./charset"
require "./ctrl"
require "./cursor"
require "./keypad"
require "./paste"
require "./finalterm"
require "./inband"
require "./passthrough"
require "./reset"
require "./screen"
require "./status"
require "./termcap"
require "./winop"
require "./xterm"
require "base64"
require "uri"
require "path"
require "colorful"

module Ansi
  # Execute writes the given escape sequence to the provided output.
  #
  # This is a syntactic sugar over IO#write.
  def self.execute(io : IO, s : String) : Int32
    io << s
    s.bytesize
  end

  def self.iterm2(data : String) : String
    "\e]1337;#{data}\a"
  end

  def self.sixel_graphics(p1 : Int32, p2 : Int32, p3 : Int32, payload : Bytes) : String
    String.build do |io|
      io << "\eP"
      io << p1 if p1 >= 0
      io << ';'
      io << p2 if p2 >= 0
      if p3 > 0
        io << ';' << p3
      end
      io << 'q'
      io.write(payload)
      io << "\e\\"
    end
  end

  def self.kitty_graphics(payload : Bytes, opts : Array(String) = [] of String) : String
    String.build do |io|
      io << "\e_G"
      io << opts.join(",")
      if payload.size > 0
        io << ';'
        io.write(payload)
      end
      io << "\e\\"
    end
  end

  # SetPalette sets the palette color for the given index. The index is a 16
  # color index between 0 and 15. The color is a 24-bit RGB color.
  #
  #	OSC P n rrggbb BEL
  #
  # Where n is the color index in hex (0-f), and rrggbb is the color in
  # hexadecimal format (e.g., ff0000 for red).
  #
  # This sequence is specific to the Linux Console and may not work in other
  # terminal emulators.
  #
  # See https://man7.org/linux/man-pages/man4/console_codes.4.html
  def self.set_palette(index : Int32, color : Ansi::PaletteColor? = nil) : String
    return "" if color.nil? || index < 0 || index > 15
    case color
    when Colorful::Color
      r, g, b = color.rgb255
    else
      r32, g32, b32, _ = color.rgba
      r = (r32 >> 8).to_u8
      g = (g32 >> 8).to_u8
      b = (b32 >> 8).to_u8
    end
    sprintf("\e]P%x%02x%02x%02x\a", index, r, g, b)
  end

  # ResetPalette resets the color palette to the default values.
  #
  # This sequence is specific to the Linux Console and may not work in other
  # terminal emulators.
  #
  # See https://man7.org/linux/man-pages/man4/console_codes.4.html
  ResetPalette = "\e]R\a"

  # SetIconNameWindowTitle returns a sequence for setting the icon name and
  # window title.
  #
  #	OSC 0 ; title ST
  #	OSC 0 ; title BEL
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h2-Operating-System-Commands
  # ameba:disable Naming/AccessorMethodName
  def self.set_icon_name_window_title(s : String) : String
    "\e]0;#{s}\a"
  end

  # SetIconName returns a sequence for setting the icon name.
  #
  #	OSC 1 ; title ST
  #	OSC 1 ; title BEL
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h2-Operating-System-Commands
  # ameba:disable Naming/AccessorMethodName
  def self.set_icon_name(s : String) : String
    "\e]1;#{s}\a"
  end

  # SetWindowTitle returns a sequence for setting the window title.
  #
  #	OSC 2 ; title ST
  #	OSC 2 ; title BEL
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h2-Operating-System-Commands
  # ameba:disable Naming/AccessorMethodName
  def self.set_window_title(s : String) : String
    "\e]2;#{s}\a"
  end

  # DECSWT is a sequence for setting the window title.
  #
  # This is an alias for SetWindowTitle("1;<name>").
  # See: EK-VT520-RM 5–156 https://vt100.net/dec/ek-vt520-rm.pdf
  def self.decswt(name : String) : String
    set_window_title("1;" + name)
  end

  # DECSIN is a sequence for setting the icon name.
  #
  # This is an alias for SetWindowTitle("L;<name>").
  # See: EK-VT520-RM 5–134 https://vt100.net/dec/ek-vt520-rm.pdf
  def self.decsin(name : String) : String
    set_window_title("L;" + name)
  end

  # NotifyWorkingDirectory returns a sequence that notifies the terminal
  # of the current working directory.
  #
  #	OSC 7 ; Pt BEL
  #
  # Where Pt is a URL in the format "file://[host]/[path]".
  # Set host to "localhost" if this is a path on the local computer.
  #
  # See: https://wezfurlong.org/wezterm/shell-integration.html#osc-7-escape-sequence-to-set-the-working-directory
  # See: https://iterm2.com/documentation-escape-codes.html#:~:text=RemoteHost%20and%20CurrentDir%3A-,OSC%207,-%3B%20%5BPs%5D%20ST
  def self.notify_working_directory(host : String, *paths : String) : String
    joined_path = "/" + paths.join("/")
    uri = URI.new(
      scheme: "file",
      host: host,
      path: joined_path
    )
    "\e]7;#{uri}\a"
  end

  # SetForegroundColor returns a sequence that sets the default terminal
  # foreground color.
  #
  #	OSC 10 ; color ST
  #	OSC 10 ; color BEL
  #
  # Where color is the encoded color number. Most terminals support hex,
  # XParseColor rgb: and rgba: strings.
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
  # ameba:disable Naming/AccessorMethodName
  def self.set_foreground_color(s : String) : String
    "\e]10;#{s}\a"
  end

  # RequestForegroundColor is a sequence that requests the current default
  # terminal foreground color.
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
  RequestForegroundColor = "\e]10;?\a"

  # ResetForegroundColor is a sequence that resets the default terminal
  # foreground color.
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
  ResetForegroundColor = "\e]110\a"

  # SetBackgroundColor returns a sequence that sets the default terminal
  # background color.
  #
  #	OSC 11 ; color ST
  #	OSC 11 ; color BEL
  #
  # Where color is the encoded color number. Most terminals support hex,
  # XParseColor rgb: and rgba: strings.
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
  # ameba:disable Naming/AccessorMethodName
  def self.set_background_color(s : String) : String
    "\e]11;#{s}\a"
  end

  # RequestBackgroundColor is a sequence that requests the current default
  # terminal background color.
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
  RequestBackgroundColor = "\e]11;?\a"

  # ResetBackgroundColor is a sequence that resets the default terminal
  # background color.
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
  ResetBackgroundColor = "\e]111\a"

  # SetCursorColor returns a sequence that sets the terminal cursor color.
  #
  #	OSC 12 ; color ST
  #	OSC 12 ; color BEL
  #
  # Where color is the encoded color number. Most terminals support hex,
  # XParseColor rgb: and rgba: strings.
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
  # ameba:disable Naming/AccessorMethodName
  def self.set_cursor_color(s : String) : String
    "\e]12;#{s}\a"
  end

  # RequestCursorColor is a sequence that requests the current terminal cursor
  # color.
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
  RequestCursorColor = "\e]12;?\a"

  # ResetCursorColor is a sequence that resets the terminal cursor color.
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
  ResetCursorColor = "\e]112\a"

  # SetHyperlink returns a sequence for starting a hyperlink.
  #
  #	OSC 8 ; Params ; Uri ST
  #	OSC 8 ; Params ; Uri BEL
  #
  # To reset the hyperlink, omit the URI.
  #
  # See: https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda
  def self.set_hyperlink(uri : String, *params) : String
    p = params.join(":")
    "\e]8;#{p};#{uri}\a"
  end

  # ResetHyperlink returns a sequence for resetting the hyperlink.
  #
  # This is equivalent to SetHyperlink("", params...).
  #
  # See: https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda
  def self.reset_hyperlink(*params) : String
    set_hyperlink("", *params)
  end

  # Notify sends a desktop notification using iTerm's OSC 9.
  #
  #	OSC 9 ; Mc ST
  #	OSC 9 ; Mc BEL
  #
  # Where Mc is the notification body.
  #
  # See: https://iterm2.com/documentation-escape-codes.html
  def self.notify(s : String) : String
    "\e]9;#{s}\a"
  end

  # DesktopNotification sends a desktop notification based on the extensible OSC
  # 99 escape code.
  #
  #	OSC 99 ; <metadata> ; <payload> ST
  #	OSC 99 ; <metadata> ; <payload> BEL
  #
  # Where <metadata> is a colon-separated list of key-value pairs, and
  # <payload> is the notification body.
  #
  # See: https://sw.kovidgoyal.net/kitty/desktop-notifications/
  def self.desktop_notification(payload : String, *metadata) : String
    m = metadata.join(":")
    "\e]99;#{m};#{payload}\a"
  end

  # ResetProgressBar is a sequence that resets the progress bar to its default
  # state (hidden).
  #
  # OSC 9 ; 4 ; 0 BEL
  #
  # See: https://learn.microsoft.com/en-us/windows/terminal/tutorials/progress-bar-sequences
  ResetProgressBar = "\e]9;4;0\a"

  # SetProgressBar returns a sequence for setting the progress bar to a specific
  # percentage (0-100) in the "default" state.
  #
  # OSC 9 ; 4 ; 1 Percentage BEL
  #
  # See: https://learn.microsoft.com/en-us/windows/terminal/tutorials/progress-bar-sequences
  # ameba:disable Naming/AccessorMethodName
  def self.set_progress_bar(percentage : Int32) : String
    p = Math.max(0, Math.min(percentage, 100))
    "\e]9;4;1;#{p}\a"
  end

  # SetErrorProgressBar returns a sequence for setting the progress bar to a
  # specific percentage (0-100) in the "Error" state.
  #
  # OSC 9 ; 4 ; 2 Percentage BEL
  #
  # See: https://learn.microsoft.com/en-us/windows/terminal/tutorials/progress-bar-sequences
  # ameba:disable Naming/AccessorMethodName
  def self.set_error_progress_bar(percentage : Int32) : String
    p = Math.max(0, Math.min(percentage, 100))
    "\e]9;4;2;#{p}\a"
  end

  # SetIndeterminateProgressBar is a sequence that sets the progress bar to the
  # indeterminate state.
  #
  # OSC 9 ; 4 ; 3 BEL
  #
  # See: https://learn.microsoft.com/en-us/windows/terminal/tutorials/progress-bar-sequences
  SetIndeterminateProgressBar = "\e]9;4;3\a"

  # SetWarningProgressBar is a sequence that sets the progress bar to the
  # "Warning" state.
  #
  # OSC 9 ; 4 ; 4 Percentage BEL
  #
  # See: https://learn.microsoft.com/en-us/windows/terminal/tutorials/progress-bar-sequences
  # ameba:disable Naming/AccessorMethodName
  def self.set_warning_progress_bar(percentage : Int32) : String
    p = Math.max(0, Math.min(percentage, 100))
    "\e]9;4;4;#{p}\a"
  end

  # Clipboard names.
  SystemClipboard  = 'c'.ord.to_u8
  PrimaryClipboard = 'p'.ord.to_u8

  # SetClipboard returns a sequence for manipulating the clipboard.
  #
  #	OSC 52 ; Pc ; Pd ST
  #	OSC 52 ; Pc ; Pd BEL
  #
  # Where Pc is the clipboard name and Pd is the base64 encoded data.
  # Empty data or invalid base64 data will reset the clipboard.
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
  def self.set_clipboard(c : UInt8, d : String) : String
    if d != ""
      d = Base64.strict_encode(d.to_slice)
    end
    "\e]52;#{c.chr};#{d}\a"
  end

  def self.set_clipboard(c : Char, d : String) : String
    set_clipboard(c.ord.to_u8, d)
  end

  # SetSystemClipboard returns a sequence for setting the system clipboard.
  #
  # This is equivalent to SetClipboard(SystemClipboard, d).
  # ameba:disable Naming/AccessorMethodName
  def self.set_system_clipboard(d : String) : String
    set_clipboard(SystemClipboard, d)
  end

  # SetPrimaryClipboard returns a sequence for setting the primary clipboard.
  #
  # This is equivalent to SetClipboard(PrimaryClipboard, d).
  # ameba:disable Naming/AccessorMethodName
  def self.set_primary_clipboard(d : String) : String
    set_clipboard(PrimaryClipboard, d)
  end

  # ResetClipboard returns a sequence for resetting the clipboard.
  #
  # This is equivalent to SetClipboard(c, "").
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
  def self.reset_clipboard(c : UInt8) : String
    set_clipboard(c, "")
  end

  def self.reset_clipboard(c : Char) : String
    set_clipboard(c, "")
  end

  # ResetSystemClipboard is a sequence for resetting the system clipboard.
  #
  # This is equivalent to ResetClipboard(SystemClipboard).
  ResetSystemClipboard = "\e]52;c;\a"

  # ResetPrimaryClipboard is a sequence for resetting the primary clipboard.
  #
  # This is equivalent to ResetClipboard(PrimaryClipboard).
  ResetPrimaryClipboard = "\e]52;p;\a"

  # RequestClipboard returns a sequence for requesting the clipboard.
  #
  # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
  def self.request_clipboard(c : UInt8) : String
    "\e]52;#{c.chr};?\a"
  end

  def self.request_clipboard(c : Char) : String
    request_clipboard(c.ord.to_u8)
  end

  # RequestSystemClipboard is a sequence for requesting the system clipboard.
  #
  # This is equivalent to RequestClipboard(SystemClipboard).
  RequestSystemClipboard = "\e]52;c;?\a"

  # RequestPrimaryClipboard is a sequence for requesting the primary clipboard.
  #
  # This is equivalent to RequestClipboard(PrimaryClipboard).
  RequestPrimaryClipboard = "\e]52;p;?\a"

  # SelectGraphicRendition (SGR) is a command that sets display attributes.
  #
  # Default is 0.
  #
  #	CSI Ps ; Ps ... m
  #
  # See: https://vt100.net/docs/vt510-rm/SGR.html
  def self.select_graphic_rendition(attrs : Array(Attr)) : String
    Style.new(attrs).to_s
  end

  def self.select_graphic_rendition(*attrs : Attr) : String
    select_graphic_rendition(attrs.to_a)
  end

  # SGR is an alias for `select_graphic_rendition`.
  def self.sgr(attrs : Array(Attr)) : String
    select_graphic_rendition(attrs)
  end

  def self.sgr(*attrs : Attr) : String
    sgr(attrs.to_a)
  end
end
