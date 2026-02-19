module Ansi
  enum ModeSetting : UInt8
    ModeNotRecognized    = 0
    ModeSet              = 1
    ModeReset            = 2
    ModePermanentlySet   = 3
    ModePermanentlyReset = 4

    # ameba:disable Naming/PredicateName
    def is_not_recognized : Bool
      self == ModeNotRecognized
    end

    # ameba:disable Naming/PredicateName
    def is_set : Bool
      self == ModeSet || self == ModePermanentlySet
    end

    # ameba:disable Naming/PredicateName
    def is_reset : Bool
      self == ModeReset || self == ModePermanentlyReset
    end

    # ameba:disable Naming/PredicateName
    def is_permanently_set : Bool
      self == ModePermanentlySet
    end

    # ameba:disable Naming/PredicateName
    def is_permanently_reset : Bool
      self == ModePermanentlyReset
    end
  end

  ModeNotRecognized    = ModeSetting::ModeNotRecognized
  ModeSet              = ModeSetting::ModeSet
  ModeReset            = ModeSetting::ModeReset
  ModePermanentlySet   = ModeSetting::ModePermanentlySet
  ModePermanentlyReset = ModeSetting::ModePermanentlyReset

  struct ANSIMode
    getter value : Int32

    def initialize(@value : Int32)
    end

    def mode : Int32
      @value
    end

    def_equals @value
    def_hash @value
  end

  struct DECMode
    getter value : Int32

    def initialize(@value : Int32)
    end

    def mode : Int32
      @value
    end

    def_equals @value
    def_hash @value
  end

  alias Mode = ANSIMode | DECMode

  # ameba:disable Naming/AccessorMethodName
  def self.set_mode(*modes : Mode) : String
    set_mode(false, modes.to_a)
  end

  def self.set_mode : String
    ""
  end

  def self.sm(*modes : Mode) : String
    set_mode(*modes)
  end

  def self.decset(*modes : Mode) : String
    set_mode(*modes)
  end

  def self.reset_mode(*modes : Mode) : String
    set_mode(true, modes.to_a)
  end

  def self.reset_mode : String
    ""
  end

  def self.rm(*modes : Mode) : String
    reset_mode(*modes)
  end

  def self.decrst(*modes : Mode) : String
    reset_mode(*modes)
  end

  private def self.set_mode(reset : Bool, modes : Array(Mode)) : String
    return "" if modes.empty?

    cmd = reset ? "l" : "h"
    seq = "\e["

    if modes.size == 1
      mode = modes[0]
      prefix = mode.is_a?(DECMode) ? "?" : ""
      return "#{seq}#{prefix}#{mode.mode}#{cmd}"
    end

    dec = [] of String
    ansi = [] of String
    modes.each do |mode_value|
      case mode_value
      when DECMode
        dec << mode_value.mode.to_s
      when ANSIMode
        ansi << mode_value.mode.to_s
      end
    end

    String.build do |io|
      if ansi.size > 0
        io << seq << ansi.join(";") << cmd
      end
      if dec.size > 0
        io << seq << "?" << dec.join(";") << cmd
      end
    end
  end

  def self.request_mode(mode : Mode) : String
    seq = mode.is_a?(DECMode) ? "\e[?" : "\e["
    "#{seq}#{mode.mode}$p"
  end

  def self.decrqm(mode : Mode) : String
    request_mode(mode)
  end

  def self.report_mode(mode : Mode, value : ModeSetting) : String
    report_mode(mode, value.value.to_i)
  end

  def self.report_mode(mode : Mode, value : Int32) : String
    value = 0 if value > 4
    seq = mode.is_a?(DECMode) ? "\e[?" : "\e["
    "#{seq}#{mode.mode};#{value}$y"
  end

  def self.decrpm(mode : Mode, value : ModeSetting) : String
    report_mode(mode, value)
  end

  # Keyboard Action Mode (KAM)
  ModeKeyboardAction = ANSIMode.new(2)
  KAM                = ModeKeyboardAction

  SetModeKeyboardAction     = "\e[2h"
  ResetModeKeyboardAction   = "\e[2l"
  RequestModeKeyboardAction = "\e[2$p"

  # Insert/Replace Mode (IRM)
  ModeInsertReplace = ANSIMode.new(4)
  IRM               = ModeInsertReplace

  SetModeInsertReplace     = "\e[4h"
  ResetModeInsertReplace   = "\e[4l"
  RequestModeInsertReplace = "\e[4$p"

  # BiDirectional Support Mode (BDSM)
  ModeBiDirectionalSupport = ANSIMode.new(8)
  BDSM                     = ModeBiDirectionalSupport

  SetModeBiDirectionalSupport     = "\e[8h"
  ResetModeBiDirectionalSupport   = "\e[8l"
  RequestModeBiDirectionalSupport = "\e[8$p"

  # Send Receive Mode (SRM) / Local Echo
  ModeSendReceive = ANSIMode.new(12)
  ModeLocalEcho   = ModeSendReceive
  SRM             = ModeSendReceive

  SetModeSendReceive     = "\e[12h"
  ResetModeSendReceive   = "\e[12l"
  RequestModeSendReceive = "\e[12$p"

  SetModeLocalEcho     = "\e[12h"
  ResetModeLocalEcho   = "\e[12l"
  RequestModeLocalEcho = "\e[12$p"

  # Line Feed/New Line Mode (LNM)
  ModeLineFeedNewLine = ANSIMode.new(20)
  LNM                 = ModeLineFeedNewLine

  SetModeLineFeedNewLine     = "\e[20h"
  ResetModeLineFeedNewLine   = "\e[20l"
  RequestModeLineFeedNewLine = "\e[20$p"

  # Cursor Keys Mode (DECCKM)
  ModeCursorKeys = DECMode.new(1)
  DECCKM         = ModeCursorKeys

  SetModeCursorKeys     = "\e[?1h"
  ResetModeCursorKeys   = "\e[?1l"
  RequestModeCursorKeys = "\e[?1$p"

  # Origin Mode (DECOM)
  ModeOrigin = DECMode.new(6)
  DECOM      = ModeOrigin

  SetModeOrigin     = "\e[?6h"
  ResetModeOrigin   = "\e[?6l"
  RequestModeOrigin = "\e[?6$p"

  # Auto Wrap Mode (DECAWM)
  ModeAutoWrap = DECMode.new(7)
  DECAWM       = ModeAutoWrap

  SetModeAutoWrap     = "\e[?7h"
  ResetModeAutoWrap   = "\e[?7l"
  RequestModeAutoWrap = "\e[?7$p"

  # X10 Mouse Mode
  ModeMouseX10 = DECMode.new(9)

  SetModeMouseX10     = "\e[?9h"
  ResetModeMouseX10   = "\e[?9l"
  RequestModeMouseX10 = "\e[?9$p"

  # Text Cursor Enable Mode (DECTCEM)
  ModeTextCursorEnable = DECMode.new(25)
  DECTCEM              = ModeTextCursorEnable

  SetModeTextCursorEnable     = "\e[?25h"
  ResetModeTextCursorEnable   = "\e[?25l"
  RequestModeTextCursorEnable = "\e[?25$p"

  ShowCursor = SetModeTextCursorEnable
  HideCursor = ResetModeTextCursorEnable

  # Numeric Keypad Mode (DECNKM)
  ModeNumericKeypad = DECMode.new(66)
  DECNKM            = ModeNumericKeypad

  SetModeNumericKeypad     = "\e[?66h"
  ResetModeNumericKeypad   = "\e[?66l"
  RequestModeNumericKeypad = "\e[?66$p"

  # Backarrow Key Mode (DECBKM)
  ModeBackarrowKey = DECMode.new(67)
  DECBKM           = ModeBackarrowKey

  SetModeBackarrowKey     = "\e[?67h"
  ResetModeBackarrowKey   = "\e[?67l"
  RequestModeBackarrowKey = "\e[?67$p"

  # Left Right Margin Mode (DECLRMM)
  ModeLeftRightMargin = DECMode.new(69)
  DECLRMM             = ModeLeftRightMargin

  SetModeLeftRightMargin     = "\e[?69h"
  ResetModeLeftRightMargin   = "\e[?69l"
  RequestModeLeftRightMargin = "\e[?69$p"

  # Normal Mouse Mode
  ModeMouseNormal = DECMode.new(1000)

  SetModeMouseNormal     = "\e[?1000h"
  ResetModeMouseNormal   = "\e[?1000l"
  RequestModeMouseNormal = "\e[?1000$p"

  # Highlight Mouse Mode
  ModeMouseHighlight = DECMode.new(1001)

  SetModeMouseHighlight     = "\e[?1001h"
  ResetModeMouseHighlight   = "\e[?1001l"
  RequestModeMouseHighlight = "\e[?1001$p"

  # Button Event Mouse Mode
  ModeMouseButtonEvent = DECMode.new(1002)

  SetModeMouseButtonEvent     = "\e[?1002h"
  ResetModeMouseButtonEvent   = "\e[?1002l"
  RequestModeMouseButtonEvent = "\e[?1002$p"

  # Any Event Mouse Mode
  ModeMouseAnyEvent = DECMode.new(1003)

  SetModeMouseAnyEvent     = "\e[?1003h"
  ResetModeMouseAnyEvent   = "\e[?1003l"
  RequestModeMouseAnyEvent = "\e[?1003$p"

  # Focus Event Mode
  ModeFocusEvent = DECMode.new(1004)

  SetModeFocusEvent     = "\e[?1004h"
  ResetModeFocusEvent   = "\e[?1004l"
  RequestModeFocusEvent = "\e[?1004$p"

  # UTF-8 Extended Mouse Mode
  ModeMouseExtUtf8 = DECMode.new(1005)

  SetModeMouseExtUtf8     = "\e[?1005h"
  ResetModeMouseExtUtf8   = "\e[?1005l"
  RequestModeMouseExtUtf8 = "\e[?1005$p"

  # SGR Extended Mouse Mode
  ModeMouseExtSgr = DECMode.new(1006)

  SetModeMouseExtSgr     = "\e[?1006h"
  ResetModeMouseExtSgr   = "\e[?1006l"
  RequestModeMouseExtSgr = "\e[?1006$p"

  # URXVT Extended Mouse Mode
  ModeMouseExtUrxvt = DECMode.new(1015)

  SetModeMouseExtUrxvt     = "\e[?1015h"
  ResetModeMouseExtUrxvt   = "\e[?1015l"
  RequestModeMouseExtUrxvt = "\e[?1015$p"

  # SGR Pixel Extended Mouse Mode
  ModeMouseExtSgrPixel = DECMode.new(1016)

  SetModeMouseExtSgrPixel     = "\e[?1016h"
  ResetModeMouseExtSgrPixel   = "\e[?1016l"
  RequestModeMouseExtSgrPixel = "\e[?1016$p"

  # Alternate Screen Mode
  ModeAltScreen = DECMode.new(1047)

  SetModeAltScreen     = "\e[?1047h"
  ResetModeAltScreen   = "\e[?1047l"
  RequestModeAltScreen = "\e[?1047$p"

  # Save Cursor Mode
  ModeSaveCursor = DECMode.new(1048)

  SetModeSaveCursor     = "\e[?1048h"
  ResetModeSaveCursor   = "\e[?1048l"
  RequestModeSaveCursor = "\e[?1048$p"

  # Alternate Screen Save Cursor Mode
  ModeAltScreenSaveCursor = DECMode.new(1049)

  SetModeAltScreenSaveCursor     = "\e[?1049h"
  ResetModeAltScreenSaveCursor   = "\e[?1049l"
  RequestModeAltScreenSaveCursor = "\e[?1049$p"

  # Bracketed Paste Mode
  ModeBracketedPaste = DECMode.new(2004)

  SetModeBracketedPaste     = "\e[?2004h"
  ResetModeBracketedPaste   = "\e[?2004l"
  RequestModeBracketedPaste = "\e[?2004$p"

  # Synchronized Output Mode
  ModeSynchronizedOutput = DECMode.new(2026)

  SetModeSynchronizedOutput     = "\e[?2026h"
  ResetModeSynchronizedOutput   = "\e[?2026l"
  RequestModeSynchronizedOutput = "\e[?2026$p"

  # Unicode Core Mode
  ModeUnicodeCore = DECMode.new(2027)

  SetModeUnicodeCore     = "\e[?2027h"
  ResetModeUnicodeCore   = "\e[?2027l"
  RequestModeUnicodeCore = "\e[?2027$p"

  # Light/Dark Mode
  ModeLightDark = DECMode.new(2031)

  SetModeLightDark     = "\e[?2031h"
  ResetModeLightDark   = "\e[?2031l"
  RequestModeLightDark = "\e[?2031$p"

  # In Band Resize Mode
  ModeInBandResize = DECMode.new(2048)

  SetModeInBandResize     = "\e[?2048h"
  ResetModeInBandResize   = "\e[?2048l"
  RequestModeInBandResize = "\e[?2048$p"

  # Win32 Input Mode
  ModeWin32Input = DECMode.new(9001)

  SetModeWin32Input     = "\e[?9001h"
  ResetModeWin32Input   = "\e[?9001l"
  RequestModeWin32Input = "\e[?9001$p"
end
