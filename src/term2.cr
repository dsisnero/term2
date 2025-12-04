require "cml"
require "cml/mailbox"
require "set"
require "./base_types"
require "./exec"
require "./zone"
require "./terminal"
require "./program_options"
require "./key_sequences"
require "./mouse"
require "./style"
require "./renderer"
require "./components/*"

{% if flag?(:unix) %}
  lib LibC
    fun kill(pid : Int32, sig : Int32) : Int32
  end
{% end %}

# Term2 is a Crystal port of the Bubble Tea terminal UI library.
#
# It provides a reactive, Elm-inspired architecture for building
# terminal user interfaces using a Model-Update-View pattern.
#
# ## Quick Start
#
# ```
# require "term2"
#
# class MyModel < Term2::Model
#   getter count : Int32 = 0
#
#   def initialize(@count = 0); end
#
#   def init : Term2::Cmd
#     Term2::Cmd.none
#   end
#
#   def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd}
#     case msg
#     when Term2::KeyMsg
#       case msg.key.to_s
#       when "q" then {self, Term2::Cmd.quit}
#       when "+" then {MyModel.new(@count + 1), Term2::Cmd.none}
#       else          {self, Term2::Cmd.none}
#       end
#     else
#       {self, Term2::Cmd.none}
#     end
#   end
#
#   def view : String
#     "Count: #{@count}\nPress + to increment, q to quit"
#   end
# end
#
# Term2.run(MyModel.new)
# ```
#
# ## Architecture
#
# Term2 follows the Elm architecture:
# - **Model**: Your application state (must inherit from `Term2::Model`)
# - **Update**: A function that takes a message and returns a new model and command
# - **View**: A function that renders the model to a string
#
# ## Key Features
#
# - Keyboard and mouse input handling
# - Alternate screen support
# - Focus reporting
# - Window resize events
# - Bracketed paste mode
# - Command system for async operations
# - Rate-limited rendering
module Term2
  VERSION = "0.1.0"

  # Messages have been moved to base_types.cr

  # KeyReader handles reading and parsing key sequences from input
  class KeyReader
    @buffer : String = ""
    @mouse_reader : MouseReader = MouseReader.new
    @in_paste : Bool = false
    @paste_buffer : String = ""
    @last_mouse_event : MouseEvent? = nil

    getter last_mouse_event : MouseEvent?

    # Bracketed paste escape sequences
    PASTE_START = "\e[200~"
    PASTE_END   = "\e[201~"

    def read_key(io : IO) : Key?
      # Reset any previous mouse event; set again only when a full event is parsed.
      @last_mouse_event = nil
      char = nil
      timeout = false

      begin
        # Try to read a character
        if @buffer.empty?
          char = io.read_char
          raise IO::EOFError.new unless char
        else
          # Buffer has data, try to read more with timeout
          if io.responds_to?(:read_timeout=) && io.is_a?(IO::FileDescriptor)
            old_timeout = io.read_timeout
            begin
              io.read_timeout = 0.05.seconds
              char = io.read_char
              raise IO::EOFError.new unless char
            rescue IO::TimeoutError
              timeout = true
            ensure
              io.read_timeout = old_timeout
            end
          else
            # For non-FileDescriptor IOs (like IO::Memory in tests), we can't easily timeout.
            # But if we are in a test with IO::Memory, we might be able to peek?
            # Or just assume if it blocks it blocks.
            # However, for the focus test, we put all data in upfront.
            # If we are here, it means we have some buffer (e.g. "\e") and we want to see if there is more.
            # If the IO is empty, read_char will raise EOF or block.
            # In tests with IO::Memory, it raises EOF if empty.
            begin
              char = io.read_char
              raise IO::EOFError.new unless char
            rescue IO::EOFError
              timeout = true
            end
          end
        end
      rescue IO::EOFError
        if !@buffer.empty?
          return resolve_current_buffer
        else
          raise IO::EOFError.new
        end
      end

      if timeout
        if mouse_sequence_prefix?(@buffer)
          return nil
        end
        return resolve_current_buffer
      end

      # If we're in paste mode, collect until we hit the end sequence
      if @in_paste
        @paste_buffer += char.to_s
        if @paste_buffer.ends_with?(PASTE_END)
          # Remove the paste end sequence from the content
          pasted_content = @paste_buffer[0...-PASTE_END.size]
          @in_paste = false
          @paste_buffer = ""
          @buffer = ""
          # Return a key with the pasted content and paste flag set
          return Key.new(pasted_content.chars, alt: false, paste: true)
        end
        return nil
      end

      # Add to buffer
      @buffer += char.to_s

      # Check for paste start sequence
      if @buffer.ends_with?(PASTE_START)
        @in_paste = true
        @paste_buffer = ""
        @buffer = ""
        return nil
      end

      # Check if we might be in a paste start sequence (partial match)
      if PASTE_START.starts_with?(@buffer) && @buffer.size < PASTE_START.size
        return nil # Need more characters
      end

      # Check for mouse events first
      if @buffer.starts_with?("\e[")
        mouse_event = @mouse_reader.check_mouse_event(@buffer)
        if mouse_event
          @buffer = ""
          @last_mouse_event = mouse_event
          # Return a dummy key to signal we have something
          return Key.new(KeyType::Null)
        end
        # If this looks like a mouse prefix but isn't complete yet, keep buffering.
        if mouse_sequence_prefix?(@buffer)
          return nil
        end
        # If no mouse event was found, continue to check for key sequences
      end

      # Clear last mouse event since we're not returning a mouse event
      @last_mouse_event = nil

      # Check for escape sequences
      if @buffer.starts_with?("\e")
        # Check if we have a complete sequence
        exact_match = KeySequences.find(@buffer)
        is_prefix = KeySequences.prefix?(@buffer)

        # STDERR.puts "Buffer: #{@buffer.inspect} Match: #{exact_match.inspect} Prefix: #{is_prefix}"

        if exact_match && !is_prefix
          # Exact match and not a prefix of anything else
          @buffer = ""
          return exact_match
        elsif is_prefix
          # It's a prefix (and maybe a match too), need more data
          return nil
        end

        # Neither a match nor a prefix, so it's an unknown/invalid sequence
        resolve_current_buffer
      else
        # Single character
        key = parse_single_char(@buffer)
        @buffer = ""
        key
      end
    rescue InvalidByteSequenceError
      # Return replacement character for invalid UTF-8
      Key.new('\uFFFD')
    end

    private def mouse_sequence_prefix?(buffer : String) : Bool
      buffer.starts_with?("\e[<") || buffer.starts_with?("\e[M")
    end

    private def resolve_current_buffer : Key
      # Check if the current buffer is a valid sequence
      # This handles cases where a sequence is a prefix of another (e.g. \e[O vs \e[OA)
      # but we timed out or hit EOF, so we should accept the shorter sequence.
      if key = KeySequences.find(@buffer)
        @buffer = ""
        return key
      end

      # If we have a complete escape sequence but no match, treat as alt+key
      if @buffer.size > 1 && @buffer[1] != '['
        key_char = @buffer[1]
        @buffer = ""
        return Key.new(key_char, alt: true)
      end

      # Unknown escape sequence, clear buffer
      @buffer = ""
      Key.new(KeyType::Esc)
    end

    private def parse_single_char(str : String) : Key?
      return nil if str.empty?

      char = str[0]
      case char.ord
      when 0
        Key.new(KeyType::Null)
      when 1..26
        Key.new(KeyType.new(char.ord))
      when 27
        Key.new(KeyType::Esc)
      when 127
        Key.new(KeyType::Backspace)
      when 9
        Key.new(KeyType::Tab)
      when 13
        Key.new(KeyType::Enter)
      when 32
        Key.new(KeyType::Space)
      else
        if char.control?
          Key.new(KeyType.new(char.ord))
        else
          Key.new(char)
        end
      end
    end
  end

  # MouseEvent is now defined in mouse.cr

  # Dispatcher bridges commands to the program's message mailbox.
  # Dispatcher and Cmd have been moved to base_types.cr

  # Run the program with the given model.
  def self.run(model : M, input : IO? = STDIN, output : IO = STDOUT, options : ProgramOptions = ProgramOptions.new) forall M
    Program(M).new(model, input, output, options).run
  end

  # Helper to create a quit command
  def self.quit : Cmd
    Cmds.quit
  end

  # Helper to batch multiple commands
  def self.batch(*cmds : Cmd) : Cmd
    Cmds.batch(*cmds)
  end

  # Program manages the event loop using CML primitives.
  class Program(M)
    getter dispatcher : Dispatcher
    getter! model
    getter output_io : IO
    getter input_io : IO?
    getter startup_options : Set(Symbol)
    getter input_type : Symbol
    getter context : ProgramContext?
    @model : M
    @pending_shutdown : Bool
    @options : ProgramOptions
    @alt_screen_enabled : Bool
    @renderer_enabled : Bool
    @panic_recovery_enabled : Bool
    @signal_handling_enabled : Bool
    @focus_reporting_enabled : Bool
    @bracketed_paste_enabled : Bool
    @mouse_cell_motion_enabled : Bool
    @mouse_all_motion_enabled : Bool
    @filter : Proc(Msg?, Msg?)?
    @renderer : Renderer
    @killed : Atomic(Bool)
    @external_context : ProgramContext?

    # Allow options to override the renderer
    def renderer=(renderer : Renderer)
      @renderer = renderer
    end

    def renderer : Renderer
      @renderer
    end

    def renderer_enabled? : Bool
      @renderer_enabled
    end

    def signal_handling_enabled? : Bool
      @signal_handling_enabled
    end

    def filter_present? : Bool
      !!@filter
    end

    def input_tty? : Bool
      @input_io.is_a?(IO::FileDescriptor)
    end

    def bracketed_paste_enabled? : Bool
      @bracketed_paste_enabled
    end

    def mouse_cell_motion_enabled? : Bool
      @mouse_cell_motion_enabled
    end

    def mouse_all_motion_enabled? : Bool
      @mouse_all_motion_enabled
    end

    def context : ProgramContext?
      @external_context
    end

    # For testing/internal parity: process a message immediately (bypassing mailbox loop).
    def process_message(msg : Message) : Nil
      handle_message(msg)
    end

    alias RenderOp = String | PrintMsg

    def initialize(@model : M, input : IO? = STDIN, output : IO = STDOUT, options : ProgramOptions = ProgramOptions.new)
      @input_io = input
      @output_io = output
      @startup_options = Set(Symbol).new
      @input_type = input_type_for(input)
      @mailbox = CML::Mailbox(Msg).new
      @render_mailbox = CML::Mailbox(RenderOp).new
      @done = CML::IVar(Nil).new
      @dispatcher = Dispatcher.new(@mailbox)
      @running = Atomic(Bool).new(false)
      @input_running = Atomic(Bool).new(false)
      @pending_shutdown = false
      @options = options
      @alt_screen_enabled = false
      @renderer_enabled = true
      @panic_recovery_enabled = true
      @signal_handling_enabled = true
      @focus_reporting_enabled = false
      @bracketed_paste_enabled = false
      @mouse_cell_motion_enabled = false
      @mouse_all_motion_enabled = false
      @filter = nil
      @renderer = StandardRenderer.new(@output_io)
      @killed = Atomic(Bool).new(false)
      @external_context = nil
      @options.apply(self)
    end

    def run : M
      # Run inside raw mode if we have an input IO that supports it
      if io = @input_io
        case io
        when IO::FileDescriptor
          # Log.debug { "Entering raw mode on #{io}" }
          begin
            io.raw do
              run_internal
            end
          rescue IO::Error
            # If raw mode is not supported (e.g., non-TTY/pipe), fall back
            run_internal
          end
        else
          run_internal
        end
      else
        run_internal
      end
      raise ProgramKilled.new("program killed") if @killed.get
      @model
    end

    def model : M
      @model
    end

    def start : Nil
      spawn { run }
    end

    def wait : Nil
      CML.sync(@done.read_evt)
      raise ProgramKilled.new("program killed") if @killed.get
    end

    def kill : Nil
      @killed.set(true)
      stop
    end

    def quit : Nil
      dispatch(QuitMsg.new)
    end

    private def run_internal
      if @panic_recovery_enabled
        begin
          bootstrap
          listen_loop
        rescue ex
          # Ensure terminal is restored even on crash
          cleanup
          @killed.set(true)
          raise ProgramPanic.new(ex.message)
        end
      else
        bootstrap
        listen_loop
      end
    ensure
      cleanup
    end

    def send(msg : Message) : Nil
      @dispatcher.dispatch(msg.as(Msg))
    end

    # Backwards-compatible alias.
    def dispatch(msg : Message) : Nil
      send(msg)
    end

    def stop : Nil
      return unless @running.compare_and_set(true, false)
      @dispatcher.stop
      @done.fill(nil)
    end

    # Option methods
    def enable_alt_screen : Nil
      @alt_screen_enabled = true
      @startup_options << :alt_screen
    end

    def disable_renderer : Nil
      @renderer_enabled = false
    end

    def disable_panic_recovery : Nil
      @panic_recovery_enabled = false
      @startup_options << :without_catch_panics
    end

    def disable_signal_handling : Nil
      @signal_handling_enabled = false
      @startup_options << :without_signal_handler
    end

    def output=(output : IO) : Nil
      @output_io = output
    end

    def input=(input : IO) : Nil
      @input_io = input
      @input_type = input_type_for(input)
    end

    def force_input_tty : Nil
      @input_type = :tty
      @input_io = File.open("/dev/tty")
    rescue
      # Ignore if /dev/tty is not available
    end

    def environment=(env : Hash(String, String)) : Nil
      # TODO: Implement environment setting
    end

    def fps=(fps : Float64) : Nil
      # TODO: Implement FPS setting
    end

    def filter=(filter : Proc(Msg?, Msg?)) : Nil
      @filter = filter
    end

    def enable_focus_reporting : Nil
      @focus_reporting_enabled = true
    end

    def context=(context : ProgramContext) : Nil
      @external_context = context
    end

    def disable_bracketed_paste : Nil
      @bracketed_paste_enabled = false
      @startup_options << :without_bracketed_paste
    end

    def enable_mouse_cell_motion : Nil
      @mouse_cell_motion_enabled = true
      @mouse_all_motion_enabled = false
      @startup_options.delete(:mouse_all_motion)
      @startup_options << :mouse_cell_motion
      Mouse.enable_tracking(@output_io)
    end

    def enable_mouse_all_motion : Nil
      @mouse_all_motion_enabled = true
      @mouse_cell_motion_enabled = false
      @startup_options.delete(:mouse_cell_motion)
      @startup_options << :mouse_all_motion
      Mouse.enable_move_reporting(@output_io)
    end

    def enable_ansi_compressor : Nil
      @startup_options << :ansi_compressor
    end

    private def input_type_for(io : IO?) : Symbol
      return :none unless io
      io.is_a?(IO::FileDescriptor) ? :tty : :custom
    end

    def disable_mouse_tracking : Nil
      @mouse_cell_motion_enabled = false
      @mouse_all_motion_enabled = false
      Mouse.disable_tracking(@output_io)
    end

    private def bootstrap
      @running.set(true)
      # Provide an initial window size message (parity with Bubble Tea)
      width, height = Terminal.size
      dispatch(WindowSizeMsg.new(width, height))
      start_context_watcher
      if @renderer_enabled
        @renderer.start
      end
      setup_terminal
      setup_signal_handlers
      start_input_reader
      init_cmd = @model.init
      schedule_render
      run_cmd(init_cmd)
    end

    private def setup_terminal
      if @alt_screen_enabled
        Terminal.enter_alt_screen(@output_io)
      end

      if @focus_reporting_enabled
        Terminal.enable_focus_reporting(@output_io)
      end

      unless @bracketed_paste_enabled
        Terminal.disable_bracketed_paste(@output_io)
      end

      # Configure mouse modes
      if @mouse_cell_motion_enabled
        Mouse.enable_tracking(@output_io)
      elsif @mouse_all_motion_enabled
        Mouse.enable_move_reporting(@output_io)
      end

      Terminal.hide_cursor(@output_io)
      Terminal.clear(@output_io)
    end

    private def start_input_reader
      return unless io = @input_io
      return if @input_running.get
      @input_running.set(true)
      spawn(name: "term2-input") { read_input(io) }
    end

    private def read_input(io : IO)
      key_reader = KeyReader.new

      while running? && @input_running.get
        begin
          # Read a key (KeyReader handles mouse events internally via check_mouse_event)
          result = key_reader.read_key(io)
          next unless result # Continue if nil (partial sequence)

          # Check if KeyReader detected a mouse event
          if mouse_event = key_reader.last_mouse_event
            # First dispatch raw mouse event
            dispatch(mouse_event)

            # Then check if it hit a zone and dispatch zone click
            if zone_click = Zone.handle_mouse(mouse_event)
              # Auto-focus clicked zone on press
              if mouse_event.action == MouseEvent::Action::Press
                Zone.focus(zone_click.id)
              end
              dispatch(zone_click)
            end
            next
          end

          key = result

          if key.type == KeyType::FocusIn
            dispatch(FocusMsg.new)
          elsif key.type == KeyType::FocusOut
            dispatch(BlurMsg.new)
          elsif key.type == KeyType::Tab
            # Tab key cycles focus through zones
            if next_id = Zone.focus_next
              dispatch(ZoneFocusMsg.new(next_id))
            end
            dispatch(KeyMsg.new(key))
          elsif key.type == KeyType::ShiftTab
            # Shift+Tab cycles focus backwards
            if prev_id = Zone.focus_prev
              dispatch(ZoneFocusMsg.new(prev_id))
            end
            dispatch(KeyMsg.new(key))
          else
            dispatch(KeyMsg.new(key))
            # Also dispatch legacy KeyPress for backward compatibility
            dispatch(KeyPress.new(key.to_s))
          end
        rescue IO::EOFError
          break
        end
      end
      @input_running.set(false)
    end

    private def start_context_watcher
      return unless ctx = @external_context
      spawn(name: "term2-context-watch") do
        ctx.wait
        @killed.set(true)
        dispatch(InterruptMsg.new)
      end
    end

    private def running? : Bool
      @running.get
    end

    private def listen_loop
      loop do
        drain_render_queue
        event = CML.sync(next_event)
        case event
        when InputEvent
          handle_message(event.message)
        when DoneEvent
          drain_render_queue
          break
        end
      end
    end

    private abstract class LoopEvent
    end

    private class InputEvent < LoopEvent
      getter message : Msg

      def initialize(@message : Msg); end
    end

    private class DoneEvent < LoopEvent
    end

    private def next_event : CML::Event(LoopEvent)
      events = [] of CML::Event(LoopEvent)
      input_evt = CML.wrap(@mailbox.recv_evt) { |msg| InputEvent.new(msg).as(LoopEvent) }
      events << CML.nack(input_evt) { }
      events << CML.wrap(@done.read_evt) { DoneEvent.new.as(LoopEvent) }
      CML.choose(events)
    end

    private def handle_message(msg : Message)
      STDERR.puts "handle #{msg.class}" if ENV["TERM2_DEBUG"]?

      # Apply message filter if configured
      filtered_msg = if filter = @filter
                       filter.call(msg.as(Msg))
                     else
                       msg.as(Msg)
                     end
      return unless filtered_msg

      # Handle internal terminal messages
      case filtered_msg
      when BatchMsg
        filtered_msg.cmds.each { |cmd| run_cmd(cmd) }
        return
      when SequenceMsg
        spawn do
          filtered_msg.cmds.each do |cmd|
            # Run synchronously in this fiber
            if msg = cmd.call
              dispatch(msg.as(Message))
            end
          end
        end
        return
      when EnterAltScreenMsg
        Terminal.enter_alt_screen(@output_io)
        @alt_screen_enabled = true
        return
      when ExitAltScreenMsg
        Terminal.exit_alt_screen(@output_io)
        @alt_screen_enabled = false
        return
      when SuspendMsg
        unless ENV["TERM2_DISABLE_SUSPEND"]?
          suspend_program
          # Process will receive SIGCONT and dispatch ResumeMsg via signal handler
        end
        return
      when ResumeMsg
        reapply_terminal_state
        # fall through to model.update so application can react
      when ShowCursorMsg
        Terminal.show_cursor(@output_io)
        return
      when HideCursorMsg
        Terminal.hide_cursor(@output_io)
        return
      when ClearScreenMsg
        Terminal.clear(@output_io)
        return
      when SetWindowTitleMsg
        Terminal.set_window_title(@output_io, filtered_msg.title)
        return
      when RequestWindowSizeMsg
        # Query window size and dispatch as WindowSizeMsg
        width, height = Terminal.size
        dispatch(WindowSizeMsg.new(width, height))
        return
      when PrintMsg
        @render_mailbox.send(filtered_msg)
        return
      when FocusMsg, BlurMsg, WindowSizeMsg
        # Pass these to the application
      when EnableMouseCellMotionMsg
        enable_mouse_cell_motion
        return
      when EnableMouseAllMotionMsg
        enable_mouse_all_motion
        return
      when DisableMouseTrackingMsg
        disable_mouse_tracking
        return
      when EnableBracketedPasteMsg
        Terminal.enable_bracketed_paste(@output_io)
        @bracketed_paste_enabled = true
        return
      when DisableBracketedPasteMsg
        Terminal.disable_bracketed_paste(@output_io)
        @bracketed_paste_enabled = false
        return
      when EnableReportFocusMsg
        Terminal.enable_focus_reporting(@output_io)
        @focus_reporting_enabled = true
        return
      when DisableReportFocusMsg
        Terminal.disable_focus_reporting(@output_io)
        @focus_reporting_enabled = false
        return
      when InterruptMsg
        @pending_shutdown = true
        @killed.set(true)
        stop
        return
      when ExecMsg
        handle_exec(filtered_msg)
        return
      end

      begin
        new_model, cmd = @model.update(filtered_msg)
        @model = new_model.as(M)
        if filtered_msg.is_a?(QuitMsg)
          @pending_shutdown = true
        end
        schedule_render
        STDERR.puts "running cmd #{cmd}" if ENV["TERM2_DEBUG"]?
        run_cmd(cmd)
      rescue ex
        if @panic_recovery_enabled
          STDERR.puts "Error in update: #{ex.message}"
          STDERR.puts ex.backtrace.join("\n") if ENV["TERM2_DEBUG"]?
          @killed.set(true)
          raise ex
        else
          raise ex
        end
      end
    end

    private def schedule_render
      frame = @model.view
      @render_mailbox.send(frame)
    end

    private def drain_render_queue
      while op = @render_mailbox.poll
        STDERR.puts "rendering frame" if ENV["TERM2_DEBUG"]?
        case op
        when String
          render_frame(op)
        when PrintMsg
          render_print(op)
        end
      end
    end

    private def render_frame(frame : String)
      # Clear and scan zones before rendering
      Zone.clear
      stripped = Zone.scan(frame)

      if @renderer_enabled
        @renderer.render(stripped)
      else
        @output_io.print(stripped)
        @output_io.flush
      end
      stop if @pending_shutdown
    end

    private def render_print(msg : PrintMsg)
      if @renderer_enabled
        @renderer.print(msg.text)
      else
        @output_io.print(msg.text)
        @output_io.flush
      end
    end

    private def run_cmd(cmd : Cmd?)
      return unless cmd
      spawn do
        if msg = cmd.call
          dispatch(msg.as(Message))
        end
      end
    end

    private def handle_exec(msg : ExecMsg)
      # Release terminal state
      Terminal.show_cursor(@output_io)
      Terminal.exit_alt_screen(@output_io) if @alt_screen_enabled
      Terminal.disable_focus_reporting(@output_io) if @focus_reporting_enabled
      Terminal.enable_bracketed_paste(@output_io)
      @output_io.print("\033[0m")
      @output_io.flush

      error : Exception? = nil
      begin
        proc_input = @input_io ? @input_io.not_nil! : Process::Redirect::Close
        status = Process.run(msg.cmd, args: msg.args, input: proc_input, output: @output_io, error: STDERR)
        error = RuntimeError.new("exit #{status.system_exit_status}") unless status.success?
      rescue ex
        error = ex
      ensure
        # Restore program terminal state
        Terminal.hide_cursor(@output_io)
        if @alt_screen_enabled
          Terminal.enter_alt_screen(@output_io)
          Terminal.clear(@output_io)
        end
        if @focus_reporting_enabled
          Terminal.enable_focus_reporting(@output_io)
        end
        Mouse.disable_tracking(@output_io)
      end

      if callback = msg.callback
        dispatch(callback.call(error))
      end
    end

    private def cleanup
      if @renderer_enabled
        @renderer.stop
      end
      restore_terminal
      restore_signal_handlers
      @dispatcher.stop
      @done.fill(nil) rescue nil
    end

    private def suspend_program
      @input_running.set(false)
      # Cancel input reader so it can be reinitialized after suspend.
      @signal_handling_enabled = false
      if io = @input_io.as?(IO::FileDescriptor)
        begin
          io.cooked!
        rescue
        end
      end
      Terminal.show_cursor(@output_io)
      Terminal.exit_alt_screen(@output_io) if @alt_screen_enabled
      Terminal.disable_focus_reporting(@output_io) if @focus_reporting_enabled
      Terminal.disable_bracketed_paste(@output_io) if @bracketed_paste_enabled
      disable_mouse_tracking
      @output_io.flush
      # Send SIGTSTP to process group so the shell can resume with SIGCONT
      begin
        {% if flag?(:unix) %}
          ::LibC.kill(0, Signal::TSTP.value)
        {% end %}
      rescue
        # Ignore if platform doesn't support it
      end
    end

    private def reapply_terminal_state
      @signal_handling_enabled = true
      if io = @input_io.as?(IO::FileDescriptor)
        begin
          io.raw!
        rescue
        end
      end
      Terminal.enter_alt_screen(@output_io) if @alt_screen_enabled
      Terminal.hide_cursor(@output_io)
      Terminal.enable_focus_reporting(@output_io) if @focus_reporting_enabled
      Terminal.enable_bracketed_paste(@output_io) if @bracketed_paste_enabled
      if @mouse_cell_motion_enabled
        enable_mouse_cell_motion
      elsif @mouse_all_motion_enabled
        enable_mouse_all_motion
      end
      setup_signal_handlers
      start_input_reader
    end

    private def restore_terminal
      Terminal.show_cursor(@output_io)

      if @alt_screen_enabled
        Terminal.exit_alt_screen(@output_io)
      end

      if @focus_reporting_enabled
        Terminal.disable_focus_reporting(@output_io)
      end

      unless @bracketed_paste_enabled
        Terminal.enable_bracketed_paste(@output_io)
      end

      # Clean up mouse modes
      if @mouse_cell_motion_enabled || @mouse_all_motion_enabled
        Mouse.disable_tracking(@output_io)
      end
    end

    private def setup_signal_handlers
      return unless @signal_handling_enabled

      # Handle SIGINT (Ctrl+C)
      Process.on_terminate do
        dispatch(QuitMsg.new)
      end

      # Handle SIGTERM
      Process.on_terminate do
        dispatch(QuitMsg.new)
      end

      # Handle window resize (SIGWINCH)
      Signal::WINCH.trap do
        width, height = Terminal.size
        dispatch(WindowSizeMsg.new(width, height))
      end

      # Handle resume after SIGCONT
      Signal::CONT.trap do
        dispatch(ResumeMsg.new)
      end
    end

    private def restore_signal_handlers
      return unless @signal_handling_enabled

      # Restore default signal handlers
      Signal::INT.reset
      Signal::TERM.reset
      Signal::WINCH.reset
      Signal::CONT.reset
    end
  end

  record KeyBinding,
    action : Symbol,
    keys : Array(String),
    help : String = "" do
    def matches?(key : String) : Bool
      keys.includes?(key)
    end

    def matches?(key : Key) : Bool
      keys.includes?(key.to_s)
    end
  end

  module Prelude
    alias Cmd = Term2::Cmd
    alias Cmds = Term2::Cmds
    alias Model = Term2::Model
    alias TC = Term2::Components
    alias Message = Term2::Message
    alias Msg = Term2::Message
    alias Terminal = Term2::Terminal
    alias Program = Term2::Program
    alias KeyPress = Term2::KeyPress
    alias MouseEvent = Term2::MouseEvent
    alias QuitMsg = Term2::QuitMsg
    alias Dispatcher = Term2::Dispatcher
    alias KeyBinding = Term2::KeyBinding
    alias ProgramOptions = Term2::ProgramOptions
    alias ProgramOption = Term2::ProgramOption
    alias WithAltScreen = Term2::WithAltScreen
    alias WithMouseCellMotion = Term2::WithMouseCellMotion
    alias WithMouseAllMotion = Term2::WithMouseAllMotion
    alias WithReportFocus = Term2::WithReportFocus
    alias WithoutBracketedPaste = Term2::WithoutBracketedPaste
    alias EnterAltScreenMsg = Term2::EnterAltScreenMsg
    alias ExitAltScreenMsg = Term2::ExitAltScreenMsg
    alias ShowCursorMsg = Term2::ShowCursorMsg
    alias HideCursorMsg = Term2::HideCursorMsg
    alias ClearScreenMsg = Term2::ClearScreenMsg
    alias SetWindowTitleMsg = Term2::SetWindowTitleMsg
    alias FocusMsg = Term2::FocusMsg
    alias BlurMsg = Term2::BlurMsg
    alias WindowSizeMsg = Term2::WindowSizeMsg
    alias KeyMsg = Term2::KeyMsg
    alias Key = Term2::Key
    alias KeyType = Term2::KeyType
    alias Style = Term2::Style
    alias Color = Term2::Color
    alias Text = Term2::Text
    alias Position = Term2::Position
    alias Border = Term2::Border
  end
end
