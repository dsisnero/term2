# View struct and related types for Term2 v2 API compatibility
# Mirrors Bubble Tea v2 View struct and associated types

require "./style"

module Term2
  # MouseMode represents the mouse mode of a view.
  enum MouseMode
    # MouseModeNone disables mouse events.
    None

    # MouseModeCellMotion enables mouse click, release, and wheel events.
    # Mouse movement events are also captured if a mouse button is pressed
    # (i.e., drag events). Cell motion mode is better supported than all
    # motion mode.
    #
    # This will try to enable the mouse in extended mode (SGR), if that is not
    # supported by the terminal it will fall back to normal mode (X10).
    CellMotion

    # MouseModeAllMotion enables all mouse events, including click, release,
    # wheel, and movement events. You will receive mouse movement events even
    # when no buttons are pressed.
    #
    # This will try to enable the mouse in extended mode (SGR), if that is not
    # supported by the terminal it will fall back to normal mode (X10).
    AllMotion
  end

  # CursorShape represents a terminal cursor shape.
  enum CursorShape
    Block
    Underline
    Bar
  end

  # Point represents a position in the terminal (x, y coordinates).
  struct Point
    property x : Int32
    property y : Int32

    def initialize(@x : Int32, @y : Int32)
    end
  end

  # Cursor represents the cursor position, style, and visibility.
  struct Cursor
    # Position determines the cursor's position on the screen relative to
    # the top left corner of the frame.
    property position : Point

    # Color determines the cursor's color.
    property color : Color?

    # Shape determines the cursor's shape.
    property shape : CursorShape = CursorShape::Block

    # Blink determines whether the cursor should blink.
    property blink : Bool = true

    def initialize(x : Int32, y : Int32)
      @position = Point.new(x, y)
      @color = nil
      @shape = CursorShape::Block
      @blink = true
    end

    def initialize(@position : Point, @color : Color? = nil, @shape : CursorShape = CursorShape::Block, @blink : Bool = true)
    end
  end

  # KeyboardEnhancements describes the requested keyboard enhancement features.
  # If the terminal supports any of them, it will respond with a
  # KeyboardEnhancementsMsg that indicates which features are supported.
  struct KeyboardEnhancements
    # ReportEventTypes requests the terminal to report key repeat and release
    # events.
    # If supported, your program will receive KeyReleaseMsgs and
    # KeyPressMsgs with the Key.IsRepeat field set indicating that this is
    # part of a key repeat sequence.
    property report_event_types : Bool = false

    def initialize(@report_event_types = false)
    end
  end

  # ProgressBar represents a terminal progress bar (placeholder for future implementation).
  struct ProgressBar
    # TODO: Implement progress bar fields
    property value : Float64 = 0.0
    property max : Float64 = 100.0

    def initialize(@value = 0.0, @max = 100.0)
    end
  end

  # View represents a terminal view that can be composed of multiple layers.
  # It can also contain a cursor that will be rendered on top of the layers.
  struct View
    # Content is the screen content of the view. It holds styled strings that
    # will be rendered to the terminal when the view is rendered.
    #
    # A styled string represents text with styles and hyperlinks encoded as
    # ANSI escape codes.
    property content : String

    # Cursor represents the cursor position, style, and visibility on the
    # screen. When not nil, the cursor will be shown at the specified
    # position.
    property cursor : Cursor?

    # BackgroundColor when not nil, sets the terminal background color. Use
    # nil to reset to the terminal's default background color.
    property background_color : Color?

    # ForegroundColor when not nil, sets the terminal foreground color. Use
    # nil to reset to the terminal's default foreground color.
    property foreground_color : Color?

    # WindowTitle sets the terminal window title. Support depends on the
    # terminal.
    property window_title : String?

    # ProgressBar when not nil, shows a progress bar in the terminal's
    # progress bar section. Support depends on the terminal.
    property progress_bar : ProgressBar?

    # AltScreen puts the program in the alternate screen buffer
    # (i.e. the program goes into full window mode). Note that the altscreen will
    # be automatically exited when the program quits.
    property alt_screen : Bool = false

    # ReportFocus enables reporting when the terminal gains and loses focus.
    # When this is enabled FocusMsg and BlurMsg messages will be sent to
    # your Update method.
    #
    # Note that while most terminals and multiplexers support focus reporting,
    # some do not. Also note that tmux needs to be configured to report focus
    # events.
    property report_focus : Bool = false

    # DisableBracketedPasteMode disables bracketed paste mode for this view.
    property disable_bracketed_paste_mode : Bool = false

    # MouseMode sets the mouse mode for this view.
    property mouse_mode : MouseMode = MouseMode::None

    # KeyboardEnhancements describes what keyboard enhancement features Bubble
    # Tea should request from the terminal.
    property keyboard_enhancements : KeyboardEnhancements = KeyboardEnhancements.new

    # OnMouse is an optional mouse message handler that can be used to
    # intercept mouse messages that depends on view content from last render.
    # It can be useful for implementing view-specific behavior without
    # breaking the unidirectional data flow of Bubble Tea.
    #
    # TODO: Implement proper Proc type for mouse handling
    # property on_mouse : Proc(MouseMsg, Cmd)?

    def initialize(
      @content : String = "",
      @cursor : Cursor? = nil,
      @background_color : Color? = nil,
      @foreground_color : Color? = nil,
      @window_title : String? = nil,
      @progress_bar : ProgressBar? = nil,
      @alt_screen : Bool = false,
      @report_focus : Bool = false,
      @disable_bracketed_paste_mode : Bool = false,
      @mouse_mode : MouseMode = MouseMode::None,
      @keyboard_enhancements : KeyboardEnhancements = KeyboardEnhancements.new,
    )
    end
  end

  # Helper function to create a new View with the given styled string.
  # A styled string represents text with styles and hyperlinks encoded
  # as ANSI escape codes.
  #
  # Example:
  # ```
  # v = Term2.new_view("Hello, World!")
  # ```
  def self.new_view(content : String) : View
    View.new(content: content)
  end
end
