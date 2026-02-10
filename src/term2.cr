require "cml"
require "./base_types"
require "./exec"
require "./zone"
require "./terminal"
require "./program_context"
require "./program_options"
require "./mouse"
require "./renderer"
require "./cursed_renderer"
require "./environ"
require "./color_profile"
require "lipgloss"
require "./components/*"

# Term2 is a Crystal port of the Bubble Tea terminal UI library.
module Term2
  VERSION = "0.1.0"

  # Raised when a program is killed (e.g., by a timeout in tests)
  class ProgramKilled < Exception
  end

  # Raised when panic recovery is disabled and an exception bubbles up.
  class ProgramPanic < Exception
  end

  # Gets the first UTF-8 rune from a string
  def self.get_first_rune_as_string(str : String) : String
    return "" if str.empty?

    # Get the first character (Crystal handles UTF-8 correctly)
    str[0].to_s
  end

  # Dispatcher bridges commands to the program's message mailbox.
  # Run the program with the given model.
  def self.run(model : M, input : IO? = STDIN, output : IO = STDOUT, options : ProgramOptions = ProgramOptions.new) forall M
    Program(M).new(model, input, output, options).run
  end

  def self.quit : Cmd
    Cmds.quit
  end

  def self.batch(*cmds : Cmd) : Cmd
    Cmds.batch(*cmds)
  end

  # Program manages the event loop using CML primitives.
  class Program(M)
    getter dispatcher : Dispatcher
    getter! model
    getter output_io : IO
    getter input_io : IO?
    getter startup_options : Array(Symbol)
    getter context : ProgramContext?
    getter input_type : Symbol
    getter environment : Hash(String, String)
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
    @filter : FilterProc?
    @renderer : Renderer
    @shutdown_ch = CML::Chan(Nil).new
    @context : ProgramContext?
    @startup_options : Array(Symbol)
    @input_type : Symbol
    property? input_tty : Bool = false
    @log_file : File? = nil
    @needs_render : Bool = false
    @profile : Bool = false
    @killed : Atomic(Bool) = Atomic(Bool).new(false)
    @window_size : {Int32, Int32} = {0, 0}
    @color_profile : Lipgloss::ColorProfile? = nil
    @environment : Hash(String, String) = Hash(String, String).new
    @last_view : View? = nil
    @cleaned_up : Bool = false
    @bootstrapping : Bool = true
    @view_mouse_mode : MouseMode = MouseMode::None
    @deferred_outputs : Array(String) = [] of String

    alias RenderOp = String | PrintMsg
    alias FilterProc = Proc(Msg, Msg?) | Proc(Model, Msg, Msg?) | Proc(Msg, Msg) | Proc(Model, Msg, Msg)

    def initialize(@model : M, input : IO? = STDIN, output : IO = STDOUT, options : ProgramOptions = ProgramOptions.new)
      @input_io = input
      @output_io = output
      @mailbox = CML::Mailbox(Msg).new
      @render_mailbox = CML::Mailbox(RenderOp).new
      @done = CML::IVar(Bool).new
      @shutdown_ch = CML::Chan(Nil).new

      @dispatcher = Dispatcher.new(@mailbox)
      @running = Atomic(Bool).new(false)
      @pending_shutdown = false
      @options = options
      @alt_screen_enabled = false
      @renderer_enabled = true
      @panic_recovery_enabled = true
      @signal_handling_enabled = true
      @focus_reporting_enabled = false
      @bracketed_paste_enabled = true
      @mouse_cell_motion_enabled = false
      @mouse_all_motion_enabled = false
      @filter = nil
      @renderer = CursedRenderer.new(@output_io)
      @context = nil
      @startup_options = [] of Symbol
      @input_type = :stdin

      @options.apply(self)
      CML.trace "Program.initialize", tag: "term2" if ENV["TERM2_TRACE"]?
      STDERR.puts "DEBUG: Program initialize completed" if ENV["TERM2_DEBUG"]?
      STDERR.flush
    end

    # Use a custom renderer instance
    def use_renderer(renderer : Renderer) : Nil
      @renderer = renderer
    end

    def run : M
      STDERR.puts "DEBUG: run start" if ENV["TERM2_DEBUG"]?
      if the_io = @input_io
        if the_io.responds_to?(:raw!) && the_io.is_a?(IO::FileDescriptor)
          if the_io.tty?
            @input_tty = true
            the_io.raw!
          end
        end
      end

      begin
        run_internal
      ensure
        if input_tty? && @input_io
          @input_io.try(&.as(IO::FileDescriptor).cooked!)
        end
        cleanup
      end
      @model
    end

    private def run_internal
      STDERR.puts "DEBUG: run_internal start" if ENV["TERM2_DEBUG"]?
      if @panic_recovery_enabled
        begin
          bootstrap
          listen_loop
        rescue ex
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

    def dispatch(msg : Msg) : Nil
      @dispatcher.dispatch(msg.as(Msg))
    end

    # Directly process a message (synchronous). Useful for tests.
    def process_message(msg : Msg) : Nil
      handle_message(msg)
    end

    def send(msg : Msg) : Nil
      return if @shutdown_ch.closed?
      dispatch(msg)
    end

    def quit : Nil
      return if @shutdown_ch.closed?
      dispatch(QuitMsg.new)
    end

    def stop : Nil
      CML.trace "Program.stop", tag: "term2" if ENV["TERM2_TRACE"]?
      return unless @running.compare_and_set(true, false)
      @dispatcher.stop
      @done.i_put(true) rescue nil
    end

    def kill : Nil
      @killed.set(true)
      stop
      raise ProgramKilled.new("program killed")
    end

    # Wait for program completion
    def wait : Nil
      CML.sync(@done.i_get_evt)
      if @killed.get
        raise ProgramKilled.new("program killed")
      end
    end

    def shutdown_evt : CML::Event(Nil)
      @shutdown_ch.recv_evt
    end

    # Options
    def enable_alt_screen
      @alt_screen_enabled = true
      record_startup_option(:alt_screen)
    end

    def disable_renderer
      @renderer_enabled = false
    end

    def disable_panic_recovery
      @panic_recovery_enabled = false
      record_startup_option(:without_catch_panics)
    end

    def disable_signal_handling
      @signal_handling_enabled = false
      record_startup_option(:without_signal_handler)
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

    def bracketed_paste_enabled? : Bool
      @bracketed_paste_enabled
    end

    def mouse_cell_motion_enabled? : Bool
      @mouse_cell_motion_enabled
    end

    def mouse_all_motion_enabled? : Bool
      @mouse_all_motion_enabled
    end

    def output=(output : IO)
      @output_io = output
      @renderer.output = output
    end

    def input=(input : IO)
      @input_io = input
      @input_type = :custom
    end

    def force_input_tty
      @input_type = :tty
      @input_io = File.open("/dev/tty")
      @input_tty = true
    rescue
      @input_io = nil
      @input_tty = true
    end

    def context=(ctx : ProgramContext)
      @context = ctx
    end

    def input_type=(type : Symbol)
      @input_type = type
    end

    def environment=(env : Hash(String, String))
      @environment = env
    end

    def fps=(fps : Float64)
      @renderer.fps = fps
    end

    def window_size=(size : {Int32, Int32})
      @window_size = size
    end

    def window_size : {Int32, Int32}
      if @window_size == {0, 0}
        Terminal.size
      else
        @window_size
      end
    end

    def color_profile=(profile : Lipgloss::ColorProfile)
      @color_profile = profile
      @renderer.color_profile = profile
    end

    def filter=(filter : Proc(Msg, Msg?)) : Nil
      @filter = filter
    end

    def filter=(filter : Proc(Model, Msg, Msg?)) : Nil
      @filter = filter
    end

    def filter=(filter : Proc(Msg, Msg)) : Nil
      @filter = filter
    end

    def filter=(filter : Proc(Model, Msg, Msg)) : Nil
      @filter = filter
    end

    def add_startup_option(option : Symbol) : Nil
      record_startup_option(option)
    end

    def enable_focus_reporting
      @focus_reporting_enabled = true
    end

    def disable_bracketed_paste
      @bracketed_paste_enabled = false
      record_startup_option(:without_bracketed_paste)
    end

    def enable_mouse_cell_motion
      @mouse_cell_motion_enabled = true
      @mouse_all_motion_enabled = false
      remove_startup_option(:mouse_all_motion)
      record_startup_option(:mouse_cell_motion)
      Mouse.enable_tracking(@output_io)
    end

    def enable_mouse_all_motion
      @mouse_all_motion_enabled = true
      @mouse_cell_motion_enabled = false
      remove_startup_option(:mouse_cell_motion)
      record_startup_option(:mouse_all_motion)
      Mouse.enable_move_reporting(@output_io)
    end

    def disable_mouse_tracking
      @mouse_cell_motion_enabled = false
      @mouse_all_motion_enabled = false
      Mouse.disable_tracking(@output_io)
    end

    def set_mouse_cell_motion
      @mouse_cell_motion_enabled = true
      @mouse_all_motion_enabled = false
      remove_startup_option(:mouse_all_motion)
      record_startup_option(:mouse_cell_motion)
    end

    def set_mouse_all_motion
      @mouse_all_motion_enabled = true
      @mouse_cell_motion_enabled = false
      remove_startup_option(:mouse_cell_motion)
      record_startup_option(:mouse_all_motion)
    end

    private def record_startup_option(option : Symbol)
      @startup_options.reject! { |opt| opt == option }
      @startup_options << option
    end

    private def remove_startup_option(option : Symbol)
      @startup_options.reject! { |opt| opt == option }
    end

    private def bootstrap
      STDERR.puts "DEBUG: bootstrap start" if ENV["TERM2_DEBUG"]?
      CML::Tracer.set_fiber_name("term2-main") if ENV["TERM2_TRACE"]?
      CML.trace "bootstrap.start", tag: "term2" if ENV["TERM2_TRACE"]?
      @running.set(true)
      @profile = ENV["TERM2_PROFILE"]? == "1"
      if path = ENV["TERM2_LOG_FILE"]?
        begin
          Dir.mkdir_p(File.dirname(path))
          @log_file = File.open(path, "a")
          @log_file.not_nil!.sync = true
        rescue ex
          STDERR.puts "TERM2_LOG_FILE error: #{ex.message}"
        end
      end
      detect_environment
      if @renderer_enabled
        @renderer.start
      end
      setup_terminal
      # Bubble Tea parity: send an initial window size message before the first render.
      if Terminal.tty?(@output_io)
        width, height = window_size
        new_model, cmd = @model.update(UV::WindowSizeEvent.new(width, height))
        @model = new_model.as(M)
        run_cmd(cmd)
      end
      setup_signal_handlers
      start_input_reader
      init_cmd = @model.init
      schedule_render
      run_cmd(init_cmd)
    end

    private def drain_startup_messages
      while msg = @mailbox.recv_poll
        handle_message(msg)
      end
    end

    private def setup_terminal
      if @alt_screen_enabled
        Terminal.enter_alt_screen(@output_io)
      end
      if @focus_reporting_enabled
        Terminal.enable_focus_reporting(@output_io)
      end
      if @mouse_cell_motion_enabled
        Mouse.enable_tracking(@output_io)
      elsif @mouse_all_motion_enabled
        Mouse.enable_move_reporting(@output_io)
      end
    end

    private def detect_environment
      # Populate environment hash if empty
      if @environment.empty?
        @environment = ENV.to_h
      end

      # Detect color profile
      detected_profile = Environ.color_profile
      if @color_profile.nil?
        @color_profile = detected_profile
        @renderer.color_profile = detected_profile
      end

      # Detect dark/light mode from environment
      ColorProfile.update_dark_mode_from_env

      # Send environment message
      dispatch(EnvMsg.new(@environment))

      # Send color profile message
      dispatch(ColorProfileMsg.new(@color_profile.as(Lipgloss::ColorProfile)))
    end

    private def start_input_reader
      CML.trace "start_input_reader", tag: "term2" if ENV["TERM2_TRACE"]?
      return unless io = @input_io
      spawn(name: "term2-input") {
        CML::Tracer.set_fiber_name("term2-input") if ENV["TERM2_TRACE"]?
        CML.trace "input_reader.start", tag: "term2" if ENV["TERM2_TRACE"]?
        read_input(io)
      }
    end

    private def read_input(io : IO)
      stop : Channel(Nil)? = nil
      reader = UV::TerminalReader.new(io, Environ.terminal_type)
      eventc = Channel(UV::Event).new
      stop = Channel(Nil).new

      spawn do
        reader.stream_events(eventc, stop)
      end

      while running?
        event = eventc.receive

        MsgAdapter.each(event) do |msg|
          if msg.is_a?(UV::Key)
            if msg.match_string("shift+tab")
              if prev_id = Zone.focus_prev
                dispatch(ZoneFocusMsg.new(prev_id))
              end
            elsif msg.match_string("tab")
              if next_id = Zone.focus_next
                dispatch(ZoneFocusMsg.new(next_id))
              end
            end
          end

          dispatch(msg)
        end
      end
    ensure
      stop.try &.close rescue nil
    end

    private def running? : Bool
      @running.get
    end

    private def listen_loop
      loop do
        if @bootstrapping
          Fiber.yield
          drain_startup_messages
          @bootstrapping = false
        end
        drain_render_queue
        event = CML.sync(next_event)
        CML.trace "listen_loop.event", event.class.to_s, tag: "term2" if ENV["TERM2_TRACE"]?
        case event
        when InputEvent
          handle_message(event.message)
          # Bubble Tea parity: render promptly after processing input so that
          # single click/key events update the UI without waiting for another
          # event to arrive.
          drain_render_queue
        when DoneEvent
          drain_render_queue
          break
        when ContextCancelEvent
          stop
          raise ProgramKilled.new("program killed")
        end
      end
    end

    private abstract class LoopEvent; end

    private class InputEvent < LoopEvent
      getter message : Msg

      def initialize(@message : Msg); end
    end

    private class DoneEvent < LoopEvent; end

    private class ContextCancelEvent < LoopEvent; end

    private def next_event : CML::Event(LoopEvent)
      events = [] of CML::Event(LoopEvent)
      input_evt = CML.wrap(@mailbox.recv_evt) { |msg| InputEvent.new(msg).as(LoopEvent) }
      events << input_evt
      events << CML.wrap(@done.i_get_evt) { DoneEvent.new.as(LoopEvent) }
      if ctx = @context
        events << CML.wrap(ctx.cancel_evt) { ContextCancelEvent.new.as(LoopEvent) }
      end
      CML.choose(events)
    end

    private def handle_message(msg : Msg)
      if ENV["TERM2_DEBUG"]?
        STDERR.puts "handle #{msg.class}"
      end
      @log_file.try(&.puts("handle #{msg.class}"))

      # Apply message filter if configured
      # Pass @model (current state) and msg
      filtered_msg_or_nil =
        if filter = @filter
          case filter
          when Proc(Msg, Msg?)
            filter.call(msg.as(Msg))
          when Proc(Msg, Msg)
            filter.call(msg.as(Msg)).as(Msg?)
          when Proc(Model, Msg, Msg?)
            filter.call(@model, msg.as(Msg))
          when Proc(Model, Msg, Msg)
            filter.call(@model, msg.as(Msg)).as(Msg?)
          else
            msg.as(Msg)
          end
        else
          msg.as(Msg)
        end

      # If the filter returned nil, drop the event (Bubble Tea logic)
      return unless filtered_msg_or_nil

      filtered_msg = filtered_msg_or_nil

      case filtered_msg
      when ExecMsg
        execute_process(filtered_msg)
        return
      when BatchMsg
        if @bootstrapping
          exec_batch(filtered_msg)
        else
          spawn { exec_batch(filtered_msg) }
        end
        return
      when SequenceMsg
        exec_sequence(filtered_msg, spawn_async: !@bootstrapping)
        return
      when QuitMsg
        CML.trace "handle_message.QuitMsg", tag: "term2" if ENV["TERM2_TRACE"]?
        @pending_shutdown = true
        unless @shutdown_ch.closed?
          @shutdown_ch.close
        end
        schedule_render
        stop
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
      when ClearScreenMsg
        if @renderer_enabled && @renderer.running?
          @renderer.request_clear
        else
          Terminal.clear(@output_io)
        end
        return
      when SetWindowTitleMsg
        Terminal.set_window_title(@output_io, filtered_msg.title)
        return
      when RequestWindowSizeMsg
        width, height = window_size
        dispatch(UV::WindowSizeEvent.new(width, height))
        return
      when ReadClipboardMsg
        if @bootstrapping
          buffer = IO::Memory.new
          Terminal.read_clipboard(buffer)
          @deferred_outputs << buffer.to_s
        else
          Terminal.read_clipboard(@output_io)
        end
        return
      when ReadPrimaryClipboardMsg
        if @bootstrapping
          buffer = IO::Memory.new
          Terminal.read_primary_clipboard(buffer)
          @deferred_outputs << buffer.to_s
        else
          Terminal.read_primary_clipboard(@output_io)
        end
        return
      when SetClipboardMsg
        if @bootstrapping
          buffer = IO::Memory.new
          Terminal.set_clipboard(buffer, filtered_msg.text, 'c')
          @deferred_outputs << buffer.to_s
        else
          Terminal.set_clipboard(@output_io, filtered_msg.text, 'c')
        end
        return
      when SetPrimaryClipboardMsg
        if @bootstrapping
          buffer = IO::Memory.new
          Terminal.set_primary_clipboard(buffer, filtered_msg.text)
          @deferred_outputs << buffer.to_s
        else
          Terminal.set_primary_clipboard(@output_io, filtered_msg.text)
        end
        return
      when RequestForegroundColorMsg
        if @bootstrapping
          buffer = IO::Memory.new
          Terminal.request_foreground_color(buffer)
          @deferred_outputs << buffer.to_s
        else
          Terminal.request_foreground_color(@output_io)
        end
        return
      when RequestBackgroundColorMsg
        if @bootstrapping
          buffer = IO::Memory.new
          Terminal.request_background_color(buffer)
          @deferred_outputs << buffer.to_s
        else
          Terminal.request_background_color(@output_io)
        end
        return
      when RequestCursorColorMsg
        if @bootstrapping
          buffer = IO::Memory.new
          Terminal.request_cursor_color(buffer)
          @deferred_outputs << buffer.to_s
        else
          Terminal.request_cursor_color(@output_io)
        end
        return
      when RequestCapabilityMsg
        if @bootstrapping
          buffer = IO::Memory.new
          Terminal.request_capability(buffer, filtered_msg.capability)
          @deferred_outputs << buffer.to_s
        else
          Terminal.request_capability(@output_io, filtered_msg.capability)
        end
        return
      when UV::CapabilityEvent
        if Environ.process_capability(filtered_msg.content)
          # Profile upgraded, send notification
          dispatch(ColorProfileMsg.new(Environ.color_profile))
        end
        # fall through to update
      when UV::BackgroundColorEvent
        uv_color = filtered_msg.color
        Environ.update_dark_mode_from_background(
          Lipgloss::Color.rgb(uv_color.r.to_i, uv_color.g.to_i, uv_color.b.to_i)
        )
        # fall through to update
      when UV::ForegroundColorEvent, UV::CursorColorEvent
        # fall through to update (user may handle these)
      when PrintMsg
        @render_mailbox.send(filtered_msg)
        return
      when UV::FocusEvent, UV::BlurEvent, UV::WindowSizeEvent
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
      end

      begin
        t0 = Time.instant if @profile

        # Bubble Tea parity: a single mouse report is one logical input event.
        # We still surface both the UV mouse event and derived ZoneClickMsg to the
        # model, but we apply both updates in one pass so we only render once.
        if uv_mouse_event?(filtered_msg)
          mouse_event = filtered_msg.as(UVMouseEvent)
          if last_view = @last_view
            if handler = last_view.on_mouse
              relative_event = relative_uv_mouse_event(mouse_event, last_view)
              run_cmd(handler.call(relative_event))
            end
          end
          t_update0 = Time.instant if @profile
          updated_model, cmd1 = @model.update(mouse_event)
          current = updated_model.as(M)
          t_update1 = Time.instant if @profile
          cmds = [] of Cmd?
          cmds << cmd1

          # Bubblezone-style mouse handling: send ZoneInBoundsMsg for zones under mouse
          t_update2a = Time.instant if @profile
          updated_model2, cmd2 = Zone.any_in_bounds_and_update(current, mouse_event)
          current = updated_model2.as(M)
          t_update2b = Time.instant if @profile
          cmds << cmd2

          # Also send ZoneClickMsg for backward compatibility
          if zone_click = Zone.handle_mouse(mouse_event)
            if mouse_event.is_a?(UV::MouseClickEvent)
              Zone.focus(zone_click.id)
            end
            @log_file.try { |f| f.puts("in zone_click id=#{zone_click.id} x=#{zone_click.x} y=#{zone_click.y} button=#{zone_click.button} action=#{zone_click.action}") }

            t_update3a = Time.instant if @profile
            updated_model3, cmd3 = current.update(zone_click)
            current = updated_model3.as(M)
            t_update3b = Time.instant if @profile
            cmds << cmd3
          end

          @model = current
          schedule_render
          cmd = Cmds.batch(cmds)
          if @profile
            t1 = Time.instant
            update_ms = ((t_update1.not_nil! - t_update0.not_nil!).total_milliseconds)
            zone_update_ms = 0.0
            if t_update2a && t_update2b
              zone_update_ms = ((t_update2b.not_nil! - t_update2a.not_nil!).total_milliseconds)
            end
            total_ms = ((t1 - t0.not_nil!).total_milliseconds)
            @log_file.try { |f| f.puts("profile handle mouse update_ms=#{update_ms} zone_update_ms=#{zone_update_ms} total_ms=#{total_ms}") }
          end
          STDERR.puts "running cmd #{cmd}" if ENV["TERM2_DEBUG"]?
          run_cmd(cmd)
          return
        end

        t_update0 = Time.instant if @profile
        new_model, cmd = @model.update(filtered_msg)
        t_update1 = Time.instant if @profile
        @model = new_model.as(M)
        schedule_render
        if @profile
          t1 = Time.instant
          update_ms = ((t_update1.not_nil! - t_update0.not_nil!).total_milliseconds)
          total_ms = ((t1 - t0.not_nil!).total_milliseconds)
          @log_file.try { |f| f.puts("profile handle #{filtered_msg.class} update_ms=#{update_ms} total_ms=#{total_ms}") }
        end
        STDERR.puts "running cmd #{cmd}" if ENV["TERM2_DEBUG"]?
        run_cmd(cmd)
      rescue ex
        if @panic_recovery_enabled
          stop
          raise ProgramPanic.new(ex.message, cause: ex)
        end
        raise ex
      end
    end

    private def uv_mouse_event?(msg : Msg) : Bool
      msg.is_a?(UV::MouseClickEvent) || msg.is_a?(UV::MouseReleaseEvent) ||
        msg.is_a?(UV::MouseWheelEvent) || msg.is_a?(UV::MouseMotionEvent)
    end

    private def relative_uv_mouse_event(event : UVMouseEvent, view : View) : UVMouseEvent
      mouse = event.mouse
      rel = UV::Mouse.new(
        x: mouse.x - view.offset_x,
        y: mouse.y - view.offset_y,
        button: mouse.button,
        mod: mouse.mod
      )

      case event
      when UV::MouseClickEvent
        UV::MouseClickEvent.new(rel)
      when UV::MouseReleaseEvent
        UV::MouseReleaseEvent.new(rel)
      when UV::MouseWheelEvent
        UV::MouseWheelEvent.new(rel)
      else
        UV::MouseMotionEvent.new(rel)
      end
    end

    private def schedule_render
      @needs_render = true
    end

    private def drain_render_queue
      last_frame = nil.as(String?)
      print_msgs = [] of PrintMsg

      while op = @render_mailbox.recv_poll
        STDERR.puts "rendering frame" if ENV["TERM2_DEBUG"]?
        case op
        when String
          last_frame = op
        when PrintMsg
          print_msgs << op
        end
      end

      print_msgs.each { |msg| render_print(msg) }

      if frame = last_frame
        @needs_render = false
        render_frame(frame)
      elsif @needs_render
        @needs_render = false
        if @profile
          t0 = Time.instant
          view = @model.view
          t1 = Time.instant
          @log_file.try { |f| f.puts("profile view_ms=#{(t1 - t0).total_milliseconds}") }
          render_frame(view)
        else
          render_frame(@model.view)
        end
      end
    end

    private def render_frame(frame : String)
      @last_view = nil
      t0 = Time.instant if @profile
      Zone.clear_zones
      t_scan0 = Time.instant if @profile
      stripped = Zone.scan(frame)
      t_scan1 = Time.instant if @profile
      if @renderer_enabled
        t_render0 = Time.instant if @profile
        @renderer.render(stripped)
        t_render1 = Time.instant if @profile
      else
        @output_io.print(stripped)
        @output_io.flush
      end
      if @profile
        t1 = Time.instant
        scan_ms = ((t_scan1.not_nil! - t_scan0.not_nil!).total_milliseconds)
        render_ms = 0.0
        if t_render0 && t_render1
          render_ms = ((t_render1.not_nil! - t_render0.not_nil!).total_milliseconds)
        end
        total_ms = ((t1 - t0.not_nil!).total_milliseconds)
        @log_file.try { |f| f.puts("profile render scan_ms=#{scan_ms} render_ms=#{render_ms} total_ms=#{total_ms}") }
      end
      stop if @pending_shutdown
    end

    private def render_frame(frame : View)
      Zone.clear_zones
      scanned_view = Zone.scan(frame)
      @view_mouse_mode = scanned_view.mouse_mode
      @last_view = scanned_view
      @renderer.render(scanned_view)
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
      STDERR.puts "DEBUG: run_cmd called" if ENV["TERM2_DEBUG"]?
      return unless cmd

      STDERR.puts "DEBUG: spawning cmd fiber" if ENV["TERM2_DEBUG"]?
      spawn do
        begin
          STDERR.puts "DEBUG: cmd fiber executing" if ENV["TERM2_DEBUG"]?
          if msg = cmd.call
            STDERR.puts "DEBUG: cmd returned #{msg.class}" if ENV["TERM2_DEBUG"]?
            handle_cmd_result(msg)
          end
        rescue ex
          handle_cmd_error(ex)
        end
      end
    end

    private def handle_cmd_result(msg : Msg)
      STDERR.puts "DEBUG: handle_cmd_result #{msg.class}" if ENV["TERM2_DEBUG"]?
      case msg
      when BatchMsg
        exec_batch(msg)
      when SequenceMsg
        exec_sequence(msg, spawn_async: !@bootstrapping)
      else
        dispatch(msg)
      end
    end

    private def exec_batch(batch : BatchMsg)
      cmds = batch.cmds
      return if cmds.empty?
      return if @shutdown_ch.closed?

      done_ch = CML::Chan(Nil).new

      cmds.each do |cmd|
        spawn do
          begin
            next if @shutdown_ch.closed?
            if msg = cmd.call
              next if @shutdown_ch.closed?
              handle_cmd_result(msg)
            end
          rescue ex
            handle_cmd_error(ex)
          ensure
            done_ch.send(nil) rescue nil
          end
        end
      end

      cmds.size.times do
        CML.select([
          done_ch.recv_evt,
          @shutdown_ch.recv_evt,
        ]
        )
        return if @shutdown_ch.closed?
      end
    end

    private def execute_process(msg : ExecMsg)
      if input_tty? && @input_io
        @input_io.try(&.as(IO::FileDescriptor).cooked!)
      end

      if the_input = @input_io
        Terminal.show_cursor(@output_io)
        if @focus_reporting_enabled
          Terminal.disable_focus_reporting(@output_io)
        end

        restore_signal_handlers

        process_err : Exception? = nil
        begin
          status = Process.run(
            msg.cmd,
            msg.args,
            env: msg.env,
            input: the_input,
            output: @output_io,
            error: STDERR
          )
          unless status.success?
            exit_code = status.exit_code
            process_err = ExecError.new(msg.cmd, "#{msg.cmd} exited with status #{exit_code}", exit_code)
          end
        rescue ex
          process_err = ex
        end
      end

      if @input_tty && @input_io
        @input_io.try(&.as(IO::FileDescriptor).raw!)
      end

      setup_signal_handlers

      if @mouse_cell_motion_enabled
        Mouse.enable_tracking(@output_io)
      elsif @mouse_all_motion_enabled
        Mouse.enable_move_reporting(@output_io)
      end

      if @focus_reporting_enabled
        Terminal.enable_focus_reporting(@output_io)
      end

      Terminal.hide_cursor(@output_io)
      Terminal.clear(@output_io)

      if callback = msg.callback
        spawn do
          if cb_msg = callback.call(process_err)
            dispatch(cb_msg)
          end
        end
      end

      schedule_render
    end

    private def exec_sequence(seq : SequenceMsg, spawn_async : Bool = true)
      return if @shutdown_ch.closed?

      runner = -> {
        seq.cmds.each do |cmd|
          # Loop control: break stops the sequence logic inside the fiber
          break if @shutdown_ch.closed?

          begin
            if msg = cmd.call
              break if @shutdown_ch.closed?
              handle_cmd_result(msg)
            end
          rescue ex
            handle_cmd_error(ex)
          end
        end
      }

      if spawn_async
        spawn { runner.call }
      else
        runner.call
      end
    end

    private def handle_cmd_error(ex)
      if @panic_recovery_enabled
        STDERR.puts "Error executing command: #{ex.message}"
        STDERR.puts ex.backtrace.join("\n") if ENV["TERM2_DEBUG"]?
      else
        raise ex
      end
    end

    private def cleanup
      return if @cleaned_up
      @cleaned_up = true
      if @renderer_enabled
        @renderer.stop
      end
      restore_terminal
      restore_signal_handlers
      @dispatcher.stop
      @done.i_put(true) rescue nil
    end

    private def restore_terminal
      show_cursor = !@renderer_enabled || @last_view.nil? || @last_view.not_nil!.cursor.nil?
      if @focus_reporting_enabled
        Terminal.disable_focus_reporting(@output_io)
      end
      @output_io.print("\e[=0;1u")
      alt_screen_active = @alt_screen_enabled || (@last_view && @last_view.not_nil!.alt_screen)
      if alt_screen_active
        Terminal.exit_alt_screen(@output_io)
      else
        if @last_view.nil? || @last_view.not_nil!.cursor.nil?
          @output_io.print("\r")
        end
        @output_io.print("\e[J")
      end
      Terminal.show_cursor(@output_io) if show_cursor
      Terminal.disable_bracketed_paste(@output_io) if @bracketed_paste_enabled
      if @mouse_cell_motion_enabled || @mouse_all_motion_enabled || @view_mouse_mode != MouseMode::None
        Mouse.disable_tracking(@output_io)
      end
      if last_view = @last_view
        if last_view.background_color
          @output_io.print("\e]111\a")
        end
        if last_view.foreground_color
          @output_io.print("\e]110\a")
        end
      end
      @output_io.print("\e[?2026$p")
      @deferred_outputs.each { |payload| @output_io.print(payload) }
      @deferred_outputs.clear
      @output_io.flush
    end

    private def setup_signal_handlers
      return unless @signal_handling_enabled
      Process.on_terminate { dispatch(QuitMsg.new) }
      Process.on_terminate { dispatch(QuitMsg.new) }
      Process.on_terminate { dispatch(QuitMsg.new) }
      Signal::WINCH.trap do
        width, height = window_size
        dispatch(UV::WindowSizeEvent.new(width, height))
      end
    end

    private def restore_signal_handlers
      return unless @signal_handling_enabled
      Signal::INT.reset
      Signal::TERM.reset
      Signal::WINCH.reset
    end
  end

  record KeyBinding, action : Symbol, keys : Array(String), help : String = "" do
    def matches?(key : String) : Bool
      keys.includes?(key)
    end

    def matches?(key : UV::Key) : Bool
      keys.includes?(key.string)
    end
  end

  module Prelude
    alias Cmd = Term2::Cmd
    alias Cmds = Term2::Cmds
    alias Model = Term2::Model
    alias TC = Term2::Components
    alias ControlMsg = Term2::ControlMsg
    alias Terminal = Term2::Terminal
    alias Program = Term2::Program
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
    alias UV = Term2::UV
    alias UVMouseEvent = Term2::UVMouseEvent
  end
end
