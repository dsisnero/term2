module Ansi
  # Keyboard Action Mode (KAM) controls locking of the keyboard.
  #
  # Deprecated: use [ModeKeyboardAction] instead.
  KeyboardActionMode = ANSIMode.new(2)

  SetKeyboardActionMode     = "\e[2h"
  ResetKeyboardActionMode   = "\e[2l"
  RequestKeyboardActionMode = "\e[2$p"

  # Insert/Replace Mode (IRM) determines whether characters are inserted or replaced.
  #
  # Deprecated: use [ModeInsertReplace] instead.
  InsertReplaceMode = ANSIMode.new(4)

  SetInsertReplaceMode     = "\e[4h"
  ResetInsertReplaceMode   = "\e[4l"
  RequestInsertReplaceMode = "\e[4$p"

  # BiDirectional Support Mode (BDSM) determines whether the terminal supports bidirectional text.
  #
  # Deprecated: use [ModeBiDirectionalSupport] instead.
  BiDirectionalSupportMode = ANSIMode.new(8)

  SetBiDirectionalSupportMode     = "\e[8h"
  ResetBiDirectionalSupportMode   = "\e[8l"
  RequestBiDirectionalSupportMode = "\e[8$p"

  # Send Receive Mode (SRM) or Local Echo Mode determines whether the terminal echoes characters.
  #
  # Deprecated: use [ModeSendReceive] instead.
  SendReceiveMode = ANSIMode.new(12)
  LocalEchoMode   = SendReceiveMode

  SetSendReceiveMode     = "\e[12h"
  ResetSendReceiveMode   = "\e[12l"
  RequestSendReceiveMode = "\e[12$p"

  SetLocalEchoMode     = "\e[12h"
  ResetLocalEchoMode   = "\e[12l"
  RequestLocalEchoMode = "\e[12$p"

  # Line Feed/New Line Mode (LNM) determines whether the terminal interprets line feed as new line.
  #
  # Deprecated: use [ModeLineFeedNewLine] instead.
  LineFeedNewLineMode = ANSIMode.new(20)

  SetLineFeedNewLineMode     = "\e[20h"
  ResetLineFeedNewLineMode   = "\e[20l"
  RequestLineFeedNewLineMode = "\e[20$p"

  # Cursor Keys Mode (DECCKM) determines whether cursor keys send ANSI or application sequences.
  #
  # Deprecated: use [ModeCursorKeys] instead.
  CursorKeysMode = DECMode.new(1)

  SetCursorKeysMode     = "\e[?1h"
  ResetCursorKeysMode   = "\e[?1l"
  RequestCursorKeysMode = "\e[?1$p"

  # Cursor Keys mode.
  #
  # Deprecated: use [SetModeCursorKeys] and [ResetModeCursorKeys] instead.
  EnableCursorKeys  = "\e[?1h"
  DisableCursorKeys = "\e[?1l"

  # Origin Mode (DECOM) determines whether the cursor moves to home or margin position.
  #
  # Deprecated: use [ModeOrigin] instead.
  OriginMode = DECMode.new(6)

  SetOriginMode     = "\e[?6h"
  ResetOriginMode   = "\e[?6l"
  RequestOriginMode = "\e[?6$p"

  # Auto Wrap Mode (DECAWM) determines whether the cursor wraps to the next line.
  #
  # Deprecated: use [ModeAutoWrap] instead.
  AutoWrapMode = DECMode.new(7)

  SetAutoWrapMode     = "\e[?7h"
  ResetAutoWrapMode   = "\e[?7l"
  RequestAutoWrapMode = "\e[?7$p"

  # X10 Mouse Mode determines whether the mouse reports on button presses.
  #
  # Deprecated: use [ModeMouseX10] instead.
  X10MouseMode = DECMode.new(9)

  SetX10MouseMode     = "\e[?9h"
  ResetX10MouseMode   = "\e[?9l"
  RequestX10MouseMode = "\e[?9$p"

  # Text Cursor Enable Mode (DECTCEM) shows/hides the cursor.
  #
  # Deprecated: use [ModeTextCursorEnable] instead.
  TextCursorEnableMode = DECMode.new(25)

  SetTextCursorEnableMode     = "\e[?25h"
  ResetTextCursorEnableMode   = "\e[?25l"
  RequestTextCursorEnableMode = "\e[?25$p"

  # Text Cursor Enable mode.
  #
  # Deprecated: use [SetModeTextCursorEnable] and [ResetModeTextCursorEnable] instead.
  CursorEnableMode        = DECMode.new(25)
  RequestCursorVisibility = "\e[?25$p"

  # Numeric Keypad Mode (DECNKM) determines whether the keypad sends application or numeric sequences.
  #
  # Deprecated: use [ModeNumericKeypad] instead.
  NumericKeypadMode = DECMode.new(66)

  SetNumericKeypadMode     = "\e[?66h"
  ResetNumericKeypadMode   = "\e[?66l"
  RequestNumericKeypadMode = "\e[?66$p"

  # Backarrow Key Mode (DECBKM) determines whether the backspace key sends backspace or delete.
  #
  # Deprecated: use [ModeBackarrowKey] instead.
  BackarrowKeyMode = DECMode.new(67)

  SetBackarrowKeyMode     = "\e[?67h"
  ResetBackarrowKeyMode   = "\e[?67l"
  RequestBackarrowKeyMode = "\e[?67$p"

  # Left Right Margin Mode (DECLRMM) determines whether left and right margins can be set.
  #
  # Deprecated: use [ModeLeftRightMargin] instead.
  LeftRightMarginMode = DECMode.new(69)

  SetLeftRightMarginMode     = "\e[?69h"
  ResetLeftRightMarginMode   = "\e[?69l"
  RequestLeftRightMarginMode = "\e[?69$p"

  # Normal Mouse Mode determines whether the mouse reports on button presses and releases.
  #
  # Deprecated: use [ModeMouseNormal] instead.
  NormalMouseMode = DECMode.new(1000)

  SetNormalMouseMode     = "\e[?1000h"
  ResetNormalMouseMode   = "\e[?1000l"
  RequestNormalMouseMode = "\e[?1000$p"

  # VT Mouse Tracking mode.
  #
  # Deprecated: use [ModeMouseNormal] instead.
  MouseMode = DECMode.new(1000)

  EnableMouse  = "\e[?1000h"
  DisableMouse = "\e[?1000l"
  RequestMouse = "\e[?1000$p"

  # Highlight Mouse Tracking determines whether the mouse reports on button presses and highlighted cells.
  #
  # Deprecated: use [ModeMouseHighlight] instead.
  HighlightMouseMode = DECMode.new(1001)

  SetHighlightMouseMode     = "\e[?1001h"
  ResetHighlightMouseMode   = "\e[?1001l"
  RequestHighlightMouseMode = "\e[?1001$p"

  # VT Hilite Mouse Tracking mode.
  #
  # Deprecated: use [ModeMouseHighlight] instead.
  MouseHiliteMode = DECMode.new(1001)

  EnableMouseHilite  = "\e[?1001h"
  DisableMouseHilite = "\e[?1001l"
  RequestMouseHilite = "\e[?1001$p"

  # Button Event Mouse Tracking reports button-motion events when a button is pressed.
  #
  # Deprecated: use [ModeMouseButtonEvent] instead.
  ButtonEventMouseMode = DECMode.new(1002)

  SetButtonEventMouseMode     = "\e[?1002h"
  ResetButtonEventMouseMode   = "\e[?1002l"
  RequestButtonEventMouseMode = "\e[?1002$p"

  # Cell Motion Mouse Tracking mode.
  #
  # Deprecated: use [ModeMouseButtonEvent] instead.
  MouseCellMotionMode = DECMode.new(1002)

  EnableMouseCellMotion  = "\e[?1002h"
  DisableMouseCellMotion = "\e[?1002l"
  RequestMouseCellMotion = "\e[?1002$p"

  # Any Event Mouse Tracking reports all motion events.
  #
  # Deprecated: use [ModeMouseAnyEvent] instead.
  AnyEventMouseMode = DECMode.new(1003)

  SetAnyEventMouseMode     = "\e[?1003h"
  ResetAnyEventMouseMode   = "\e[?1003l"
  RequestAnyEventMouseMode = "\e[?1003$p"

  # All Mouse Tracking mode.
  #
  # Deprecated: use [ModeMouseAnyEvent] instead.
  MouseAllMotionMode = DECMode.new(1003)

  EnableMouseAllMotion  = "\e[?1003h"
  DisableMouseAllMotion = "\e[?1003l"
  RequestMouseAllMotion = "\e[?1003$p"

  # Focus Event Mode determines whether the terminal reports focus and blur events.
  #
  # Deprecated: use [ModeFocusEvent] instead.
  FocusEventMode = DECMode.new(1004)

  SetFocusEventMode     = "\e[?1004h"
  ResetFocusEventMode   = "\e[?1004l"
  RequestFocusEventMode = "\e[?1004$p"

  # Focus reporting mode.
  #
  # Deprecated: use [SetModeFocusEvent], [ResetModeFocusEvent], and
  # [RequestModeFocusEvent] instead.
  ReportFocusMode = DECMode.new(1004)

  EnableReportFocus  = "\e[?1004h"
  DisableReportFocus = "\e[?1004l"
  RequestReportFocus = "\e[?1004$p"

  # UTF-8 Extended Mouse Mode changes the mouse tracking encoding to use UTF-8 parameters.
  #
  # Deprecated: use [ModeMouseExtUtf8] instead.
  Utf8ExtMouseMode = DECMode.new(1005)

  SetUtf8ExtMouseMode     = "\e[?1005h"
  ResetUtf8ExtMouseMode   = "\e[?1005l"
  RequestUtf8ExtMouseMode = "\e[?1005$p"

  # SGR Extended Mouse Mode changes the mouse tracking encoding to use SGR parameters.
  #
  # Deprecated: use [ModeMouseExtSgr] instead.
  SgrExtMouseMode = DECMode.new(1006)

  SetSgrExtMouseMode     = "\e[?1006h"
  ResetSgrExtMouseMode   = "\e[?1006l"
  RequestSgrExtMouseMode = "\e[?1006$p"

  # Mouse SGR Extended mode.
  #
  # Deprecated: use [ModeMouseExtSgr], [SetModeMouseExtSgr],
  # [ResetModeMouseExtSgr], and [RequestModeMouseExtSgr] instead.
  MouseSgrExtMode    = DECMode.new(1006)
  EnableMouseSgrExt  = "\e[?1006h"
  DisableMouseSgrExt = "\e[?1006l"
  RequestMouseSgrExt = "\e[?1006$p"

  # URXVT Extended Mouse Mode changes the mouse tracking encoding to use an alternate encoding.
  #
  # Deprecated: use [ModeMouseUrxvtExt] instead.
  UrxvtExtMouseMode = DECMode.new(1015)

  SetUrxvtExtMouseMode     = "\e[?1015h"
  ResetUrxvtExtMouseMode   = "\e[?1015l"
  RequestUrxvtExtMouseMode = "\e[?1015$p"

  # SGR Pixel Extended Mouse Mode changes the mouse tracking encoding to use SGR parameters with pixel coordinates.
  #
  # Deprecated: use [ModeMouseExtSgrPixel] instead.
  SgrPixelExtMouseMode = DECMode.new(1016)

  SetSgrPixelExtMouseMode     = "\e[?1016h"
  ResetSgrPixelExtMouseMode   = "\e[?1016l"
  RequestSgrPixelExtMouseMode = "\e[?1016$p"

  # Alternate Screen Mode determines whether the alternate screen buffer is active.
  #
  # Deprecated: use [ModeAltScreen] instead.
  AltScreenMode = DECMode.new(1047)

  SetAltScreenMode     = "\e[?1047h"
  ResetAltScreenMode   = "\e[?1047l"
  RequestAltScreenMode = "\e[?1047$p"

  # Save Cursor Mode saves the cursor position.
  #
  # Deprecated: use [ModeSaveCursor] instead.
  SaveCursorMode = DECMode.new(1048)

  SetSaveCursorMode     = "\e[?1048h"
  ResetSaveCursorMode   = "\e[?1048l"
  RequestSaveCursorMode = "\e[?1048$p"

  # Alternate Screen Save Cursor Mode saves the cursor position and switches to alternate screen.
  #
  # Deprecated: use [ModeAltScreenSaveCursor] instead.
  AltScreenSaveCursorMode = DECMode.new(1049)

  SetAltScreenSaveCursorMode     = "\e[?1049h"
  ResetAltScreenSaveCursorMode   = "\e[?1049l"
  RequestAltScreenSaveCursorMode = "\e[?1049$p"

  # Alternate Screen Buffer mode.
  #
  # Deprecated: use [ModeAltScreenSaveCursor] instead.
  AltScreenBufferMode = DECMode.new(1049)

  SetAltScreenBufferMode     = "\e[?1049h"
  ResetAltScreenBufferMode   = "\e[?1049l"
  RequestAltScreenBufferMode = "\e[?1049$p"

  EnableAltScreenBuffer  = "\e[?1049h"
  DisableAltScreenBuffer = "\e[?1049l"
  RequestAltScreenBuffer = "\e[?1049$p"

  # Bracketed Paste Mode determines whether pasted text is bracketed with escape sequences.
  #
  # Deprecated: use [ModeBracketedPaste] instead.
  BracketedPasteMode = DECMode.new(2004)

  SetBracketedPasteMode     = "\e[?2004h"
  ResetBracketedPasteMode   = "\e[?2004l"
  RequestBracketedPasteMode = "\e[?2004$p"

  # Deprecated: use [SetModeBracketedPaste], [ResetModeBracketedPaste], and
  # [RequestModeBracketedPaste] instead.
  EnableBracketedPaste  = "\e[?2004h"
  DisableBracketedPaste = "\e[?2004l"
  RequestBracketedPaste = "\e[?2004$p"

  # Synchronized Output Mode determines whether output is synchronized with the terminal.
  #
  # Deprecated: use [ModeSynchronizedOutput] instead.
  SynchronizedOutputMode = DECMode.new(2026)

  SetSynchronizedOutputMode     = "\e[?2026h"
  ResetSynchronizedOutputMode   = "\e[?2026l"
  RequestSynchronizedOutputMode = "\e[?2026$p"

  # Synchronized output mode.
  #
  # Deprecated: use [ModeSynchronizedOutput], [SetModeSynchronizedOutput],
  # [ResetModeSynchronizedOutput], and [RequestModeSynchronizedOutput] instead.
  SyncdOutputMode = DECMode.new(2026)

  EnableSyncdOutput  = "\e[?2026h"
  DisableSyncdOutput = "\e[?2026l"
  RequestSyncdOutput = "\e[?2026$p"

  # Unicode Core Mode determines whether the terminal uses Unicode grapheme clustering.
  #
  # Deprecated: use [ModeUnicodeCore] instead.
  UnicodeCoreMode = DECMode.new(2027)

  SetUnicodeCoreMode     = "\e[?2027h"
  ResetUnicodeCoreMode   = "\e[?2027l"
  RequestUnicodeCoreMode = "\e[?2027$p"

  # Grapheme Clustering Mode determines whether the terminal looks for grapheme clusters.
  #
  # Deprecated: use [ModeUnicodeCore], [SetModeUnicodeCore],
  # [ResetModeUnicodeCore], and [RequestModeUnicodeCore] instead.
  GraphemeClusteringMode = DECMode.new(2027)

  SetGraphemeClusteringMode     = "\e[?2027h"
  ResetGraphemeClusteringMode   = "\e[?2027l"
  RequestGraphemeClusteringMode = "\e[?2027$p"

  # Unicode Core mode.
  #
  # Deprecated: use [SetModeUnicodeCore], [ResetModeUnicodeCore], and
  # [RequestModeUnicodeCore] instead.
  EnableGraphemeClustering  = "\e[?2027h"
  DisableGraphemeClustering = "\e[?2027l"
  RequestGraphemeClustering = "\e[?2027$p"

  # Light Dark Mode enables reporting the operating system's color scheme preference.
  #
  # Deprecated: use [ModeLightDark] instead.
  LightDarkMode = DECMode.new(2031)

  SetLightDarkMode     = "\e[?2031h"
  ResetLightDarkMode   = "\e[?2031l"
  RequestLightDarkMode = "\e[?2031$p"

  # In Band Resize Mode reports terminal resize events as escape sequences.
  #
  # Deprecated: use [ModeInBandResize] instead.
  InBandResizeMode = DECMode.new(2048)

  SetInBandResizeMode     = "\e[?2048h"
  ResetInBandResizeMode   = "\e[?2048l"
  RequestInBandResizeMode = "\e[?2048$p"

  # Win32Input determines whether input is processed by the Win32 console and Conpty.
  #
  # Deprecated: use [ModeWin32Input] instead.
  Win32InputMode = DECMode.new(9001)

  SetWin32InputMode     = "\e[?9001h"
  ResetWin32InputMode   = "\e[?9001l"
  RequestWin32InputMode = "\e[?9001$p"

  # Deprecated: use [SetModeWin32Input], [ResetModeWin32Input], and
  # [RequestModeWin32Input] instead.
  EnableWin32Input  = "\e[?9001h"
  DisableWin32Input = "\e[?9001l"
  RequestWin32Input = "\e[?9001$p"
end
