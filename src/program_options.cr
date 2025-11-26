# Program options and configuration system
module Term2
  # Base type for program configuration options.
  #
  # Program options are applied when creating a `Program` to configure
  # terminal behavior, input/output handling, and UI features.
  #
  # ```crystal
  # options = Term2::ProgramOptions.new(
  #   Term2::WithAltScreen.new,
  #   Term2::WithMouseAllMotion.new,
  #   Term2::WithReportFocus.new
  # )
  # program = Term2::Program.new(app, options)
  # ```
  abstract struct ProgramOption
    # Apply this option to a program instance.
    abstract def apply(program : Program) : Nil
  end

  # Enables alternate screen buffer mode.
  #
  # When enabled, the terminal switches to an alternate screen that
  # doesn't affect the main scrollback buffer. The original screen
  # is restored when the program exits.
  struct WithAltScreen < ProgramOption
    def apply(program : Program) : Nil
      program.enable_alt_screen
    end
  end

  # Disables the renderer for non-TUI applications.
  #
  # Use this when you need the event loop but don't want terminal
  # UI rendering (e.g., for headless processing).
  struct WithoutRenderer < ProgramOption
    def apply(program : Program) : Nil
      program.disable_renderer
    end
  end

  # Disables automatic panic (exception) recovery.
  #
  # By default, Term2 catches exceptions and attempts to restore
  # terminal state before re-raising. Use this to disable that behavior.
  struct WithoutCatchPanics < ProgramOption
    def apply(program : Program) : Nil
      program.disable_panic_recovery
    end
  end

  # Disables signal handling (SIGINT, SIGTERM, etc.).
  struct WithoutSignalHandler < ProgramOption
    def apply(program : Program) : Nil
      program.disable_signal_handling
    end
  end

  # Configures a custom input source.
  #
  # ```crystal
  # # Use a string as input for testing
  # input = IO::Memory.new("test input\n")
  # options = Term2::ProgramOptions.new(Term2::WithInput.new(input))
  # ```
  struct WithInput < ProgramOption
    def initialize(@input : IO); end

    def apply(program : Program) : Nil
      program.input = @input
    end
  end

  # Configures a custom output destination.
  #
  # ```crystal
  # # Capture output for testing
  # output = IO::Memory.new
  # options = Term2::ProgramOptions.new(Term2::WithOutput.new(output))
  # ```
  struct WithOutput < ProgramOption
    def initialize(@output : IO); end

    def apply(program : Program) : Nil
      program.output = @output
    end
  end

  # Forces TTY input mode even when stdin is not a TTY.
  struct WithInputTTY < ProgramOption
    def apply(program : Program) : Nil
      program.force_input_tty
    end
  end

  # Configures environment variables for the program.
  struct WithEnvironment < ProgramOption
    def initialize(@env : Hash(String, String)); end

    def apply(program : Program) : Nil
      program.environment = @env
    end
  end

  # Configures the frame rate for rendering.
  #
  # ```crystal
  # # Set to 30 FPS
  # Term2::WithFPS.new(30.0)
  # ```
  struct WithFPS < ProgramOption
    def initialize(@fps : Float64); end

    def apply(program : Program) : Nil
      program.fps = @fps
    end
  end

  # Configures a message filter function.
  #
  # The filter receives each message before it reaches update()
  # and can transform or replace it.
  struct WithFilter < ProgramOption
    def initialize(@filter : Message -> Message); end

    def apply(program : Program) : Nil
      program.filter = @filter
    end
  end

  # Enables terminal focus reporting.
  #
  # When enabled, `FocusIn` and `FocusOut` key events are sent
  # when the terminal window gains or loses focus.
  struct WithReportFocus < ProgramOption
    def apply(program : Program) : Nil
      program.enable_focus_reporting
    end
  end

  # Disables bracketed paste mode.
  #
  # Bracketed paste allows distinguishing pasted text from typed
  # input. When disabled, pasted text appears as regular keystrokes.
  struct WithoutBracketedPaste < ProgramOption
    def apply(program : Program) : Nil
      program.disable_bracketed_paste
    end
  end

  # Enables cell-based mouse motion tracking.
  #
  # Reports mouse movement when a button is held and the mouse
  # moves to a new cell (character position).
  struct WithMouseCellMotion < ProgramOption
    def apply(program : Program) : Nil
      program.enable_mouse_cell_motion
    end
  end

  # Enables all mouse motion tracking (hover events).
  #
  # Reports all mouse movement, including when no button is pressed.
  # This enables hover detection but generates many events.
  struct WithMouseAllMotion < ProgramOption
    def apply(program : Program) : Nil
      program.enable_mouse_all_motion
    end
  end

  # Container for multiple program options.
  #
  # ```crystal
  # options = Term2::ProgramOptions.new(
  #   Term2::WithAltScreen.new,
  #   Term2::WithMouseAllMotion.new
  # )
  #
  # # Or build incrementally
  # options = Term2::ProgramOptions.new
  # options.add(Term2::WithAltScreen.new)
  # options.add(Term2::WithFPS.new(30.0))
  # ```
  class ProgramOptions
    @options : Array(ProgramOption) = [] of ProgramOption

    def initialize
    end

    def initialize(*options : ProgramOption)
      @options = options.to_a
    end

    # Add an option to the collection.
    def add(option : ProgramOption) : self
      @options << option
      self
    end

    # Apply all options to a program instance.
    def apply(program : Program) : Nil
      @options.each do |option|
        option.apply(program)
      end
    end

    # Check if an option of a specific type is present.
    def has_option?(option_type : ProgramOption.class) : Bool
      @options.any? { |opt| opt.class == option_type }
    end

    # Get all options of a specific type.
    def get_options(option_type : ProgramOption.class) : Array(ProgramOption)
      @options.select { |opt| opt.class == option_type }
    end
  end
end
