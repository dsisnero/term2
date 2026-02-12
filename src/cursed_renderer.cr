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
    @starting : Bool = false
    @mu : Mutex = Mutex.new
    @buf : IO::Memory = IO::Memory.new

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
    @logger : Ultraviolet::Logger? = nil
    @term : String = ""
    @view : View = View.new

    def initialize(@output : IO = STDOUT, env : Array(String) = ENV.map { |k, v| "#{k}=#{v}" }.to_a, width : Int32 = 0, height : Int32 = 0)
      update_frame_duration
      @env = env
      @term = env.find { |e| e.starts_with?("TERM=") }.try(&.[5..]) || ""
      @width = width
      @height = height
      # Initialize cell buffers with dummy size (will resize on first render)
      @cell_buf = Ultraviolet::ScreenBuffer.new(0, 0)
      @scr = nil
    end

    def output=(io : IO) : Nil
      @mu.synchronize do
        @output = io
      end
    end

    def set_logger(logger : Ultraviolet::Logger) : Nil
      @mu.synchronize do
        @logger = logger
      end
    end

    def set_optimizations(hard_tabs : Bool, backspace : Bool, mapnl : Bool) : Nil
      @mu.synchronize do
        @hard_tabs = hard_tabs
        @backspace = backspace
        @mapnl = mapnl
        if scr = @scr
          scr.tab_stops = @width
          scr.backspace = backspace
          scr.map_newline = mapnl
        end
      end
    end

    def set_syncd_updates(syncd : Bool) : Nil
      @mu.synchronize do
        @syncd_updates = syncd
      end
    end

    def resize(width : Int32, height : Int32) : Nil
      @mu.synchronize do
        scr.erase
        @width = width
        @height = height
        scr.resize(width, height)
      end
    end

    def clear_screen : Nil
      @mu.synchronize do
        scr.move_to(0, 0)
        scr.erase
      end
    end

    def insert_above(str : String) : Nil
      @mu.synchronize do
        # TODO: implement insert_above
      end
    end

    def set_color_profile(profile : Lipgloss::ColorProfile) : Nil
      @mu.synchronize do
        @color_profile = profile
        if scr = @scr
          scr.color_profile = to_ultraviolet_profile(profile)
        end
      end
    end

    # Start the renderer
    def start : Nil
      @mu.synchronize do
        return if @running
        reset if @scr.nil?
        @running = true
        @last_render = ""
        @last_lines.clear
        @last_frame_time = Time::UNIX_EPOCH # Reset to allow immediate first render
        @current_bracketed_paste_disabled = nil
        @current_alt_screen = nil
        @cursor_visible = nil
        @clear_requested = false
        @starting = true
        _restore_state
      end
    end

    # Stop the renderer
    def stop : Nil
      @mu.synchronize do
        return unless @running
        @running = false
        _cleanup
        @current_alt_screen = nil
        @current_background = nil
        @current_foreground = nil
        @current_mouse_mode = MouseMode::None
        @current_keyboard_enhancements = KeyboardEnhancements.new
        @current_bracketed_paste_disabled = nil
        @cursor_visible = nil
        @last_view = nil
        @last_render = ""
        @last_lines.clear
      end
    end

    # Render a string view (legacy compatibility)
    def render(view : String) : Nil
      @mu.synchronize do
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
        _flush_buffer

        @last_render = view
      end
    end

    # Render a View struct (v2 API)
    def render_view(view : View) : Nil
      @mu.synchronize do
        render_standard(view, closing: false)
      end
    end

    # Request a clear on the next render
    def request_clear : Nil
      @mu.synchronize do
        @clear_requested = true
      end
    end

    # Flush any pending output
    def flush : Nil
      @mu.synchronize do
        scr.flush
        _flush_buffer
      end
    end

    private def _flush_buffer : Nil
      if @buf.bytesize > 0
        @output.write(@buf.to_slice)
        @buf.clear
      end
    end

    private def _cleanup : Nil
      # Reset colors
      apply_colors(nil, nil)

      # Reset cursor color and shape
      write_string("\e]112\a") # Reset cursor color (OSC 112)
      write_string("\e[0 q")   # Reset cursor style to default

      # Show cursor if hidden
      apply_cursor_visibility(true)

      # Disable mouse tracking
      _disable_mouse_tracking

      # Disable keyboard enhancements
      _disable_keyboard_enhancements

      # Disable bracketed paste mode
      apply_bracketed_paste(true)

      # Reset progress bar
      write_string("\e]9;4;0\a")

      # Clear window title
      write_string("\e]2;\a")

      # Flush cleanup sequences
      scr.flush
      _flush_buffer
    end

    private def _restore_state : Nil
      return unless view = @last_view

      # Restore alt screen state
      if view.alt_screen
        # Enter alt screen
        scr.save_cursor
        write_string("\e[?1049h")
        scr.fullscreen = true
        scr.relative_cursor = false
        scr.erase
        @current_alt_screen = true
      end

      # Restore cursor
      if cursor = view.cursor
        apply_cursor_shape(cursor.shape, cursor.blink, cursor.color)
        apply_cursor_visibility(true)
      else
        apply_cursor_visibility(false)
      end

      # Restore colors
      apply_colors(view.background_color, view.foreground_color)

      # Restore bracketed paste mode
      apply_bracketed_paste(view.disable_bracketed_paste_mode)

      # Restore mouse mode
      apply_mouse_mode(view.mouse_mode)

      # Restore keyboard enhancements
      apply_keyboard_enhancements(view.keyboard_enhancements)

      # Restore window title
      if title = view.window_title
        write_string("\e]2;#{title}\a")
      end

      # Restore progress bar
      if progress = view.progress_bar
        apply_progress_bar(progress)
      end

      # Flush restore sequences
      scr.flush
      _flush_buffer
    end

    # Check if the renderer is running
    def running? : Bool
      @mu.synchronize do
        @running
      end
    end

    # Repaint the screen
    def repaint : Nil
      @mu.synchronize do
        _repaint
      end
    end

    private def _repaint : Nil
      return unless @running
      @last_render = "" # Force re-render on next call
      @last_lines.clear
    end

    # Print text to the output, handling screen clearing/restoring if necessary
    def print(text : String) : Nil
      @mu.synchronize do
        return unless @running

        # Clear the screen (remove TUI)
        clear_screen

        # Print the text
        formatted_text = text.gsub("\n", "\r\n")
        write_string(formatted_text)
        scr.flush
        _flush_buffer

        # Force repaint on next render
        _repaint
      end
    end

    # Get the color profile
    def color_profile : Lipgloss::ColorProfile
      @mu.synchronize do
        @color_profile
      end
    end

    # Set the color profile
    def color_profile=(profile : Lipgloss::ColorProfile) : Nil
      @mu.synchronize do
        @color_profile = profile
        if scr = @scr
          scr.color_profile = to_ultraviolet_profile(profile)
        end
      end
    end

    # Set the frame rate (frames per second)
    def fps=(fps : Float64) : Nil
      @mu.synchronize do
        @fps = fps.clamp(1.0, 120.0)
        update_frame_duration
      end
    end

    # Get the current frame rate
    def fps : Float64
      @mu.synchronize do
        @fps
      end
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
      @scr.not_nil! # ameba:disable Lint/NotNil
    end

    private def write_string(str : String) : Nil
      scr.write_string(str)
    end

    # Compatibility no-op with Bubble Tea renderer API
    def reset_lines_rendered : Nil
      @mu.synchronize do
        # We don't track rendered lines; noop for compatibility.
      end
    end

    # TODO: Implement ultraviolet-style cell buffer diffing
    # ameba:disable Metrics/CyclomaticComplexity
    private def render_standard(view : View, closing : Bool = false) : Nil
      # Ensure terminal renderer is initialized
      reset if @scr.nil?
      scr = @scr.as(Ultraviolet::TerminalRenderer)
      @view = view

      # Update alt screen state (matches Go's shouldUpdateAltScreen logic)
      should_update_alt_screen = (@current_alt_screen.nil? && view.alt_screen) ||
                                 (@current_alt_screen != nil && @current_alt_screen != view.alt_screen)

      if should_update_alt_screen
        # Kitty keyboard reset when switching screens (deferred to flush)
        # write_string("\e[=0;1u")

        if view.alt_screen
          # Enter alt screen (state only, sequences deferred)
          scr.save_cursor
          # write_string("\e[?1049h")
          scr.fullscreen = true
          scr.relative_cursor = false
          scr.erase
        else
          # Exit alt screen (state only, sequences deferred)
          scr.erase
          scr.relative_cursor = true
          scr.fullscreen = false
          # write_string("\e[?1049l")
          scr.restore_cursor
        end
        @current_alt_screen = view.alt_screen
      end

      if view.cursor.nil?
        apply_cursor_visibility(false, write: false)
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

      # Compute frame area (matching Go's flush logic)
      frame_area = Ultraviolet.rect(0, 0, @width, @height)
      if view.content.empty?
        # If the component is nil, we should clear the screen buffer.
        frame_area = Ultraviolet.rect(0, 0, @width, 0)
      end

      content = Ultraviolet::StyledString.new(view.content)
      frame_height = frame_area.dy
      unless view.alt_screen
        # We need to resize the screen based on the frame height and
        # terminal width. This is because the frame height can change based on
        # the content of the frame. This is different from the alt screen buffer,
        # which has a fixed height and width.
        content_height = content.height
        if content_height != frame_height
          frame_height = content_height
          frame_area = Ultraviolet.rect(frame_area.min.x, frame_area.min.y, frame_area.dx, frame_height)
        end
      end

      # No-change optimization (matches Go)
      if !@starting && (last_view = @last_view) && view_equals(last_view, view) && frame_area == @cell_buf.bounds
        # No changes, nothing to do.
        return
      end

      # We're no longer starting.
      @starting = false

      if frame_area != @cell_buf.bounds
        scr.erase # Force a full redraw to avoid artifacts.
        # We need to reset the touched lines buffer to match the new height.
        @cell_buf.touched = Array(Ultraviolet::LineData?).new(frame_area.dy, nil)
        @cell_buf.resize(frame_area.dx, frame_area.dy)
      end

      # Clear our screen buffer before copying the new frame into it to ensure
      # we erase any old content.
      @cell_buf.clear
      content.draw(@cell_buf, @cell_buf.bounds)

      # If the frame height is greater than the screen height, we drop the
      # lines from the top of the buffer.
      if frame_height > @height
        n = frame_height - @height
        @cell_buf.lines.shift(n)
      end

      # Render cell buffer to terminal
      scr.render(@cell_buf)

      if cursor = view.cursor
        scr.move_to(cursor.position.x, cursor.position.y)
        apply_cursor_visibility(true, write: false)
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
      _flush_updates(closing)

      @last_render = view.content
      @last_view = view
    end

    # TODO: Implement ultraviolet cell buffer diffing
    private def view_equals(a : View, b : View) : Bool
      a.content == b.content &&
        a.alt_screen == b.alt_screen &&
        a.cursor == b.cursor &&
        a.background_color == b.background_color &&
        a.foreground_color == b.foreground_color &&
        a.window_title == b.window_title &&
        a.progress_bar == b.progress_bar &&
        a.disable_bracketed_paste_mode == b.disable_bracketed_paste_mode &&
        a.mouse_mode == b.mouse_mode &&
        a.keyboard_enhancements == b.keyboard_enhancements &&
        a.report_focus == b.report_focus
    end

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

    private def apply_cursor_visibility(show : Bool, write : Bool = true)
      return if @cursor_visible == show
      if write
        if show
          write_string("\e[?25h")
        else
          write_string("\e[?25l")
        end
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
        _disable_mouse_cell_motion
      when MouseMode::AllMotion
        _disable_mouse_all_motion
      when MouseMode::None
        # Already disabled, nothing to do
      end

      # Enable new tracking
      case mode
      when MouseMode::CellMotion
        _enable_mouse_cell_motion
      when MouseMode::AllMotion
        _enable_mouse_all_motion
      when MouseMode::None
        _disable_mouse_tracking
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
      @mu.synchronize do
        _enable_mouse_cell_motion
      end
    end

    private def _enable_mouse_cell_motion : Nil
      write_string("\e[?1002h\e[?1006h")
    end

    # Disable mouse cell motion tracking
    def disable_mouse_cell_motion : Nil
      @mu.synchronize do
        _disable_mouse_cell_motion
      end
    end

    private def _disable_mouse_cell_motion : Nil
      write_string("\e[?1002l\e[?1003l\e[?1006l")
    end

    # Enable mouse all motion tracking (including hover)
    def enable_mouse_all_motion : Nil
      @mu.synchronize do
        _enable_mouse_all_motion
      end
    end

    private def _enable_mouse_all_motion : Nil
      write_string("\e[?1003h\e[?1006h")
    end

    # Disable mouse all motion tracking
    def disable_mouse_all_motion : Nil
      @mu.synchronize do
        _disable_mouse_all_motion
      end
    end

    private def _disable_mouse_all_motion : Nil
      write_string("\e[?1003l")
    end

    # Disable all mouse tracking
    def disable_mouse_tracking : Nil
      @mu.synchronize do
        _disable_mouse_tracking
      end
    end

    private def _disable_mouse_tracking : Nil
      write_string("\e[?1002l\e[?1003l\e[?1006l")
    end

    # Enable keyboard enhancements (key repeat/release reporting)
    def enable_keyboard_enhancements : Nil
      @mu.synchronize do
        _enable_keyboard_enhancements
      end
    end

    private def _enable_keyboard_enhancements : Nil
      write_string("\e[?1001h")
    end

    # Disable keyboard enhancements
    def disable_keyboard_enhancements : Nil
      @mu.synchronize do
        _disable_keyboard_enhancements
      end
    end

    private def _disable_keyboard_enhancements : Nil
      write_string("\e[?1001l")
    end

    private def reset : Nil
      # Clear output buffer
      @buf.clear

      # Determine terminal dimensions
      if @width <= 0 || @height <= 0
        @width, @height = Terminal.size
      end

      # Create terminal renderer writing to buffer
      @scr = Ultraviolet::TerminalRenderer.new(@buf, @env)
      scr = @scr.as(Ultraviolet::TerminalRenderer)

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

    private def _flush_updates(closing : Bool) : Nil
      return if @buf.bytesize == 0

      has_updates = @buf.bytesize > 0
      did_show_cursor = @last_view.try(&.cursor) != nil
      show_cursor = @view.cursor != nil
      hide_cursor = !show_cursor
      last_alt_screen = @last_view.try(&.alt_screen)
      should_update_alt_screen = (@last_view.nil? && @view.alt_screen) ||
                                 (last_alt_screen != nil && last_alt_screen != @view.alt_screen)
      should_update_cursor_vis = (@last_view.nil? || did_show_cursor != show_cursor) || should_update_alt_screen

      # Build final output buffer (simplified - write directly to output)
      if should_update_alt_screen
        # We always disable keyboard enhancements when switching screens
        @output.write("\e[=0;1u".to_slice)
        if @view.alt_screen
          # Entering alt screen mode
          @output.write("\e[?1049h".to_slice)
        else
          # Exiting alt screen mode
          @output.write("\e[?1049l".to_slice)
        end
      end

      if @syncd_updates
        if has_updates
          @output.write(Ultraviolet::Ansi::SetModeSynchronizedOutput.to_slice)
        end
        if should_update_cursor_vis && hide_cursor
          @output.write("\e[?25l".to_slice)
        end
      elsif (should_update_cursor_vis && hide_cursor) || (has_updates && show_cursor && did_show_cursor)
        @output.write("\e[?25l".to_slice)
      end

      if has_updates
        @output.write(@buf.to_slice)
      end

      if @syncd_updates
        if should_update_cursor_vis && show_cursor
          @output.write("\e[?25h".to_slice)
        end
        if has_updates
          @output.write(Ultraviolet::Ansi::ResetModeSynchronizedOutput.to_slice)
        end
      elsif (should_update_cursor_vis && show_cursor) || (has_updates && show_cursor && did_show_cursor)
        @output.write("\e[?25h".to_slice)
      end

      @buf.clear
    end
  end
end
