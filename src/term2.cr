require "cml"
require "cml/mailbox"
require "./base_types"
require "./terminal"
require "./program_options"
require "./key_sequences"
require "./mouse"
require "./styles"
require "./view"
require "./renderer"

# Term2 is a Crystal port of the Bubble Tea terminal UI library.
#
# It provides a reactive, Elm-inspired architecture for building
# terminal user interfaces using a Model-Update-View pattern.
#
# ## Quick Start
#
# ```crystal
# require "term2"
#
# class MyApp < Term2::Application
#   class MyModel < Term2::Model
#     getter count : Int32 = 0
#     def initialize(@count = 0); end
#   end
#
#   def init
#     MyModel.new
#   end
#
#   def update(msg : Term2::Message, model : Term2::Model)
#     m = model.as(MyModel)
#     case msg
#     when Term2::KeyMsg
#       case msg.key.to_s
#       when "q" then {m, Term2::Cmd.quit}
#       when "+" then {MyModel.new(m.count + 1), Term2::Cmd.none}
#       else {m, Term2::Cmd.none}
#       end
#     else
#       {m, Term2::Cmd.none}
#     end
#   end
#
#   def view(model : Term2::Model) : String
#     "Count: #{model.as(MyModel).count}\nPress + to increment, q to quit"
#   end
# end
#
# MyApp.new.run
# ```
#
# ## Architecture
#
# Term2 follows the Elm architecture:
# - **Model**: Your application state (must inherit from `Term2::Model`)
# - **Update**: A function that takes a message and model, returns new model and optional command
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

  # Internal message that signals the program should terminate.
  # Use `Cmd.quit` to send this message.
  class QuitMsg < Message
  end

  # Message to enter alternate screen mode.
  # Use `Cmd.enter_alt_screen` to send this message.
  class EnterAltScreenMsg < Message
  end

  # Message to exit alternate screen mode.
  # Use `Cmd.exit_alt_screen` to send this message.
  class ExitAltScreenMsg < Message
  end

  # Message to show the cursor.
  # Use `Cmd.show_cursor` to send this message.
  class ShowCursorMsg < Message
  end

  # Message to hide the cursor.
  # Use `Cmd.hide_cursor` to send this message.
  class HideCursorMsg < Message
  end

  # Message sent when the terminal window gains focus.
  # Only received if focus reporting is enabled via `program.enable_focus_reporting`.
  class FocusMsg < Message
  end

  # Message sent when the terminal window loses focus.
  # Only received if focus reporting is enabled via `program.enable_focus_reporting`.
  class BlurMsg < Message
  end

  # Message sent when the terminal window is resized.
  # Contains the new width and height in characters.
  class WindowSizeMsg < Message
    # The new terminal width in characters
    getter width : Int32
    # The new terminal height in characters
    getter height : Int32

    def initialize(@width : Int32, @height : Int32)
    end
  end

  # PrintMsg signals a request to print text to the output
  class PrintMsg < Message
    getter text : String

    def initialize(@text : String)
    end
  end

  # EnableMouseCellMotionMsg signals enabling mouse cell motion tracking
  class EnableMouseCellMotionMsg < Message
  end

  # EnableMouseAllMotionMsg signals enabling mouse all motion tracking
  class EnableMouseAllMotionMsg < Message
  end

  # DisableMouseTrackingMsg signals disabling mouse tracking
  class DisableMouseTrackingMsg < Message
  end

  # Keyboard events emitted by the default input reader.
  # DEPRECATED: Use KeyMsg instead for richer key information
  class KeyPress < Message
    getter key : String

    def initialize(@key : String)
    end
  end

  # KeyMsg contains information about a keypress
  class KeyMsg < Message
    getter key : Key

    def initialize(@key : Key)
    end

    def to_s : String
      @key.to_s
    end
  end

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
        return resolve_current_buffer
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
  class Dispatcher
    def initialize(@mailbox : CML::Mailbox(Message), parent : Dispatcher? = nil, mapper : Proc(Message, Message)? = nil)
      @parent = parent
      @mapper = mapper
      @running_state = parent ? parent.@running_state : Atomic(Bool).new(true)
    end

    def dispatch(msg : Message) : Nil
      return unless running?
      mapped = if mapper = @mapper
                 mapper.call(msg)
               else
                 msg
               end
      if parent = @parent
        parent.dispatch(mapped)
      else
        @mailbox.send(mapped)
      end
    end

    def stop : Nil
      if parent = @parent
        parent.stop
      else
        @running_state.set(false)
      end
    end

    def running? : Bool
      if parent = @parent
        parent.running?
      else
        @running_state.get
      end
    end

    def mapped(&mapper : Message -> Message) : Dispatcher
      Dispatcher.new(@mailbox, self, mapper)
    end
  end

  # Cmd represents an asynchronous side-effect that may emit messages.
  struct Cmd
    @block : Proc(Dispatcher, Nil)?

    def initialize(&block : Dispatcher -> Nil)
      @block = block
    end

    def initialize
      @block = nil
    end

    def run(dispatcher : Dispatcher) : Nil
      @block.try &.call(dispatcher)
    end

    def self.none : self
      new
    end

    def self.message(msg : Message) : self
      new(&.dispatch(msg))
    end

    def self.batch(*cmds : self) : self
      new do |dispatch|
        cmds.each &.run(dispatch)
      end
    end

    def self.sequence(*cmds : self) : self
      new do |dispatch|
        cmds.each &.run(dispatch)
      end
    end

    def self.map(cmd : self, &block : Message -> Message) : self
      new do |dispatch|
        cmd.run(dispatch.mapped(&block))
      end
    end

    def self.every(duration : Time::Span, message : Message) : self
      every(duration) { |_| message }
    end

    def self.every(duration : Time::Span, &block : Time -> Message) : self
      new do |dispatch|
        spawn do
          loop do
            break unless dispatch.running?
            CML.sync(CML.timeout(duration))
            break unless dispatch.running?
            dispatch.dispatch(block.call(Time.utc))
          end
        end
      end
    end

    # Schedule a message to be dispatched after the given duration.
    def self.after(duration : Time::Span, message : Message) : self
      if duration <= Time::Span.zero
        return message(message)
      end
      after(duration) { message }
    end

    # Lazy variant where the message is generated at delivery time.
    def self.after(duration : Time::Span, &block : -> Message) : self
      if duration <= Time::Span.zero
        return message(block.call)
      end
      from_event(CML.wrap(CML.timeout(duration)) { block.call })
    end

    def self.deadline(target : Time, message : Message) : self
      span = duration_until(target)
      return message(message) if span <= Time::Span.zero
      after(span, message)
    end

    def self.deadline(target : Time, &block : -> Message) : self
      span = duration_until(target)
      return after(span, &block) if span > Time::Span.zero
      message(block.call)
    end

    def self.timeout(duration : Time::Span, timeout_message : Message, &block : -> Message) : self
      event = CML.spawn_evt { block.call }
      timeout(duration, timeout_message, event)
    end

    def self.timeout(duration : Time::Span, timeout_message : Message, event : CML::Event(Message)) : self
      events = [] of CML::Event(Message)
      events << event
      timeout_evt = CML.wrap(CML.timeout(duration)) { |_| timeout_message.as(Message) }
      events << timeout_evt
      from_event(CML.choose(events))
    end

    # Sends a message produced by the block after the duration elapses.
    # The block receives the current UTC time similar to tea.Tick in Bubble Tea.
    def self.tick(duration : Time::Span, &block : Time -> Message) : self
      from_event(CML.wrap(CML.timeout(duration)) { block.call(Time.utc) })
    end

    def self.from_event(evt : CML::Event(Message)) : self
      new do |dispatch|
        spawn do
          begin
            dispatch.dispatch(CML.sync(evt))
          rescue
            # Ignore errors from the event and keep the program running.
          end
        end
      end
    end

    def self.perform(&block : -> Message) : self
      new do |dispatch|
        spawn do
          dispatch.dispatch(block.call)
        end
      end
    end

    def self.quit : self
      message(QuitMsg.new)
    end

    # Enter alternate screen mode
    def self.enter_alt_screen : self
      message(EnterAltScreenMsg.new)
    end

    # Exit alternate screen mode
    def self.exit_alt_screen : self
      message(ExitAltScreenMsg.new)
    end

    # Show the cursor
    def self.show_cursor : self
      message(ShowCursorMsg.new)
    end

    # Hide the cursor
    def self.hide_cursor : self
      message(HideCursorMsg.new)
    end

    # Print a message above the program
    def self.println(text : String) : self
      message(PrintMsg.new(text + "\n"))
    end

    # Print formatted text above the program
    def self.printf(format : String, *args) : self
      message(PrintMsg.new(sprintf(format, *args)))
    end

    # Enable mouse cell motion tracking
    def self.enable_mouse_cell_motion : self
      message(EnableMouseCellMotionMsg.new)
    end

    # Enable mouse all motion tracking (hover)
    def self.enable_mouse_all_motion : self
      message(EnableMouseAllMotionMsg.new)
    end

    # Disable mouse tracking
    def self.disable_mouse_tracking : self
      message(DisableMouseTrackingMsg.new)
    end

    private def self.duration_until(target : Time) : Time::Span
      span = target - Time.utc
      span > Time::Span.zero ? span : Time::Span.zero
    end
  end

  # Applications describe the high-level Elm-style lifecycle.
  abstract class Application
    abstract def init
    abstract def update(msg : Message, model : Model)
    abstract def view(model : Model) : String

    def run(input : IO? = STDIN, output : IO = STDOUT) : Model
      Program.new(self, input: input, output: output).run
    end
  end

  # Program manages the event loop using CML primitives.
  class Program
    getter dispatcher : Dispatcher
    getter! model
    @model : Model
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

    def initialize(@application : Application, input : IO? = STDIN, output : IO = STDOUT, options : ProgramOptions = ProgramOptions.new)
      @input_io = input
      @output_io = output
      @mailbox = CML::Mailbox(Message).new
      @render_mailbox = CML::Mailbox(RenderOp).new
      @done = CML::IVar(Nil).new
      @dispatcher = Dispatcher.new(@mailbox)
      @running = Atomic(Bool).new(false)
      @model = uninitialized Model
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

    def run : Model
      if @panic_recovery_enabled
        begin
          bootstrap
          listen_loop
          @model
        rescue ex
          # Ensure terminal is restored even on crash
          cleanup
          raise ex
        end
      else
        bootstrap
        listen_loop
        @model
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
      init_model, init_cmd = normalize_result(@application.init)
      @model = init_model
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
      case filtered_msg
      when QuitMsg
        @pending_shutdown = true
        schedule_render
        return
      when EnterAltScreenMsg
        Terminal.enter_alt_screen(@output_io)
        @alt_screen_enabled = true
        return
      when ExitAltScreenMsg
        Terminal.exit_alt_screen(@output_io)
        @alt_screen_enabled = false
        return
      when ShowCursorMsg
        Terminal.show_cursor(@output_io)
        return
      when HideCursorMsg
        Terminal.hide_cursor(@output_io)
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
      end

      begin
        new_model, cmd = normalize_result(@application.update(filtered_msg, @model))
        @model = new_model
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

    private def schedule_render
      frame = @application.view(@model)
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

    private def normalize_result(result)
      case result
      when Tuple
        model = result[0]
        cmd = result.size > 1 ? result[1].as(Cmd?) : Cmd.none
        {model, cmd}
      else
        {result, Cmd.none}
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

  module Components
    class CountdownTimer
      getter interval : Time::Span

      class Model < Term2::Model
        getter duration : Time::Span
        getter remaining : Time::Span
        getter? running : Bool
        getter last_tick : Time?

        def initialize(@duration : Time::Span, @remaining : Time::Span, @running : Bool, @last_tick : Time?)
        end
      end

      class Start < Term2::Message
        getter duration : Time::Span

        def initialize(@duration : Time::Span)
        end
      end

      class Tick < Term2::Message
        getter time : Time

        def initialize(@time : Time)
        end
      end

      class Finished < Term2::Message
        getter finished_at : Time

        def initialize(@finished_at : Time)
        end
      end

      def initialize(@interval : Time::Span = 100.milliseconds)
      end

      def init(duration : Time::Span) : {Model, Cmd}
        now = Time.utc
        model = Model.new(duration, duration, true, now)
        {model, schedule_tick}
      end

      def update(msg : Term2::Message, model : Model) : {Model, Cmd}
        case msg
        when Start
          restart(msg.duration)
        when Tick
          advance(model, msg.time)
        else
          {model, Cmd.none}
        end
      end

      def view(model : Model) : String
        remaining_seconds = (model.remaining.total_milliseconds / 1000.0).clamp(0.0, model.duration.total_milliseconds / 1000.0)
        status = model.running? ? "running" : "finished"
        "Timer: #{remaining_seconds.round(2)}s (#{status})"
      end

      private def restart(duration : Time::Span) : {Model, Cmd}
        now = Time.utc
        model = Model.new(duration, duration, true, now)
        {model, schedule_tick}
      end

      private def advance(model : Model, tick_at : Time) : {Model, Cmd}
        return {model, Cmd.none} unless model.running?
        last_tick = model.last_tick || tick_at
        elapsed = tick_at - last_tick
        remaining = model.remaining - elapsed

        if remaining <= Time::Span.zero
          finished_model = Model.new(model.duration, Time::Span.zero, false, tick_at)
          {finished_model, Cmd.message(Finished.new(tick_at))}
        else
          updated_model = Model.new(model.duration, remaining, true, tick_at)
          {updated_model, schedule_tick}
        end
      end

      private def schedule_tick : Cmd
        Cmd.tick(@interval) { |time| Tick.new(time) }
      end
    end

    class Spinner
      getter frames : Array(String)

      class Model < Term2::Model
        getter text : String
        getter frame_index : Int32
        getter? spinning : Bool

        def initialize(@text : String, @frame_index : Int32, @spinning : Bool)
        end
      end

      record Theme,
        prefix : String = "",
        suffix : String = "",
        separator : String = " ",
        finished_symbol : String = "✔",
        show_text_when_empty : Bool = false do
        def render(frame : String, text : String, running : Bool) : String
          symbol = running ? frame : finished_symbol
          display_text = text
          display_text = "" if display_text.empty? && !show_text_when_empty
          body = display_text.empty? ? "" : "#{separator}#{display_text}"
          "#{prefix}#{symbol}#{body}#{suffix}"
        end
      end

      class Tick < Message
        getter time : Time

        def initialize(@time : Time)
        end
      end

      class Start < Message
      end

      class Stop < Message
      end

      class SetText < Message
        getter text : String

        def initialize(@text : String)
        end
      end

      def initialize(*, frames : Array(String) = ["|", "/", "-", "\\"], interval : Time::Span = 100.milliseconds, theme : Theme = Theme.new)
        @frames = frames
        @interval = interval
        @theme = theme
      end

      def init(text : String = "") : {Model, Cmd}
        model = Model.new(text, 0, true)
        {model, schedule_tick}
      end

      def update(msg : Term2::Message, model : Model) : {Model, Cmd}
        case msg
        when Start
          resumed = Model.new(model.text, model.frame_index, true)
          {resumed, schedule_tick}
        when Stop
          stopped = Model.new(model.text, model.frame_index, false)
          {stopped, Cmd.none}
        when SetText
          updated = Model.new(msg.text, model.frame_index, model.spinning?)
          {updated, Cmd.none}
        when Tick
          advance(model, msg.time)
        else
          {model, Cmd.none}
        end
      end

      def view(model : Model) : String
        frame = model.spinning? ? @frames[model.frame_index % @frames.size] : @theme.finished_symbol
        @theme.render(frame, model.text, model.spinning?)
      end

      private def advance(model : Model, _time : Time) : {Model, Cmd}
        return {model, Cmd.none} unless model.spinning?
        next_index = (model.frame_index + 1) % @frames.size
        updated = Model.new(model.text, next_index, true)
        {updated, schedule_tick}
      end

      private def schedule_tick : Cmd
        Cmd.tick(@interval) { |time| Tick.new(time) }
      end
    end

    class ProgressBar
      class Model < Term2::Model
        getter percent : Float64
        getter width : Int32
        getter complete_char : Char
        getter incomplete_char : Char
        getter? show_percentage : Bool

        def initialize(@percent : Float64, @width : Int32, @complete_char : Char, @incomplete_char : Char, @show_percentage : Bool)
        end
      end

      class SetPercent < Term2::Message
        getter value : Float64

        def initialize(@value : Float64)
        end
      end

      class Increment < Term2::Message
        getter delta : Float64

        def initialize(@delta : Float64)
        end
      end

      def initialize(*, width : Int32 = 30, complete_char : Char = '=', incomplete_char : Char = ' ', show_percentage : Bool = true)
        @width = width
        @complete_char = complete_char
        @incomplete_char = incomplete_char
        @show_percentage = show_percentage
      end

      def init : {Model, Cmd}
        model = Model.new(0.0, @width, @complete_char, @incomplete_char, @show_percentage)
        {model, Cmd.none}
      end

      def update(msg : Term2::Message, model : Model) : {Model, Cmd}
        case msg
        when SetPercent
          {model_with_percent(model, msg.value), Cmd.none}
        when Increment
          {model_with_percent(model, model.percent + msg.delta), Cmd.none}
        else
          {model, Cmd.none}
        end
      end

      def view(model : Model) : String
        pct = clamp_percent(model.percent)
        filled = (pct * model.width).round.to_i
        bar = String.build do |io|
          io << '['
          filled.times { io << model.complete_char }
          (model.width - filled).times { io << model.incomplete_char }
          io << ']'
        end

        if model.show_percentage?
          "#{bar} #{(pct * 100).round(1)}%"
        else
          bar
        end
      end

      private def model_with_percent(model : Model, percent : Float64) : Model
        Model.new(clamp_percent(percent), model.width, model.complete_char, model.incomplete_char, model.show_percentage?)
      end

      private def clamp_percent(value : Float64) : Float64
        if value < 0.0
          0.0
        elsif value > 1.0
          1.0
        else
          value
        end
      end
    end

    class TextInput
      DEFAULT_BINDINGS = [
        KeyBinding.new(:move_left, ["ctrl+b", "left"], "Left"),
        KeyBinding.new(:move_right, ["ctrl+f", "right"], "Right"),
        KeyBinding.new(:move_start, ["ctrl+a", "home"], "Start"),
        KeyBinding.new(:move_end, ["ctrl+e", "end"], "End"),
        KeyBinding.new(:backspace, ["ctrl+h", "backspace"], "Backspace"),
        KeyBinding.new(:delete, ["ctrl+d", "delete"], "Delete"),
        KeyBinding.new(:clear, ["ctrl+u"], "Clear"),
      ]

      class Model < Term2::Model
        getter value : String
        getter cursor : Int32
        getter? focused : Bool

        def initialize(@value : String, @cursor : Int32, @focused : Bool)
        end
      end

      class Focus < Term2::Message
      end

      class Blur < Term2::Message
      end

      class SetValue < Term2::Message
        getter value : String

        def initialize(@value : String)
        end
      end

      getter placeholder : String

      def initialize(*, placeholder : String = "", max_length : Int32? = nil, key_bindings : Array(KeyBinding) = DEFAULT_BINDINGS)
        @placeholder = placeholder
        @max_length = max_length
        @key_bindings = key_bindings
      end

      def init(value : String = "", focused : Bool = false) : {Model, Cmd}
        value = truncate(value)
        model = Model.new(value, value.size, focused)
        {model, Cmd.none}
      end

      def update(msg : Term2::Message, model : Model) : {Model, Cmd}
        case msg
        when Focus
          {Model.new(model.value, model.cursor, true), Cmd.none}
        when Blur
          {Model.new(model.value, model.cursor, false), Cmd.none}
        when SetValue
          value = truncate(msg.value)
          cursor = value.size.clamp(0, value.size)
          {Model.new(value, cursor, model.focused?), Cmd.none}
        when Term2::KeyMsg
          handle_key_press(msg.key, model)
        when Term2::KeyPress
          # Legacy support - convert to KeyMsg
          key = parse_legacy_key(msg.key)
          handle_key_press(key, model)
        else
          {model, Cmd.none}
        end
      end

      def view(model : Model) : String
        if !model.focused? && model.value.empty? && !@placeholder.empty?
          "  #{@placeholder}"
        else
          display_value(model)
        end
      end

      def key_bindings : Array(KeyBinding)
        @key_bindings
      end

      private def display_value(model : Model) : String
        if model.focused?
          left = model.value[0, model.cursor] || ""
          right = model.value[model.cursor, model.value.size - model.cursor] || ""
          "> #{left}|#{right}"
        else
          "> #{model.value}"
        end
      end

      private def handle_key_press(key : Key, model : Model) : {Model, Cmd}
        if binding = binding_for_key(key)
          apply_binding(binding.action, model)
        elsif printable?(key)
          insert_character(key, model)
        else
          {model, Cmd.none}
        end
      end

      private def binding_for_key(key : Key) : KeyBinding?
        @key_bindings.find(&.matches?(key))
      end

      private def apply_binding(action : Symbol, model : Model) : {Model, Cmd}
        case action
        when :move_left
          move_cursor(model, model.cursor - 1)
        when :move_right
          move_cursor(model, model.cursor + 1)
        when :move_start
          move_cursor(model, 0)
        when :move_end
          move_cursor(model, model.value.size)
        when :backspace
          delete_backwards(model)
        when :delete
          delete_forwards(model)
        when :clear
          {Model.new("", 0, model.focused?), Cmd.none}
        else
          {model, Cmd.none}
        end
      end

      private def printable?(key : Key) : Bool
        key.type == KeyType::Runes && key.runes.size == 1 && key.runes.first.ord >= 32
      end

      private def insert_character(key : Key, model : Model) : {Model, Cmd}
        if max = @max_length
          return {model, Cmd.none} if model.value.size >= max
        end
        char = String.build { |str| key.runes.each { |rune| str << rune } }
        left = model.value[0, model.cursor] || ""
        right = model.value[model.cursor, model.value.size - model.cursor] || ""
        new_value = "#{left}#{char}#{right}"
        new_cursor = model.cursor + char.size
        {Model.new(new_value, new_cursor, model.focused?), Cmd.none}
      end

      private def delete_backwards(model : Model) : {Model, Cmd}
        return {model, Cmd.none} if model.cursor <= 0
        left = model.value[0, model.cursor - 1] || ""
        right = model.value[model.cursor, model.value.size - model.cursor] || ""
        new_value = "#{left}#{right}"
        {Model.new(new_value, model.cursor - 1, model.focused?), Cmd.none}
      end

      private def delete_forwards(model : Model) : {Model, Cmd}
        return {model, Cmd.none} if model.cursor >= model.value.size
        left = model.value[0, model.cursor] || ""
        right = model.value[model.cursor + 1, model.value.size - model.cursor - 1] || ""
        new_value = "#{left}#{right}"
        {Model.new(new_value, model.cursor, model.focused?), Cmd.none}
      end

      private def move_cursor(model : Model, position : Int32) : {Model, Cmd}
        new_cursor = position.clamp(0, model.value.size)
        {Model.new(model.value, new_cursor, model.focused?), Cmd.none}
      end

      private def truncate(value : String) : String
        return value unless max = @max_length
        value[0, max] || value
      end

      private def parse_legacy_key(key_str : String) : Key
        # Convert legacy string keys to new Key objects
        case key_str
        when "\u0001" then Key.new(KeyType::CtrlA)
        when "\u0002" then Key.new(KeyType::CtrlB)
        when "\u0004" then Key.new(KeyType::CtrlD)
        when "\u0005" then Key.new(KeyType::CtrlE)
        when "\u0006" then Key.new(KeyType::CtrlF)
        when "\u0008" then Key.new(KeyType::CtrlH)
        when "\u0015" then Key.new(KeyType::CtrlU)
        when "\u007F" then Key.new(KeyType::Backspace)
        when "\e[D"   then Key.new(KeyType::Left)
        when "\e[C"   then Key.new(KeyType::Right)
        when "\e[H"   then Key.new(KeyType::Home)
        when "\e[F"   then Key.new(KeyType::End)
        else
          if key_str.size == 1
            Key.new(key_str[0])
          else
            Key.new(key_str)
          end
        end
      end
    end
  end

  module Prelude
    alias Cmd = Term2::Cmd
    alias Model = Term2::Model
    alias Message = Term2::Message
    alias Terminal = Term2::Terminal
    alias Program = Term2::Program
    alias Application = Term2::Application
    alias KeyPress = Term2::KeyPress
    alias MouseEvent = Term2::MouseEvent
    alias QuitMsg = Term2::QuitMsg
    alias Dispatcher = Term2::Dispatcher
    alias Components = Term2::Components
    alias KeyBinding = Term2::KeyBinding
    alias ProgramOptions = Term2::ProgramOptions
    alias EnterAltScreenMsg = Term2::EnterAltScreenMsg
    alias ExitAltScreenMsg = Term2::ExitAltScreenMsg
    alias ShowCursorMsg = Term2::ShowCursorMsg
    alias HideCursorMsg = Term2::HideCursorMsg
    alias FocusMsg = Term2::FocusMsg
    alias BlurMsg = Term2::BlurMsg
    alias WindowSizeMsg = Term2::WindowSizeMsg
  end
end
