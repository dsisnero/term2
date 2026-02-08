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
    @cell_buf : Ultraviolet::Buffer
    @previous_cell_buf : Ultraviolet::Buffer?
    @last_content : String = ""
    @cell_width : Int32 = 0
    @cell_height : Int32 = 0

    def initialize(@output : IO = STDOUT)
      update_frame_duration
      # Initialize cell buffers with dummy size (will resize on first render)
      @cell_buf = Ultraviolet::Buffer.new(0, 0)
      @previous_cell_buf = nil
    end

    def output=(io : IO) : Nil
      @output = io
    end

    # Start the renderer
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

    # Stop the renderer
    def stop : Nil
      return unless @running
      @running = false
      @current_alt_screen = nil
      @output.flush
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

      @output.print("\r\e[J")
      @output.print(view)
      @output.flush

      @last_render = view
    end

    # Render a View struct (v2 API)
    def render_view(view : View) : Nil
      # TODO: Implement ultraviolet-style cell buffer diffing
      # For now, delegate to StandardRenderer logic
      update_cell_buffer(view)
      render_standard(view)
    end

    # Request a clear on the next render
    def request_clear : Nil
      @clear_requested = true
    end

    # Flush any pending output
    def flush : Nil
      @output.flush
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
      @output.print(formatted_text)
      @output.flush

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
      @output.print("\e[H\e[J")
    end

    # Compatibility no-op with Bubble Tea renderer API
    def reset_lines_rendered : Nil
      # We don't track rendered lines; noop for compatibility.
    end

    # TODO: Implement ultraviolet-style cell buffer diffing
    private def render_standard(view : View) : Nil
      # Temporary implementation using StandardRenderer logic
      # This will be replaced with ultraviolet cell buffer diffing
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

        # Render ultraviolet cell buffer
        render_full_buffer
        @output.flush
        @last_render = view.content
      end

      if cursor = view.cursor
        # Position cursor at cursor location
        move_cursor_to(cursor.position.x, cursor.position.y)
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

    # TODO: Implement ultraviolet cell buffer diffing
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

    # Update the ultraviolet cell buffer with the view's content
    private def update_cell_buffer(view : View) : Nil
      return if view.content == @last_content
      @last_content = view.content

      # Parse content into cells
      cells, width, height = parse_content_to_cells(view.content)

      # Resize buffer if dimensions changed
      if width != @cell_width || height != @cell_height
        @cell_width = width
        @cell_height = height
        @cell_buf = Ultraviolet::Buffer.new(width, height)
      end

      # Fill buffer with cells
      cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          @cell_buf.set_cell(x, y, cell)
        end
      end
    end

    # Render full cell buffer to output with cursor positioning
    private def render_full_buffer : Nil
      buffer = @cell_buf
      return if buffer.width == 0 || buffer.height == 0

      cur_style = Ultraviolet::Style.new
      cur_link = Ultraviolet::Link.new

      buffer.height.times do |y|
        buffer.width.times do |x|
          cell = buffer.cell_at(x, y)

          # Move cursor to cell position
          move_cursor_to(x, y)

          # Output cell
          cur_style, cur_link = output_cell(cell, cur_style, cur_link)
        end
      end

      # Reset style and link at end
      if !cur_style.zero?
        @output.print("\e[0m")
      end
      if !cur_link.empty?
        @output.print(cur_link.end_sequence)
      end

      # Update previous buffer for future diffing
      @previous_cell_buf = buffer.clone
    end

    # Check if two cells are different
    private def cell_changed?(prev_cell : Ultraviolet::Cell?, curr_cell : Ultraviolet::Cell?) : Bool
      # Both nil -> no change
      return false if prev_cell.nil? && curr_cell.nil?

      # One nil, other not -> change
      return true if prev_cell.nil? != curr_cell.nil?

      # Now both are not nil, compare fields
      prev = prev_cell.not_nil!
      curr = curr_cell.not_nil!

      return true if prev.content != curr.content
      return true if prev.width != curr.width
      return true if prev.style != curr.style
      return true if prev.link != curr.link

      false
    end

    # Move cursor to position (0,0 is top-left)
    private def move_cursor_to(x : Int32, y : Int32) : Nil
      # Use 1-based indexing for ANSI
      @output.print("\e[#{y + 1};#{x + 1}H")
    end

    # Output a cell with proper styling, returns updated style and link
    private def output_cell(cell : Ultraviolet::Cell?, cur_style : Ultraviolet::Style, cur_link : Ultraviolet::Link) : {Ultraviolet::Style, Ultraviolet::Link}
      if cell.nil? || (cell.content == " " && cell.width == 1 && cell.style.zero? && cell.link.empty?)
        # Empty cell
        @output.print(" ")
        return {cur_style, cur_link}
      end

      new_style = cur_style
      new_link = cur_link

      # Apply style changes if needed
      if cell.style != cur_style
        if cell.style.zero?
          @output.print("\e[0m")
          new_style = Ultraviolet::Style.new
        else
          @output.print(cell.style.string)
          new_style = cell.style
        end
      end

      # Apply link changes if needed
      if cell.link != cur_link
        if !cur_link.empty?
          @output.print(cur_link.end_sequence)
        end
        if !cell.link.empty?
          @output.print(cell.link.start_sequence)
        end
        new_link = cell.link
      end

      # Output cell content
      @output.print(cell.content)

      {new_style, new_link}
    end

    # Parse ANSI-escaped content into a 2D array of cells
    private def parse_content_to_cells(content : String) : {Array(Array(Ultraviolet::Cell?)), Int32, Int32}
      bytes = content.to_slice
      i = 0
      x = 0
      y = 0
      rows = [] of Array(Ultraviolet::Cell?)
      current_row = [] of Ultraviolet::Cell?
      current_style = Ultraviolet::Style.new

      while i < bytes.size
        b = bytes[i]

        # Handle escape sequences
        if b == 0x1b_u8 && i + 1 < bytes.size
          i = consume_escape_sequence(bytes, i)
          next
        end

        # Handle newline
        if b == '\n'.ord.to_u8
          rows << current_row
          current_row = [] of Ultraviolet::Cell?
          x = 0
          y += 1
          i += 1
          next
        end

        # Handle carriage return (ignore for positioning)
        if b == '\r'.ord.to_u8
          i += 1
          next
        end

        # Decode UTF-8 grapheme
        cp, len = decode_utf8(bytes, i)
        grapheme = String.new(bytes[i, len])
        width = UnicodeCharWidth.width(cp)

        # Create cell
        cell = Ultraviolet::Cell.new(grapheme, width, current_style)
        current_row << cell
        x += width

        i += len
      end

      # Add last row if not empty
      rows << current_row unless current_row.empty?

      # Determine max width
      max_width = rows.max_of?(&.size) || 0
      height = rows.size

      # Pad rows to uniform width
      rows.each do |row|
        while row.size < max_width
          row << nil
        end
      end

      {rows, max_width, height}
    end

    # Consume an ANSI escape sequence, returning new index
    private def consume_escape_sequence(bytes : Bytes, i : Int32) : Int32
      return i + 1 if i + 1 >= bytes.size
      second = bytes[i + 1]

      # CSI: ESC [ ... final-byte(@-~)
      if second == '['.ord.to_u8
        j = i + 2
        while j < bytes.size
          final = bytes[j]
          j += 1
          break if final >= 0x40_u8 && final <= 0x7E_u8
        end
        return j
      end

      # OSC: ESC ] ... BEL or ST(ESC \)
      if second == ']'.ord.to_u8
        j = i + 2
        while j < bytes.size
          b = bytes[j]
          j += 1
          break if b == 0x07_u8
          if b == 0x1b_u8 && j < bytes.size && bytes[j] == '\\'.ord.to_u8
            j += 1
            break
          end
        end
        return j
      end

      # Other single-char escape sequence
      i + 2
    end

    # Decode UTF-8 codepoint, returns codepoint and byte length
    private def decode_utf8(bytes : Bytes, i : Int32) : {Int32, Int32}
      first = bytes[i].to_i32
      if first < 0x80
        return {first, 1}
      elsif first < 0xC2
        # Invalid continuation, treat as replacement character
        return {0xFFFD, 1}
      elsif first < 0xE0
        return {(first & 0x1F) << 6 | (bytes[i + 1] & 0x3F), 2} if i + 1 < bytes.size
        return {0xFFFD, 1}
      elsif first < 0xF0
        if i + 2 < bytes.size
          cp = (first & 0x0F) << 12 | (bytes[i + 1] & 0x3F) << 6 | (bytes[i + 2] & 0x3F)
          return {cp, 3}
        end
        return {0xFFFD, 1}
      elsif first < 0xF8
        if i + 3 < bytes.size
          cp = (first & 0x07) << 18 | (bytes[i + 1] & 0x3F) << 12 | (bytes[i + 2] & 0x3F) << 6 | (bytes[i + 3] & 0x3F)
          return {cp, 4}
        end
        return {0xFFFD, 1}
      else
        return {0xFFFD, 1}
      end
    end
  end
end
