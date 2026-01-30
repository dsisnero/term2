# Renderer interface and implementations for Term2
require "./color_profile"
require "./style"
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
    abstract def render(view : View) : Nil

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
    @current_background : Color? = nil
    @current_foreground : Color? = nil

    def initialize(@output : IO = STDOUT)
      update_frame_duration
    end

    def start : Nil
      return if @running
      @running = true
      @last_render = ""
      @last_lines.clear
      @last_frame_time = Time::UNIX_EPOCH # Reset to allow immediate first render
      Terminal.hide_cursor(@output)
    end

    def stop : Nil
      return unless @running
      @running = false
      Terminal.show_cursor(@output)
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

      # Bubble Tea parity: avoid full-screen clears when possible. Updating only
      # changed lines dramatically reduces output, which is crucial for large
      # views like the bubblezone full-lipgloss example.
      new_lines = view.split('\n', remove_empty: false)
      max_lines = {new_lines.size, @last_lines.size}.max

      (0...max_lines).each do |i|
        prev = @last_lines[i]?
        curr = new_lines[i]?
        next if prev == curr

        Terminal.move_to(i + 1, 1, @output)
        # Reset attributes before writing a line. Unlike full-screen rendering,
        # line-diff updates are non-linear, so terminal SGR state must not leak
        # from whatever was last written.
        @output.print("\e[0m")
        apply_current_colors
        if curr
          @output.print(curr)
        end
        Terminal.clear_line(@output)
      end

      # If the new view has fewer lines, clear the remaining old lines.
      if new_lines.size < @last_lines.size
        (new_lines.size...@last_lines.size).each do |i|
          Terminal.move_to(i + 1, 1, @output)
          @output.print("\e[0m")
          apply_current_colors
          Terminal.clear_entire_line(@output)
        end
      end

      @output.flush

      @last_render = view
      @last_lines = new_lines
    end

    def render(view : View) : Nil
      # Apply background/foreground colors if set
      apply_colors(view.background_color, view.foreground_color)

      # Render content (this will also handle line diff updates)
      render(view.content)

      # Set cursor position if provided
      if cursor = view.cursor
        Terminal.move_to(cursor.position.y + 1, cursor.position.x + 1, @output)
        # Set cursor shape and blink
        apply_cursor_shape(cursor.shape, cursor.blink, cursor.color)
      end

      # Set window title if provided
      if title = view.window_title
        Terminal.set_window_title(@output, title)
      end

      # Handle mouse mode
      apply_mouse_mode(view.mouse_mode)

      # Handle keyboard enhancements
      apply_keyboard_enhancements(view.keyboard_enhancements)

      # Handle progress bar if provided
      if progress = view.progress_bar
        apply_progress_bar(progress)
      end

      # Reset colors after rendering? Colors persist, but we reset at start of each render
      # via apply_colors (which resets if nil). The content render resets attributes per line.
    end

    private def apply_colors(background : Color?, foreground : Color?)
      # Store old colors for comparison
      old_bg = @current_background
      old_fg = @current_foreground

      # Update stored colors
      @current_background = background
      @current_foreground = foreground

      # Handle background change
      if background != old_bg
        if background
          codes = background.background_codes
          @output.print("\e[#{codes.join(";")}m") unless codes.empty?
        else
          # Reset to default background
          @output.print("\e[49m")
        end
      end

      # Handle foreground change
      if foreground != old_fg
        if foreground
          codes = foreground.foreground_codes
          @output.print("\e[#{codes.join(";")}m") unless codes.empty?
        else
          # Reset to default foreground
          @output.print("\e[39m")
        end
      end
    end

    private def apply_current_colors
      # Apply stored background and foreground colors
      if bg = @current_background
        codes = bg.background_codes
        @output.print("\e[#{codes.join(";")}m") unless codes.empty?
      end
      if fg = @current_foreground
        codes = fg.foreground_codes
        @output.print("\e[#{codes.join(";")}m") unless codes.empty?
      end
    end

    private def apply_cursor_shape(shape : CursorShape, blink : Bool, color : Color?)
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

      # Cursor color via OSC 12 (not widely supported)
      if color
        codes = color.foreground_codes
        unless codes.empty?
          # OSC 12 ; rgb:RR/GG/BB ST
          r, g, b = color.to_rgb
          @output.print("\e]12;rgb:#{r.to_s(16).rjust(2, '0')}/#{g.to_s(16).rjust(2, '0')}/#{b.to_s(16).rjust(2, '0')}\e\\")
        end
      end
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
      return if ke == @current_keyboard_enhancements

      # Handle report_event_types flag
      if ke.report_event_types != @current_keyboard_enhancements.report_event_types
        if ke.report_event_types
          enable_keyboard_enhancements
        else
          disable_keyboard_enhancements
        end
      end

      @current_keyboard_enhancements = ke
    end

    private def apply_progress_bar(progress : ProgressBar)
      # TODO: implement progress bar display
      # OSC 9 ; 0 ; <percent> ST ?
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

    def render(view : View) : Nil
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
    property color_profile : ColorProfile = ColorProfile::TrueColor

    def has_dark_background? : Bool
      @has_dark_background
    end
  end

  def self.new_renderer(_io : IO, *_opts) : LipglossRenderer
    LipglossRenderer.new
  end
end
