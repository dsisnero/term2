# Renderer interface and implementations for Term2
module Term2
  # Renderer is the abstract base class for terminal rendering
  abstract class Renderer
    # Start the renderer
    abstract def start : Nil

    # Stop the renderer
    abstract def stop : Nil

    # Render a frame
    abstract def render(view : String) : Nil

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
    @fps : Float64 = 60.0
    @last_frame_time : Time = Time::UNIX_EPOCH
    @frame_duration : Time::Span = Time::Span.new(nanoseconds: 16_666_667) # ~60 fps

    def initialize(@output : IO = STDOUT)
      update_frame_duration
    end

    def start : Nil
      return if @running
      @running = true
      @last_render = ""
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

      # Clear and render the new view
      clear_screen
      @output.print(view)
      @output.flush

      @last_render = view
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
    end

    def print(text : String) : Nil
      return unless @running

      # Clear the screen (remove TUI)
      clear_screen

      # Print the text
      @output.print(text)
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
  end

  # NilRenderer is a no-op renderer for non-TUI mode
  class NilRenderer < Renderer
    @running : Bool = false
    @fps : Float64 = 60.0

    def start : Nil
      @running = true
    end

    def stop : Nil
      @running = false
    end

    def render(view : String) : Nil
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
  end
end
