# Renderer interface and implementations for Term2
require "lipgloss"
require "./view"
require "./mouse"
require "./terminal"

module Term2
  # Renderer is the abstract base class for terminal rendering
  abstract class Renderer
    # Start the renderer
    abstract def start : Nil

    # Stop the renderer
    abstract def stop : Nil

    # Render a frame
    abstract def render(view : String) : Nil
    def render(view : View) : Nil
      render_view(view)
    end

    abstract def render_view(view : View) : Nil

    # Request a clear on the next render
    abstract def request_clear : Nil

    # Flush any pending output
    abstract def flush : Nil

    # Check if the renderer is running
    abstract def running? : Bool

    # Repaint the screen
    abstract def repaint : Nil

    # Set the frame rate (frames per second)
    abstract def fps=(fps : Float64) : Nil

    # Get the current frame rate
    abstract def fps : Float64

    # Print text to the output, handling screen clearing/restoring if necessary
    abstract def print(text : String) : Nil

    # Get the color profile
    abstract def color_profile : Lipgloss::ColorProfile

    # Set the color profile
    abstract def color_profile=(profile : Lipgloss::ColorProfile) : Nil
  end

  # StandardRenderer provides ANSI-based terminal rendering
  class StandardRenderer < Renderer
    @output : IO
    @running : Bool = false
    @last_render : String = ""
    @last_lines : Array(String) = [] of String
    @fps : Float64 = 60.0
    @last_frame_time : Time = Time::UNIX_EPOCH
    @frame_duration : Time::Span = Time::Span.new(nanoseconds: 16_666_667) # ~60 fps
    @current_mouse_mode : MouseMode = MouseMode::None
    @current_keyboard_enhancements : KeyboardEnhancements = KeyboardEnhancements.new
    @current_background : Lipgloss::Color? = nil
    @current_foreground : Lipgloss::Color? = nil
    @color_profile : Lipgloss::ColorProfile = Lipgloss::ColorProfile::TrueColor
    @current_bracketed_paste_disabled : Bool? = nil
    @current_alt_screen : Bool? = nil
    @last_view : View? = nil
    @cursor_visible : Bool? = nil
    @clear_requested : Bool = false

    def initialize(@output : IO = STDOUT)
      update_frame_duration
    end

    def output=(io : IO) : Nil
      @output = io
    end

    def start : Nil
      return if @running
      @running = true
      @last_render = ""
      @last_lines.clear
      @last_frame_time = Time::UNIX_EPOCH # Reset to allow immediate first render
      @current_bracketed_paste_disabled = nil
      @current_alt_screen = nil
      @last_view = nil
      @cursor_visible = nil
      @clear_requested = false
    end

    def stop : Nil
      return unless @running
      @running = false
      @current_alt_screen = nil
      @output.flush
    end

    def render(view : String) : Nil
      return unless @running

      # Rate limiting based on FPS
      now = Time.utc
      elapsed = now - @last_frame_time
      if elapsed < @frame_duration
        return
      end
      @last_frame_time = now

      # Only render if the view has changed
      return if view == @last_render

      @output.print("\r\e[J")
      @output.print(view)
      @output.flush

      @last_render = view
    end

    def render_view(view : View) : Nil
      if @current_alt_screen.nil?
        if view.alt_screen
          @output.print("\e[=0;1u")
          Terminal.enter_alt_screen(@output)
        end
        @current_alt_screen = view.alt_screen
      elsif @current_alt_screen != view.alt_screen
        @output.print("\e[=0;1u")
        if view.alt_screen
          Terminal.enter_alt_screen(@output)
        else
          Terminal.exit_alt_screen(@output)
        end
        @current_alt_screen = view.alt_screen
      end

      if view.cursor.nil?
        apply_cursor_visibility(false)
      end

      clear_requested = false
      if @clear_requested
        @output.print("\r")
        @clear_requested = false
        clear_requested = true
      end

      apply_bracketed_paste(view.disable_bracketed_paste_mode)
      apply_mouse_mode(view.mouse_mode)
      apply_keyboard_enhancements(view.keyboard_enhancements)
      apply_colors(view.background_color, view.foreground_color)

      if cursor = view.cursor
        apply_cursor_shape(cursor.shape, cursor.blink, cursor.color)
      end

      content_changed = view.content != @last_render
      if content_changed
        if view.alt_screen
          @output.print("\e[H\e[2J")
        else
          if clear_requested
            @output.print("\e[J")
          else
            @output.print("\r\e[J")
          end
        end
        @output.print(view.content)
        @output.flush
        @last_render = view.content
      end

      if view.cursor
        @output.print("\r")
        apply_cursor_visibility(true)
      end

      if title = view.window_title
        Terminal.set_window_title(@output, title)
      end

      if progress = view.progress_bar
        apply_progress_bar(progress)
      end

      @last_view = view
    end

    def request_clear : Nil
      @clear_requested = true
    end

    private def apply_colors(background : Lipgloss::Color?, foreground : Lipgloss::Color?)
      old_bg = @current_background
      old_fg = @current_foreground

      @current_background = background
      @current_foreground = foreground

      if background != old_bg
        if background
          @output.print("\e]11;#{color_hex(background)}\a")
        else
          @output.print("\e]111\a")
        end
      end

      if foreground != old_fg
        if foreground
          @output.print("\e]10;#{color_hex(foreground)}\a")
        else
          @output.print("\e]110\a")
        end
      end
    end

    private def apply_cursor_shape(shape : CursorShape, blink : Bool, color : Lipgloss::Color?)
      # DECSCUSR sequences for cursor shape
      code = case {shape, blink}
             when {CursorShape::Block, true}      then 1
             when {CursorShape::Block, false}     then 2
             when {CursorShape::Underline, true}  then 3
             when {CursorShape::Underline, false} then 4
             when {CursorShape::Bar, true}        then 5
             when {CursorShape::Bar, false}       then 6
             else                                      1 # default blinking block
             end
      @output.print("\e[#{code} q")

      # Cursor color via OSC 12 when explicitly set
      if color
        @output.print("\e]12;#{color_hex(color)}\a")
      end
    end

    private def apply_cursor_visibility(show : Bool)
      return if @cursor_visible == show
      if show
        Terminal.show_cursor(@output)
      else
        Terminal.hide_cursor(@output)
      end
      @cursor_visible = show
    end

    private def apply_bracketed_paste(disable : Bool)
      return if @current_bracketed_paste_disabled == disable
      if disable
        Terminal.disable_bracketed_paste(@output)
      else
        Terminal.enable_bracketed_paste(@output)
      end
      @current_bracketed_paste_disabled = disable
    end

    private def apply_mouse_mode(mode : MouseMode)
      return if mode == @current_mouse_mode

      # Disable current tracking
      case @current_mouse_mode
      when MouseMode::CellMotion
        disable_mouse_cell_motion
      when MouseMode::AllMotion
        disable_mouse_all_motion
      when MouseMode::None
        # Already disabled, nothing to do
      end

      # Enable new tracking
      case mode
      when MouseMode::CellMotion
        enable_mouse_cell_motion
      when MouseMode::AllMotion
        enable_mouse_all_motion
      when MouseMode::None
        disable_mouse_tracking
      end

      @current_mouse_mode = mode
    end

    private def apply_keyboard_enhancements(ke : KeyboardEnhancements)
      return if ke == @current_keyboard_enhancements && @last_view

      flags = 1
      flags |= 2 if ke.report_event_types
      @output.print("\e[=#{flags};1u")
      @current_keyboard_enhancements = ke
    end

    private def apply_progress_bar(progress : ProgressBar)
      case progress.state
      when ProgressBarState::None
        @output.print("\e]9;4;0\a")
      when ProgressBarState::Default
        @output.print("\e]9;4;1;#{progress.value}\a")
      when ProgressBarState::Error
        @output.print("\e]9;4;2;#{progress.value}\a")
      when ProgressBarState::Indeterminate
        @output.print("\e]9;4;3\a")
      when ProgressBarState::Warning
        @output.print("\e]9;4;4;#{progress.value}\a")
      end
      @output.flush
    end

    private def color_hex(color : Lipgloss::Color) : String
      r, g, b = color.to_rgb
      "##{r.to_s(16).rjust(2, '0')}#{g.to_s(16).rjust(2, '0')}#{b.to_s(16).rjust(2, '0')}"
    end

    def flush : Nil
      @output.flush
    end

    def running? : Bool
      @running
    end

    def repaint : Nil
      return unless @running
      @last_render = "" # Force re-render on next call
      @last_lines.clear
    end

    def print(text : String) : Nil
      return unless @running

      # Clear the screen (remove TUI)
      clear_screen

      # Print the text
      formatted_text = text.gsub("\n", "\r\n")
      @output.print(formatted_text)
      @output.flush

      # Force repaint on next render
      repaint
    end

    def fps=(fps : Float64) : Nil
      @fps = fps.clamp(1.0, 120.0)
      update_frame_duration
    end

    def fps : Float64
      @fps
    end

    def color_profile : Lipgloss::ColorProfile
      @color_profile
    end

    def color_profile=(profile : Lipgloss::ColorProfile) : Nil
      @color_profile = profile
    end

    private def update_frame_duration
      @frame_duration = Time::Span.new(nanoseconds: (1_000_000_000 / @fps).to_i64)
    end

    private def clear_screen
      # Move cursor to home position and clear from cursor to end of screen
      @output.print("\e[H\e[J")
    end

    # Compatibility no-op with Bubble Tea renderer API
    def reset_lines_rendered : Nil
      # We don't track rendered lines; noop for compatibility.
    end

    # Enable mouse cell motion tracking (clicks and drags)
    def enable_mouse_cell_motion : Nil
      @output.print("\e[?1002h\e[?1006h")
      @output.flush
    end

    # Disable mouse cell motion tracking
    def disable_mouse_cell_motion : Nil
      @output.print("\e[?1002l\e[?1003l\e[?1006l")
      @output.flush
    end

    # Enable mouse all motion tracking (including hover)
    def enable_mouse_all_motion : Nil
      @output.print("\e[?1003h\e[?1006h")
      @output.flush
    end

    # Disable mouse all motion tracking
    def disable_mouse_all_motion : Nil
      @output.print("\e[?1003l")
      @output.flush
    end

    # Disable all mouse tracking
    def disable_mouse_tracking : Nil
      @output.print("\e[?1002l\e[?1003l\e[?1006l")
      @output.flush
    end

    # Enable keyboard enhancements (key repeat/release reporting)
    def enable_keyboard_enhancements : Nil
      @output.print("\e[?1001h")
      @output.flush
    end

    # Disable keyboard enhancements
    def disable_keyboard_enhancements : Nil
      @output.print("\e[?1001l")
      @output.flush
    end
  end

  # NilRenderer is a no-op renderer for non-TUI mode
  class NilRenderer < Renderer
    @running : Bool = false
    @fps : Float64 = 60.0

    def start : Nil
      @running = true
    end

    def write(text : String) : Nil
      # No-op
    end

    def stop : Nil
      @running = false
    end

    def kill : Nil
      @running = false
    end

    def render(view : String) : Nil
      # No-op
    end

    def render_view(view : View) : Nil
      # No-op
    end

    def request_clear : Nil
      # No-op
    end

    def print(text : String) : Nil
      # No-op
    end

    def flush : Nil
      # No-op
    end

    def running? : Bool
      @running
    end

    def repaint : Nil
      # No-op
    end

    def fps=(fps : Float64) : Nil
      @fps = fps
    end

    def fps : Float64
      @fps
    end

    def color_profile : Lipgloss::ColorProfile
      Lipgloss::ColorProfile::TrueColor
    end

    def color_profile=(profile : Lipgloss::ColorProfile) : Nil
      # No-op
    end

    def reset_lines_rendered : Nil
      # No-op
    end

    def enter_alt_screen : Nil
      # No-op
    end

    def exit_alt_screen : Nil
      # No-op
    end

    def alt_screen? : Bool
      false
    end

    def clear_screen : Nil
      # No-op
    end

    def show_cursor : Nil
      # No-op
    end

    def hide_cursor : Nil
      # No-op
    end

    def enable_mouse_cell_motion : Nil
      # No-op
    end

    def disable_mouse_cell_motion : Nil
      # No-op
    end

    def enable_mouse_all_motion : Nil
      # No-op
    end

    def disable_mouse_all_motion : Nil
      # No-op
    end
  end

  # Lightweight renderer to satisfy lipgloss renderer API expectations.
  class LipglossRenderer < NilRenderer
    property has_dark_background : Bool = true
    @color_profile : Lipgloss::ColorProfile = Lipgloss::ColorProfile::TrueColor

    def color_profile : Lipgloss::ColorProfile
      @color_profile
    end

    def color_profile=(profile : Lipgloss::ColorProfile) : Nil
      @color_profile = profile
    end

    def has_dark_background? : Bool
      @has_dark_background
    end
  end

  def self.new_renderer(_io : IO, *_opts) : LipglossRenderer
    LipglossRenderer.new
  end
end
