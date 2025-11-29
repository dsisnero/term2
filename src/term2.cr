require "cml"
require "cml/mailbox"
require "./base_types"
require "./terminal"
require "./program_options"
require "./key_sequences"
require "./mouse"
require "./styles"
require "./lipgloss"
require "./view"
require "./layout"
require "./renderer"
require "./components/*"

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
      char, timeout = read_next_char(io)

      if timeout
        return resolve_current_buffer
      end

      # Handle paste mode
      if @in_paste
        return handle_paste_mode(char) if char
      end

      # Add to buffer and check for paste start
      @buffer += char.to_s

      if check_paste_start
        return nil
      end

      # Check for mouse events
      if handle_mouse_events
        return Key.new(KeyType::Null)
      end

      # Clear last mouse event since we're not returning a mouse event
      @last_mouse_event = nil

      # Check for escape sequences or single character
      handle_escape_sequences
    rescue InvalidByteSequenceError
      # Return replacement character for invalid UTF-8
      Key.new('\uFFFD')
    rescue IO::EOFError
      if !@buffer.empty?
        resolve_current_buffer
      else
        raise IO::EOFError.new
      end
    end

    private def read_next_char(io : IO) : {Char?, Bool}
      char = nil
      timeout = false

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
          begin
            char = io.read_char
            raise IO::EOFError.new unless char
          rescue IO::EOFError
            timeout = true
          end
        end
      end

      {char, timeout}
    end

    private def handle_paste_mode(char : Char) : Key?
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
      nil
    end

    private def check_paste_start : Bool
      if @buffer.ends_with?(PASTE_START)
        @in_paste = true
        @paste_buffer = ""
        @buffer = ""
        return true
      end

      # Check if we might be in a paste start sequence (partial match)
      if PASTE_START.starts_with?(@buffer) && @buffer.size < PASTE_START.size
        return true # Need more characters
      end

      false
    end

    private def handle_mouse_events : Bool
      if @buffer.starts_with?("\e[")
        mouse_event = @mouse_reader.check_mouse_event(@buffer)
        if mouse_event
          @buffer = ""
          @last_mouse_event = mouse_event
          return true
        end
      end
      false
    end

    private def handle_escape_sequences : Key?
      if @buffer.starts_with?("\e")
        # Check if we have a complete sequence
        exact_match = KeySequences.find(@buffer)
        is_prefix = KeySequences.prefix?(@buffer)

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
    Cmd.quit
  end

  # Helper to batch multiple commands
  def self.batch(*cmds : Cmd) : Cmd
    Cmd.batch(*cmds)
  end

  # Helper to batch multiple commands from an array
  def self.batch(cmds : Enumerable(Cmd)) : Cmd
    Cmd.new do |dispatch|
      cmds.each &.run(dispatch)
    end
  end

  # Program manages the event loop using CML primitives.
  class Program(M)
    getter dispatcher : Dispatcher
    getter! model
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
    @filter : Proc(Message, Message)?
    @renderer : Renderer

    alias RenderOp = String | PrintMsg

    def initialize(@model : M, input : IO? = STDIN, output : IO = STDOUT, options : ProgramOptions = ProgramOptions.new)
      @input_io = input
      @output_io = output
      @mailbox = CML::Mailbox(Message).new
      @render_mailbox = CML::Mailbox(RenderOp).new
      @done = CML::IVar(Nil).new
      @dispatcher = Dispatcher.new(@mailbox)
      @running = Atomic(Bool).new(false)
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

      # Apply options
      @options.apply(self)
    end

    def run : M
      # Run inside raw mode if we have an input IO that supports it
      if io = @input_io
        case io
        when IO::FileDescriptor
          # Log.debug { "Entering raw mode on #{io}" }
          io.raw do
            run_internal
          end
        else
          run_internal
        end
      else
        run_internal
      end
      @model
    end

    private def run_internal
      if @panic_recovery_enabled
        begin
          bootstrap
          listen_loop
        rescue ex
          # Ensure terminal is restored even on crash
          cleanup
          raise ex
        end
      else
        bootstrap
        listen_loop
      end
    ensure
      cleanup
    end

    def dispatch(msg : Message) : Nil
      @dispatcher.dispatch(msg)
    end

    def stop : Nil
      return unless @running.compare_and_set(true, false)
      @dispatcher.stop
      @done.fill(nil)
    end

    # Option methods
    def enable_alt_screen : Nil
      @alt_screen_enabled = true
    end

    def disable_renderer : Nil
      @renderer_enabled = false
    end

    def disable_panic_recovery : Nil
      @panic_recovery_enabled = false
    end

    def disable_signal_handling : Nil
      @signal_handling_enabled = false
    end

    def input=(input : IO) : Nil
      @input_io = input
    end

    def output=(output : IO) : Nil
      @output_io = output
    end

    def force_input_tty : Nil
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

    def filter=(filter : Message -> Message) : Nil
      @filter = filter
    end

    def enable_focus_reporting : Nil
      @focus_reporting_enabled = true
    end

    def disable_bracketed_paste : Nil
      @bracketed_paste_enabled = false
    end

    def enable_mouse_cell_motion : Nil
      @mouse_cell_motion_enabled = true
      @mouse_all_motion_enabled = false
      Mouse.enable_tracking
    end

    def enable_mouse_all_motion : Nil
      @mouse_all_motion_enabled = true
      @mouse_cell_motion_enabled = false
      Mouse.enable_move_reporting
    end

    def disable_mouse_tracking : Nil
      @mouse_cell_motion_enabled = false
      @mouse_all_motion_enabled = false
      Mouse.disable_tracking
    end

    private def bootstrap
      @running.set(true)
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
      spawn(name: "term2-input") { read_input(io) }
    end

    private def read_input(io : IO)
      key_reader = KeyReader.new

      while running?
        begin
          # Read a key (KeyReader handles mouse events internally via check_mouse_event)
          result = key_reader.read_key(io)
          next unless result # Continue if nil (partial sequence)

          # Check if KeyReader detected a mouse event
          if mouse_event = key_reader.last_mouse_event
            dispatch(mouse_event)
            next
          end

          key = result

          if key.type == KeyType::FocusIn
            dispatch(FocusMsg.new)
          elsif key.type == KeyType::FocusOut
            dispatch(BlurMsg.new)
          else
            dispatch(KeyMsg.new(key))
            # Also dispatch legacy KeyPress for backward compatibility
            dispatch(KeyPress.new(key.to_s))
          end
        rescue IO::EOFError
          break
        end
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
      getter message : Message

      def initialize(@message : Message); end
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
                       filter.call(msg)
                     else
                       msg
                     end

      # Handle internal terminal messages
      if handle_internal_message(filtered_msg)
        return
      end

      begin
        new_model, cmd = @model.update(filtered_msg)
        @model = new_model.as(M)
        schedule_render
        STDERR.puts "running cmd #{cmd}" if ENV["TERM2_DEBUG"]?
        run_cmd(cmd)
      rescue ex
        if @panic_recovery_enabled
          STDERR.puts "Error in update: #{ex.message}"
          STDERR.puts ex.backtrace.join("\n") if ENV["TERM2_DEBUG"]?
        else
          raise ex
        end
      end
    end

    private def handle_internal_message(msg : Message) : Bool
      case msg
      when QuitMsg
        handle_quit_message
      when EnterAltScreenMsg
        handle_enter_alt_screen_message
      when ExitAltScreenMsg
        handle_exit_alt_screen_message
      when ShowCursorMsg
        handle_show_cursor_message
      when HideCursorMsg
        handle_hide_cursor_message
      when ClearScreenMsg
        handle_clear_screen_message
      when SetWindowTitleMsg
        handle_set_window_title_message(msg)
      when RequestWindowSizeMsg
        handle_request_window_size_message
      when PrintMsg
        handle_print_message(msg)
      when FocusMsg, BlurMsg, WindowSizeMsg
        # Pass these to the application
        false
      when EnableMouseCellMotionMsg
        handle_enable_mouse_cell_motion_message
      when EnableMouseAllMotionMsg
        handle_enable_mouse_all_motion_message
      when DisableMouseTrackingMsg
        handle_disable_mouse_tracking_message
      when EnableBracketedPasteMsg
        handle_enable_bracketed_paste_message
      when DisableBracketedPasteMsg
        handle_disable_bracketed_paste_message
      when EnableReportFocusMsg
        handle_enable_report_focus_message
      when DisableReportFocusMsg
        handle_disable_report_focus_message
      else
        false
      end
    end

    private def handle_quit_message : Bool
      @pending_shutdown = true
      schedule_render
      true
    end

    private def handle_enter_alt_screen_message : Bool
      Terminal.enter_alt_screen(@output_io)
      @alt_screen_enabled = true
      true
    end

    private def handle_exit_alt_screen_message : Bool
      Terminal.exit_alt_screen(@output_io)
      @alt_screen_enabled = false
      true
    end

    private def handle_show_cursor_message : Bool
      Terminal.show_cursor(@output_io)
      true
    end

    private def handle_hide_cursor_message : Bool
      Terminal.hide_cursor(@output_io)
      true
    end

    private def handle_clear_screen_message : Bool
      Terminal.clear(@output_io)
      true
    end

    private def handle_set_window_title_message(msg : SetWindowTitleMsg) : Bool
      Terminal.set_window_title(@output_io, msg.title)
      true
    end

    private def handle_request_window_size_message : Bool
      width, height = Terminal.size
      dispatch(WindowSizeMsg.new(width, height))
      true
    end

    private def handle_print_message(msg : PrintMsg) : Bool
      @render_mailbox.send(msg)
      true
    end

    private def handle_enable_mouse_cell_motion_message : Bool
      enable_mouse_cell_motion
      true
    end

    private def handle_enable_mouse_all_motion_message : Bool
      enable_mouse_all_motion
      true
    end

    private def handle_disable_mouse_tracking_message : Bool
      disable_mouse_tracking
      true
    end

    private def handle_enable_bracketed_paste_message : Bool
      Terminal.enable_bracketed_paste(@output_io)
      @bracketed_paste_enabled = true
      true
    end

    private def handle_disable_bracketed_paste_message : Bool
      Terminal.disable_bracketed_paste(@output_io)
      @bracketed_paste_enabled = false
      true
    end

    private def handle_enable_report_focus_message : Bool
      Terminal.enable_focus_reporting(@output_io)
      @focus_reporting_enabled = true
      true
    end

    private def handle_disable_report_focus_message : Bool
      Terminal.disable_focus_reporting(@output_io)
      @focus_reporting_enabled = false
      true
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
      if @renderer_enabled
        @renderer.render(frame)
      else
        @output_io.print(frame)
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
      cmd.try &.run(dispatcher)
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
    end

    private def restore_signal_handlers
      return unless @signal_handling_enabled

      # Restore default signal handlers
      Signal::INT.reset
      Signal::TERM.reset
      Signal::WINCH.reset
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
    alias Model = Term2::Model
    alias TC = Term2::Components
    alias Message = Term2::Message
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
    alias S = Term2::S
    alias Style = Term2::Style
    alias Color = Term2::Color
    alias Text = Term2::Text
    alias Cursor = Term2::Cursor
    alias Layout = Term2::Layout
  end
end
