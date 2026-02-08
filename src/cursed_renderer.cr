# CursedRenderer provides ultraviolet-compatible terminal rendering
# for Bubble Tea v2 API compatibility.
require "lipgloss"
require "uniwidth"
require "./view"
require "./mouse"
require "./terminal"
require "./renderer"
require "../lib/ultraviolet/src/ultraviolet"

module Term2
  class CursedRenderer < Renderer
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

    # Ultraviolet cell buffer for efficient diffing
    @cell_buf : Ultraviolet::ScreenBuffer

    # Terminal renderer and buffer
    @scr : Ultraviolet::TerminalRenderer?
    @env : Array(String)
    @width : Int32
    @height : Int32
    @hard_tabs : Bool = false
    @backspace : Bool = false
    @mapnl : Bool = false
    @syncd_updates : Bool = false

    def initialize(@output : IO = STDOUT, env : Array(String) = ENV.map { |k, v| "#{k}=#{v}" }.to_a, width : Int32 = 0, height : Int32 = 0)
      update_frame_duration
      @env = env
      @width = width
      @height = height
      # Initialize cell buffers with dummy size (will resize on first render)
      @cell_buf = Ultraviolet::ScreenBuffer.new(0, 0)
      @scr = nil
    end

    def output=(io : IO) : Nil
      @output = io
    end

    # Start the renderer
    def start : Nil
      return if @running
      reset if @scr.nil?
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

    # Stop the renderer
    def stop : Nil
      return unless @running
      @running = false
      @current_alt_screen = nil
      scr.flush
    end

    # Render a string view (legacy compatibility)
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

      write_string("\r\e[J")
      write_string(view)
      scr.flush

      @last_render = view
    end

    # Render a View struct (v2 API)
    def render_view(view : View) : Nil
      render_standard(view)
    end

    # Request a clear on the next render
    def request_clear : Nil
      @clear_requested = true
    end

    # Flush any pending output
    def flush : Nil
      scr.flush
    end

    # Check if the renderer is running
    def running? : Bool
      @running
    end

    # Repaint the screen
    def repaint : Nil
      return unless @running
      @last_render = "" # Force re-render on next call
      @last_lines.clear
    end

    # Print text to the output, handling screen clearing/restoring if necessary
    def print(text : String) : Nil
      return unless @running

      # Clear the screen (remove TUI)
      clear_screen

      # Print the text
      formatted_text = text.gsub("\n", "\r\n")
      write_string(formatted_text)
      scr.flush

      # Force repaint on next render
      repaint
    end

    # Get the color profile
    def color_profile : Lipgloss::ColorProfile
      @color_profile
    end

    # Set the color profile
    def color_profile=(profile : Lipgloss::ColorProfile) : Nil
      @color_profile = profile
      if scr = @scr
        scr.color_profile = to_ultraviolet_profile(profile)
      end
    end

    # Set the frame rate (frames per second)
    def fps=(fps : Float64) : Nil
      @fps = fps.clamp(1.0, 120.0)
      update_frame_duration
    end

    # Get the current frame rate
    def fps : Float64
      @fps
    end

    # Private helper methods

    private def update_frame_duration
      @frame_duration = Time::Span.new(nanoseconds: (1_000_000_000 / @fps).to_i64)
    end

    private def clear_screen
      # Move cursor to home position and clear from cursor to end of screen
      write_string("\e[H\e[J")
    end

    private def scr : Ultraviolet::TerminalRenderer
      @scr.not_nil!
    end

    private def write_string(str : String) : Nil
      scr.write_string(str)
    end

    # Compatibility no-op with Bubble Tea renderer API
    def reset_lines_rendered : Nil
      # We don't track rendered lines; noop for compatibility.
    end

    # TODO: Implement ultraviolet-style cell buffer diffing
    private def render_standard(view : View) : Nil
      # Ensure terminal renderer is initialized
      reset if @scr.nil?
      scr = @scr.not_nil!

      # Update alt screen state (matches Go's shouldUpdateAltScreen logic)
      should_update_alt_screen = (@current_alt_screen.nil? && view.alt_screen) ||
                                 (@current_alt_screen != nil && @current_alt_screen != view.alt_screen)

      if should_update_alt_screen
        # Kitty keyboard reset when switching screens
        write_string("\e[=0;1u")

        if view.alt_screen
          # Enter alt screen
          scr.save_cursor
          write_string("\e[?1049h")
          scr.fullscreen = true
          scr.relative_cursor = false
          scr.erase
        else
          # Exit alt screen
          scr.erase
          scr.relative_cursor = true
          scr.fullscreen = false
          write_string("\e[?1049l")
          scr.restore_cursor
        end
        @current_alt_screen = view.alt_screen
      end

      if view.cursor.nil?
        apply_cursor_visibility(false)
      end

      if @clear_requested
        scr.erase
        scr.move_to(0, 0)
        @clear_requested = false
      end

      apply_bracketed_paste(view.disable_bracketed_paste_mode)
      apply_mouse_mode(view.mouse_mode)
      apply_keyboard_enhancements(view.keyboard_enhancements)
      apply_colors(view.background_color, view.foreground_color)

      if cursor = view.cursor
        apply_cursor_shape(cursor.shape, cursor.blink, cursor.color)
      end

      scr = @scr.not_nil!

      # Create styled string and compute frame dimensions (matching Go's flush logic)
      content = Ultraviolet::StyledString.new(view.content)
      frame_area = @cell_buf.bounds
      unless view.alt_screen
        # In inline mode, resize based on content height
        frame_height = content.height
        if frame_height != frame_area.dy
          frame_area = Ultraviolet.rect(frame_area.min.x, frame_area.min.y, frame_area.dx, frame_height)
        end
      end

      # Resize cell buffer if dimensions changed
      if frame_area != @cell_buf.bounds
        scr.erase # Force full redraw to avoid artifacts
        # We need to reset touched lines buffer to match new height
        # @cell_buf.touched = nil if @cell_buf.responds_to?(:touched)
        @cell_buf.resize(frame_area.dx, frame_area.dy)
      end

      # Clear screen buffer before drawing new content
      @cell_buf.clear
      content.draw(@cell_buf, @cell_buf.bounds)

      # Render cell buffer to terminal
      scr.render(@cell_buf)

      if cursor = view.cursor
        scr.move_to(cursor.position.x, cursor.position.y)
        apply_cursor_visibility(true)
      else
        # Move cursor out of the way in inline mode
        unless view.alt_screen
          x, y = scr.position
          if x >= @width - 1
            scr.move_to(0, y)
          end
        end
      end

      if title = view.window_title
        write_string("\e]2;#{title}\a")
      end

      if progress = view.progress_bar
        apply_progress_bar(progress)
      end

      scr.flush

      @last_render = view.content
      @last_view = view
    end

    # TODO: Implement ultraviolet cell buffer diffing
    private def apply_colors(background : Lipgloss::Color?, foreground : Lipgloss::Color?)
      old_bg = @current_background
      old_fg = @current_foreground

      @current_background = background
      @current_foreground = foreground

      if background != old_bg
        if background
          write_string("\e]11;#{color_hex(background)}\a")
        else
          write_string("\e]111\a")
        end
      end

      if foreground != old_fg
        if foreground
          write_string("\e]10;#{color_hex(foreground)}\a")
        else
          write_string("\e]110\a")
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
      write_string("\e[#{code} q")

      # Cursor color via OSC 12 when explicitly set
      if color
        write_string("\e]12;#{color_hex(color)}\a")
      end
    end

    private def apply_cursor_visibility(show : Bool)
      return if @cursor_visible == show
      if show
        write_string("\e[?25h")
      else
        write_string("\e[?25l")
      end
      @cursor_visible = show
    end

    private def apply_bracketed_paste(disable : Bool)
      return if @current_bracketed_paste_disabled == disable
      if disable
        write_string("\e[?2004l")
      else
        write_string("\e[?2004h")
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
      write_string("\e[=#{flags};1u")
      @current_keyboard_enhancements = ke
    end

    private def apply_progress_bar(progress : ProgressBar)
      case progress.state
      when ProgressBarState::None
        write_string("\e]9;4;0\a")
      when ProgressBarState::Default
        write_string("\e]9;4;1;#{progress.value}\a")
      when ProgressBarState::Error
        write_string("\e]9;4;2;#{progress.value}\a")
      when ProgressBarState::Indeterminate
        write_string("\e]9;4;3\a")
      when ProgressBarState::Warning
        write_string("\e]9;4;4;#{progress.value}\a")
      end
    end

    private def color_hex(color : Lipgloss::Color) : String
      r, g, b = color.to_rgb
      "##{r.to_s(16).rjust(2, '0')}#{g.to_s(16).rjust(2, '0')}#{b.to_s(16).rjust(2, '0')}"
    end

    # Enable mouse cell motion tracking (clicks and drags)
    def enable_mouse_cell_motion : Nil
      write_string("\e[?1002h\e[?1006h")
    end

    # Disable mouse cell motion tracking
    def disable_mouse_cell_motion : Nil
      write_string("\e[?1002l\e[?1003l\e[?1006l")
    end

    # Enable mouse all motion tracking (including hover)
    def enable_mouse_all_motion : Nil
      write_string("\e[?1003h\e[?1006h")
    end

    # Disable mouse all motion tracking
    def disable_mouse_all_motion : Nil
      write_string("\e[?1003l")
    end

    # Disable all mouse tracking
    def disable_mouse_tracking : Nil
      write_string("\e[?1002l\e[?1003l\e[?1006l")
    end

    # Enable keyboard enhancements (key repeat/release reporting)
    def enable_keyboard_enhancements : Nil
      write_string("\e[?1001h")
    end

    # Disable keyboard enhancements
    def disable_keyboard_enhancements : Nil
      write_string("\e[?1001l")
    end

    private def reset : Nil
      # Determine terminal dimensions
      if @width <= 0 || @height <= 0
        @width, @height = Terminal.size
      end

      # Create terminal renderer
      @scr = Ultraviolet::TerminalRenderer.new(@output, @env)
      scr = @scr.not_nil!

      # Set color profile
      scr.color_profile = to_ultraviolet_profile(@color_profile)

      # Set flags
      scr.relative_cursor = true # Always start in inline mode
      scr.fullscreen = false     # Always start in inline mode
      scr.scroll_optim = !(@env.includes?("TERM2_WINDOWS") || @env.includes?("WT_SESSION"))
      scr.map_newline = @mapnl
      scr.backspace = @backspace
      scr.tab_stops = @width

      # Resize cell buffer
      @cell_buf = Ultraviolet::ScreenBuffer.new(@width, @height)
    end

    private def to_ultraviolet_profile(profile : Lipgloss::ColorProfile) : Ultraviolet::ColorProfile
      case profile
      when Lipgloss::ColorProfile::TrueColor
        Ultraviolet::ColorProfile::TrueColor
      when Lipgloss::ColorProfile::ANSI256
        Ultraviolet::ColorProfile::ANSI256
      when Lipgloss::ColorProfile::ANSI
        Ultraviolet::ColorProfile::ANSI
      when Lipgloss::ColorProfile::ASCII
        Ultraviolet::ColorProfile::Ascii
      else
        Ultraviolet::ColorProfile::TrueColor
      end
    end
  end
end
