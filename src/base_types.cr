# Base types for Term2
#
# Mirrors Bubble Tea's core types as closely as possible:
#
#   Go (Bubble Tea)              Crystal (Term2)
#   ---------------              ---------------
#   type Msg interface{}         alias Msg = Ultraviolet::Event | ControlMsg
#   type Cmd func() Msg          alias Cmd = (-> Msg)?
#   type Model interface {       module Model
#     Init() Cmd                   def init : Cmd
#     Update(Msg) (Model, Cmd)     def update(msg) : {Model, Cmd}
#     View() View                  def view : String | View  # v2: View, v1: String
#   }                            end
#
require "cml"
require "./view"
require "lipgloss"
require "../lib/ultraviolet/src/ultraviolet"

module Term2
  alias UV = Ultraviolet

  # Msg is any message that can be sent to the update function.
  # In Go this is `interface{}` (any type). In Crystal we use
  # a union of ultraviolet input events and message-like types.
  #
  # For user-defined messages, include `Term2::MsgLike` to opt in.
  module MsgLike
  end

  abstract class ControlMsg
    include MsgLike
  end

  # Legacy message base class for user-defined messages.
  abstract class Message < ControlMsg
  end

  alias Msg = UV::Event | MsgLike
  alias UVMouseEvent = UV::MouseClickEvent | UV::MouseReleaseEvent | UV::MouseWheelEvent | UV::MouseMotionEvent
  alias KeyMsg = UV::Key
  alias KeyPressMsg = UV::Key
  alias KeyReleaseMsg = UV::Key
  alias WindowSizeMsg = UV::WindowSizeEvent
  alias FocusMsg = UV::FocusEvent
  alias BlurMsg = UV::BlurEvent
  alias MouseMsg = UVMouseEvent
  alias MouseClickMsg = UV::MouseClickEvent
  alias MouseReleaseMsg = UV::MouseReleaseEvent
  alias MouseWheelMsg = UV::MouseWheelEvent
  alias MouseMotionMsg = UV::MouseMotionEvent
  alias BackgroundColorMsg = UV::BackgroundColorEvent
  alias ForegroundColorMsg = UV::ForegroundColorEvent
  alias CursorColorMsg = UV::CursorColorEvent
  alias CapabilityMsg = UV::CapabilityEvent
  alias KeyboardEnhancementsMsg = UV::KeyboardEnhancementsEvent
  alias PasteMsg = UV::PasteEvent
  alias PasteStartMsg = UV::PasteStartEvent
  alias PasteEndMsg = UV::PasteEndEvent

  # Adapters for Ultraviolet events to Term2 messages.
  module MsgAdapter
    def self.each(event : UV::Event, &block : Msg ->) : Nil
      case event
      when Array(UV::EventSingle)
        event.each { |evt| block.call(evt.as(Msg)) }
      else
        block.call(event.as(Msg))
      end
    end

    def self.to_messages(event : UV::Event) : Array(Msg)
      messages = [] of Msg
      each(event) { |msg| messages << msg }
      messages
    end
  end


  # Cmd is an IO operation that returns a message when it's complete.
  # If it's nil it's considered a no-op.
  #
  # Bubble Tea allows commands to return a nil Msg. In Crystal we support both:
  # - commands that always return a message (`-> Msg`)
  # - commands that may return nil (`-> Msg?`)
  alias Cmd = ((-> Msg) | (-> Msg?))?

  # Model contains the program's state as well as its core functions.
  #
  # Any type that includes this module and implements the required
  # methods can be used as a model. This mirrors Go's interface-based
  # approach where any struct with the right methods implements Model.
  #
  # ```
  # class Counter
  #   include Term2::Model
  #
  #   getter count : Int32 = 0
  #
  #   def init : Term2::Cmd
  #     nil # no initial command
  #   end
  #
  #   def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
  #     case msg
  #     when UV::Key
  #       case msg.key.to_s
  #       when "q" then {self, Term2.quit}
  #       when "+" then {Counter.new(@count + 1), nil}
  #       else          {self, nil}
  #       end
  #     else
  #       {self, nil}
  #     end
  #   end
  #
  #   def view : String
  #     "Count: #{@count}"
  #   end
  # end
  # ```
  module Model
    # Init is the first function that will be called. It returns an optional
    # initial command. To not perform an initial command return nil.
    def init : Cmd
      nil
    end

    # Update is called when a message is received. Use it to inspect the
    # message and, in response, update the model and/or send a command.
    abstract def update(msg : Msg) : {Model, Cmd}

    # View renders the program's UI, which can be a string or a View struct.
    # The view is rendered after every Update.
    abstract def view : String | View

    # Zone ID for this model (used by BubbleZone for focus/click tracking).
    # Override this to provide a custom zone ID.
    def zone_id : String?
      nil
    end

    # Whether this model is currently focused.
    def focused? : Bool
      if id = zone_id
        Zone.focused?(id)
      else
        false
      end
    end

    # Focus this model's zone.
    def focus : Cmd
      if id = zone_id
        Zone.focus(id)
      end
      nil
    end

    # Blur (unfocus) this model's zone.
    def blur : Cmd
      if id = zone_id
        Zone.blur(id)
      end
      nil
    end
  end

  # BatchMsg is used internally to run commands concurrently.
  class BatchMsg < ControlMsg
    getter cmds : Array(-> Msg?)

    def initialize(@cmds)
    end
  end

  # SequenceMsg is used internally to run commands in order.
  class SequenceMsg < ControlMsg
    getter cmds : Array(-> Msg?)

    def initialize(@cmds)
    end
  end

  # Key events are represented directly by Ultraviolet::Key.

  # Internal message that signals the program should terminate.
  # Use `Cmds.quit` to send this message.
  class QuitMsg < ControlMsg
  end

  # ControlMsg to enter alternate screen mode.
  # Use `Cmds.enter_alt_screen` to send this message.
  class EnterAltScreenMsg < ControlMsg
  end

  # ControlMsg to exit alternate screen mode.
  # Use `Cmds.exit_alt_screen` to send this message.
  class ExitAltScreenMsg < ControlMsg
  end

  # ControlMsg to show the cursor.
  # Use `Cmds.show_cursor` to send this message.
  class ShowCursorMsg < ControlMsg
  end

  # ControlMsg to hide the cursor.
  # Use `Cmds.hide_cursor` to send this message.
  class HideCursorMsg < ControlMsg
  end

  # Message sent when a suspended program should resume.
  class ResumeMsg < ControlMsg
  end

  # Message sent to request program suspension.
  class SuspendMsg < ControlMsg
  end

  # Message sent when a zone receives focus via tab navigation.
  # Contains the zone ID that should receive focus.
  class ZoneFocusMsg < ControlMsg
    getter zone_id : String

    def initialize(@zone_id : String)
    end
  end

  # PrintMsg signals a request to print text to the output
  class PrintMsg < ControlMsg
    getter text : String

    def initialize(@text : String)
    end
  end

  # ClearScreenMsg signals a request to clear the screen
  class ClearScreenMsg < ControlMsg
  end

  # SetWindowTitleMsg signals a request to set the terminal window title
  class SetWindowTitleMsg < ControlMsg
    getter title : String

    def initialize(@title : String)
    end
  end

  # RequestWindowSizeMsg signals a request for the current window size
  class RequestWindowSizeMsg < ControlMsg
  end

  # ReadClipboardMsg signals a request to read the clipboard
  class ReadClipboardMsg < ControlMsg
  end

  # ReadPrimaryClipboardMsg signals a request to read the primary clipboard
  class ReadPrimaryClipboardMsg < ControlMsg
  end

  # SetClipboardMsg signals a request to set the clipboard
  class SetClipboardMsg < ControlMsg
    getter text : String

    def initialize(@text : String)
    end
  end

  # SetPrimaryClipboardMsg signals a request to set the primary clipboard
  class SetPrimaryClipboardMsg < ControlMsg
    getter text : String

    def initialize(@text : String)
    end
  end

  # RequestForegroundColorMsg signals a request for the terminal's foreground color
  class RequestForegroundColorMsg < ControlMsg
  end

  # RequestBackgroundColorMsg signals a request for the terminal's background color
  class RequestBackgroundColorMsg < ControlMsg
  end

  # RequestCursorColorMsg signals a request for the terminal's cursor color
  class RequestCursorColorMsg < ControlMsg
  end

  # EnableMouseCellMotionMsg signals enabling mouse cell motion tracking
  class EnableMouseCellMotionMsg < ControlMsg
  end

  # EnableMouseAllMotionMsg signals enabling mouse all motion tracking
  class EnableMouseAllMotionMsg < ControlMsg
  end

  # DisableMouseTrackingMsg signals disabling mouse tracking
  class DisableMouseTrackingMsg < ControlMsg
  end

  # EnableBracketedPasteMsg signals enabling bracketed paste mode
  class EnableBracketedPasteMsg < ControlMsg
  end

  # DisableBracketedPasteMsg signals disabling bracketed paste mode
  class DisableBracketedPasteMsg < ControlMsg
  end

  # EnableReportFocusMsg signals enabling focus reporting
  class EnableReportFocusMsg < ControlMsg
  end

  # DisableReportFocusMsg signals disabling focus reporting
  class DisableReportFocusMsg < ControlMsg
  end

# EnvMsg represents the environment variables of the program.
  # This is useful for getting environment variables of programs
  # running in a remote session like SSH. In that case, using ENV[] would
  # return the server's environment variables, not the client's.
  #
  # This message is sent to the program when it starts.
  #
  # Example:
  #
  #   case msg
  #   when Term2::EnvMsg
  #     term = msg.getenv("TERM")
  class EnvMsg < ControlMsg
    getter env : Hash(String, String)

    def initialize(@env : Hash(String, String))
    end

    # Returns the value of the environment variable named by the key.
    # If the variable is not present, returns an empty string.
    def getenv(key : String) : String
      @env[key]? || ""
    end

    # Retrieves the value of the environment variable named by the key.
    # If the variable is present returns the value (may be empty) and true,
    # otherwise returns empty string and false.
    def lookup_env(key : String) : {String, Bool}
      if value = @env[key]?
        {value, true}
      else
        {"", false}
      end
    end

    def ==(other : EnvMsg)
      @env == other.env
    end
  end

  # ColorProfileMsg is a message that describes the terminal's color profile.
  #
  # To upgrade the terminal color profile, use the `RequestCapability` command.
  class ColorProfileMsg < ControlMsg
    getter profile : Lipgloss::ColorProfile

    def initialize(@profile : Lipgloss::ColorProfile)
    end

    def ==(other : ColorProfileMsg)
      @profile == other.profile
    end
  end

  # Internal message that requests the terminal to send its Termcap/Terminfo response.
  class RequestCapabilityMsg < ControlMsg
    getter capability : String

    def initialize(@capability : String)
    end

    def ==(other : RequestCapabilityMsg)
      @capability == other.capability
    end
  end


  class Dispatcher
    def initialize(@mailbox : CML::Mailbox(Msg), parent : Dispatcher? = nil, mapper : Proc(Msg, Msg)? = nil)
      @parent = parent
      @mapper = mapper
      @running_state = parent ? parent.@running_state : Atomic(Bool).new(true)
    end

    def dispatch(msg : Msg) : Nil
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

    def mapped(&mapper : Msg -> Msg) : Dispatcher
      Dispatcher.new(@mailbox, self, mapper)
    end
  end

  # Batch performs a bunch of commands concurrently with no ordering guarantees.
  # Use a Batch to return several commands from Init or Update.
  #
  # ```
  # def init : Term2::Cmd
  #   Term2.batch(load_data_cmd, start_timer_cmd)
  # end
  # ```
  def self.batch(*cmds : Cmd) : Cmd
    Cmds.batch(*cmds)
  end

  # Sequence runs the given commands one at a time, in order.
  # Contrast this with Batch, which runs commands concurrently.
  def self.sequence(*cmds : Cmd) : Cmd
    Cmds.sequence(*cmds)
  end

  # Quit is a command that tells the program to exit.
  def self.quit : Cmd
    Cmds.quit
  end

  # RequestCapability is a command that requests the terminal to send its
  # Termcap/Terminfo response for the given capability.
  #
  # Bubble Tea recognizes the following capabilities and will use them to
  # upgrade the program's color profile:
  #   - "RGB" Xterm direct color
  #   - "Tc" True color support
  #
  # Note: that some terminal's like Apple's Terminal.app do not support this and
  # will send the wrong response to the terminal breaking the program's output.
  #
  # When the Bubble Tea advertises a non-TrueColor profile, you can use this
  # command to query the terminal for its color capabilities. Example:
  #
  #   case msg
  #   when Term2::ColorProfileMsg
  #     if msg.profile != Lipgloss::ColorProfile::TrueColor
  #       return m, Term2.batch(
  #         Term2.request_capability("RGB"),
  #         Term2.request_capability("Tc"),
  #       )
  #     end
  #   end
  def self.request_capability(capability : String) : Cmd
    Cmds.request_capability(capability)
  end

  def self.request_background_color : Cmd
    Cmds.request_background_color
  end

  def self.request_foreground_color : Cmd
    Cmds.request_foreground_color
  end

  def self.request_cursor_color : Cmd
    Cmds.request_cursor_color
  end

  # Alias for request_capability to match Bubble Tea's naming convention.
  # Note: Crystal method names are typically lowercase; use request_capability.
  # RequestCapability = ->request_capability(String)

  module Cmds
    # No-op command (nil)
    def self.none : ::Term2::Cmd
      nil
    end

    # Immediately emit a single message.
    def self.message(msg : Msg) : ::Term2::Cmd
      -> { msg.as(Msg?) }
    end

    # Run several commands concurrently.
    def self.batch(*cmds : ::Term2::Cmd) : ::Term2::Cmd
      normalized = cmds.to_a.compact
      return none if normalized.empty?
      return normalized.first if normalized.size == 1

      safe_cmds = normalized.map do |cmd|
        -> { cmd.call.as(Msg?) }
      end
      -> { BatchMsg.new(safe_cmds).as(Msg?) }
    end

    # Run commands sequentially.
    def self.sequence(*cmds : ::Term2::Cmd) : ::Term2::Cmd
      normalized = cmds.to_a.compact
      return none if normalized.empty?
      return normalized.first if normalized.size == 1

      safe_cmds = normalized.map do |cmd|
        -> { cmd.call.as(Msg?) }
      end
      -> { SequenceMsg.new(safe_cmds).as(Msg?) }
    end

    # Run several commands concurrently - array version.
    def self.batch(cmds : Array(::Term2::Cmd?)) : ::Term2::Cmd
      normalized = cmds.compact
      return none if normalized.empty?
      return normalized.first if normalized.size == 1

      safe_cmds = normalized.map do |cmd|
        -> { cmd.call.as(Msg?) }
      end
      -> { BatchMsg.new(safe_cmds).as(Msg?) }
    end

    # Run commands sequentially - array version.
    def self.sequence(cmds : Array(::Term2::Cmd?)) : ::Term2::Cmd
      normalized = cmds.compact
      return none if normalized.empty?
      return normalized.first if normalized.size == 1

      safe_cmds = normalized.map do |cmd|
        -> { cmd.call.as(Msg?) }
      end
      -> { SequenceMsg.new(safe_cmds).as(Msg?) }
    end

    # Map the result of a command.
    def self.map(cmd : ::Term2::Cmd, &block : Msg -> Msg?) : ::Term2::Cmd
      return none unless cmd
      -> {
        msg = cmd.call
        msg ? block.call(msg) : nil
      }
    end

    # Every is a command that ticks after a duration.
    # Like Bubble Tea, this sends a single message - to tick repeatedly,
    # return another Every command from your update function.
    def self.every(duration : Time::Span, &block : Time -> Msg?) : ::Term2::Cmd
      -> {
        sleep duration
        block.call(Time.utc).as(Msg?)
      }
    end

    # Tick sends a message after a duration (alias for every).
    def self.tick(duration : Time::Span, &block : Time -> Msg?) : ::Term2::Cmd
      every(duration, &block)
    end

    # Schedule a message after a duration.
    def self.after(duration : Time::Span, msg : Msg) : ::Term2::Cmd
      -> {
        CML.sync(CML.timeout(duration)) unless duration <= Time::Span.zero
        msg.as(Msg?)
      }
    end

    def self.after(duration : Time::Span, &block : -> Msg?) : ::Term2::Cmd
      -> {
        CML.sync(CML.timeout(duration)) unless duration <= Time::Span.zero
        block.call.as(Msg?)
      }
    end

    def self.deadline(target : Time, msg : Msg) : ::Term2::Cmd
      span = duration_until(target)
      after(span, msg)
    end

    def self.deadline(target : Time, &block : -> Msg?) : ::Term2::Cmd
      span = duration_until(target)
      after(span, &block)
    end

    def self.timeout(duration : Time::Span, timeout_message : Msg, &block : -> Msg?) : ::Term2::Cmd
      -> {
        result_ch = Channel(Msg?).new

        # Spawn the work
        spawn do
          result_ch.send(block.call)
        end

        # Race between work and timeout
        select
        when msg = result_ch.receive
          msg.as(Msg?)
        when timeout(duration)
          timeout_message.as(Msg?)
        end
      }
    end

    def self.from_event(evt : CML::Event(Msg)) : ::Term2::Cmd
      -> {
        CML.sync(evt).as(Msg?)
      }
    end

    def self.perform(&block : -> Msg?) : ::Term2::Cmd
      -> { block.call.as(Msg?) }
    end

    def self.quit : ::Term2::Cmd
      message(QuitMsg.new)
    end

    def self.interrupt : ::Term2::Cmd
      message(QuitMsg.new)
    end

    def self.suspend : ::Term2::Cmd
      message(SuspendMsg.new)
    end

    # Internal/terminal related helper constructors mirror the
    # old Cmd API for convenience.
    def self.enter_alt_screen : ::Term2::Cmd
      message(EnterAltScreenMsg.new)
    end

    def self.exit_alt_screen : ::Term2::Cmd
      message(ExitAltScreenMsg.new)
    end

    def self.show_cursor : ::Term2::Cmd
      message(ShowCursorMsg.new)
    end

    def self.hide_cursor : ::Term2::Cmd
      message(HideCursorMsg.new)
    end

    def self.clear_screen : ::Term2::Cmd
      message(ClearScreenMsg.new)
    end

    def self.window_title=(title : String) : ::Term2::Cmd
      message(SetWindowTitleMsg.new(title))
    end

    def self.window_size : ::Term2::Cmd
      message(RequestWindowSizeMsg.new)
    end

    def self.read_clipboard : ::Term2::Cmd
      message(ReadClipboardMsg.new)
    end

    def self.read_primary_clipboard : ::Term2::Cmd
      message(ReadPrimaryClipboardMsg.new)
    end

    def self.set_clipboard(text : String) : ::Term2::Cmd
      message(SetClipboardMsg.new(text))
    end

    def self.set_primary_clipboard(text : String) : ::Term2::Cmd
      message(SetPrimaryClipboardMsg.new(text))
    end

    def self.request_foreground_color : ::Term2::Cmd
      message(RequestForegroundColorMsg.new)
    end

    def self.request_background_color : ::Term2::Cmd
      message(RequestBackgroundColorMsg.new)
    end

    def self.request_cursor_color : ::Term2::Cmd
      message(RequestCursorColorMsg.new)
    end

    def self.println(text : String) : ::Term2::Cmd
      message(PrintMsg.new(text + "\n"))
    end

    def self.printf(format : String, *args) : ::Term2::Cmd
      message(PrintMsg.new(sprintf(format, *args)))
    end

    def self.enable_mouse_cell_motion : ::Term2::Cmd
      message(EnableMouseCellMotionMsg.new)
    end

    def self.enable_mouse_all_motion : ::Term2::Cmd
      message(EnableMouseAllMotionMsg.new)
    end

    def self.disable_mouse_tracking : ::Term2::Cmd
      message(DisableMouseTrackingMsg.new)
    end

    def self.enable_bracketed_paste : ::Term2::Cmd
      message(EnableBracketedPasteMsg.new)
    end

    def self.disable_bracketed_paste : ::Term2::Cmd
      message(DisableBracketedPasteMsg.new)
    end

    def self.enable_report_focus : ::Term2::Cmd
      message(EnableReportFocusMsg.new)
    end

    def self.disable_report_focus : ::Term2::Cmd
      message(DisableReportFocusMsg.new)
    end

    # RequestCapability is a command that requests the terminal to send its
    # Termcap/Terminfo response for the given capability.
    #
    # Bubble Tea recognizes the following capabilities and will use them to
    # upgrade the program's color profile:
    #   - "RGB" Xterm direct color
    #   - "Tc" True color support
    #
    # Note: that some terminal's like Apple's Terminal.app do not support this and
    # will send the wrong response to the terminal breaking the program's output.
    #
    # When the Bubble Tea advertises a non-TrueColor profile, you can use this
    # command to query the terminal for its color capabilities. Example:
    #
    #   case msg
    #   when Term2::ColorProfileMsg
    #     if msg.profile != Lipgloss::ColorProfile::TrueColor
    #       return m, Term2.batch(
    #         Term2::Cmds.request_capability("RGB"),
    #         Term2::Cmds.request_capability("Tc"),
    #       )
    #     end
    #   end
    def self.request_capability(capability : String) : ::Term2::Cmd
      message(RequestCapabilityMsg.new(capability))
    end

    private def self.duration_until(target : Time) : Time::Span
      span = target - Time.utc
      span > Time::Span.zero ? span : Time::Span.zero
    end
  end
end
