# Base types for Term2
#
# Mirrors Bubble Tea's core types as closely as possible:
#
#   Go (Bubble Tea)              Crystal (Term2)
#   ---------------              ---------------
#   type Msg interface{}         alias Msg = Message
#   type Cmd func() Msg          alias Cmd = (-> Msg)?
#   type Model interface {       module Model
#     Init() Cmd                   def init : Cmd
#     Update(Msg) (Model, Cmd)     def update(msg) : {Model, Cmd}
#     View() string                def view : String
#   }                            end
#
require "cml"
require "cml/mailbox"

module Term2
  # Msg is any message that can be sent to the update function.
  # In Go this is `interface{}` (any type). In Crystal we use
  # a base class that all messages inherit from.
  abstract class Message
  end

  alias Msg = Message

  # Cmd is an IO operation that returns a message when it's complete.
  # If it's nil it's considered a no-op.
  #
  # In Go: `type Cmd func() Msg`
  # In Crystal: `alias Cmd = (-> Msg)?`
  alias Cmd = (Proc(Msg) | Proc(Msg?))?

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
  #     when Term2::KeyMsg
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

    # View renders the program's UI, which is just a string. The view is
    # rendered after every Update.
    abstract def view : String

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
  class BatchMsg < Message
    getter cmds : Array(-> Msg?)

    def initialize(cmds)
      @cmds = cmds.map { |c| -> : Msg? { c.call.as?(Msg) } }
    end
  end

  # SequenceMsg is used internally to run commands in order.
  class SequenceMsg < Message
    getter cmds : Array(-> Msg?)

    def initialize(cmds)
      @cmds = cmds.map { |c| -> : Msg? { c.call.as?(Msg) } }
    end
  end

  # Key contains information about a keypress.
  #
  # Keys can represent:
  # - Regular characters (type == KeyType::Runes)
  # - Special keys like arrows, function keys (type == KeyType::Up, etc.)
  # - Control combinations (type == KeyType::CtrlC, etc.)
  # - Alt combinations (alt? == true)
  # - Pasted text (paste? == true)
  #
  # ```
  # case msg
  # when Term2::KeyMsg
  #   key = msg.key
  #   case key.to_s
  #   when "q" # quit
  #  then
  #   when "ctrl+c" # also quit
  #  then
  #   when "up" # move up
  #  then
  #   end
  # end
  # ```
  struct Key
    # The type of key (special key or Runes for regular characters)
    getter type : KeyType
    # The characters for this key (for KeyType::Runes)
    getter runes : Array(Char)
    # Whether Alt was held
    getter? alt : Bool
    # Whether this key came from a paste operation
    getter? paste : Bool

    def initialize(@type : KeyType, @runes : Array(Char) = [] of Char, @alt : Bool = false, @paste : Bool = false)
    end

    def initialize(char : Char, alt : Bool = false)
      @type = KeyType::Runes
      @runes = [char]
      @alt = alt
      @paste = false
    end

    def initialize(str : String, alt : Bool = false)
      @type = KeyType::Runes
      @runes = str.chars
      @alt = alt
      @paste = false
    end

    def initialize(runes : Array(Char), alt : Bool = false, paste : Bool = false)
      @type = KeyType::Runes
      @runes = runes
      @alt = alt
      @paste = paste
    end

    # Returns a friendly string representation for a key
    def to_s : String
      String.build do |str|
        str << "alt+" if @alt
        if @type == KeyType::Runes
          if @paste
            str << '['
            @runes.each { |rune| str << rune }
            str << ']'
          else
            @runes.each { |rune| str << rune }
          end
        else
          str << KEY_NAMES[@type]?
        end
      end
    end

    def ==(other : Key) : Bool
      to_s == other.to_s
    end

    # Check if this key matches a given string representation
    def matches?(pattern : String) : Bool
      to_s == pattern
    end

    # Check if this is a specific key type
    def type?(key_type : KeyType) : Bool
      @type == key_type
    end

    # Get the first rune (for single character keys)
    def rune : Char?
      @runes.first?
    end
  end

  # KeyType indicates the type of key pressed.
  #
  # Most key types represent special keys (arrows, function keys, etc.).
  # For regular character input, `KeyType::Runes` is used and the actual
  # characters are stored in `Key#runes`.
  #
  # ### Control Keys
  # Control key combinations (Ctrl+A through Ctrl+Z) have their own types
  # and numeric values corresponding to ASCII control codes.
  #
  # ### Navigation Keys
  # - Arrow keys: `Up`, `Down`, `Left`, `Right`
  # - With modifiers: `CtrlUp`, `ShiftUp`, `CtrlShiftUp`, etc.
  # - Page navigation: `PgUp`, `PgDown`, `Home`, `End`
  #
  # ### Function Keys
  # F1 through F20 are supported.
  #
  # ### Focus Events
  # `FocusIn` and `FocusOut` represent terminal focus changes when
  # focus reporting is enabled.
  enum KeyType
    # Control keys
    Null      =   0 # null, \0
    Break     =   3 # break, ctrl+c
    Enter     =  13 # carriage return, \r
    Backspace = 127 # delete/backspace
    Tab       =   9 # horizontal tabulation, \t
    Esc       =  27 # escape, \e
    Escape    =  27 # alias for Esc

    # Control key aliases
    CtrlAt           =   0 # ctrl+@
    CtrlA            =   1
    CtrlB            =   2
    CtrlC            =   3
    CtrlD            =   4
    CtrlE            =   5
    CtrlF            =   6
    CtrlG            =   7
    CtrlH            =   8
    CtrlI            =   9
    CtrlJ            =  10
    CtrlK            =  11
    CtrlL            =  12
    CtrlM            =  13
    CtrlN            =  14
    CtrlO            =  15
    CtrlP            =  16
    CtrlQ            =  17
    CtrlR            =  18
    CtrlS            =  19
    CtrlT            =  20
    CtrlU            =  21
    CtrlV            =  22
    CtrlW            =  23
    CtrlX            =  24
    CtrlY            =  25
    CtrlZ            =  26
    CtrlOpenBracket  =  27 # ctrl+[
    CtrlBackslash    =  28 # ctrl+\
    CtrlCloseBracket =  29 # ctrl+]
    CtrlCaret        =  30 # ctrl+^
    CtrlUnderscore   =  31 # ctrl+_
    CtrlQuestionMark = 127 # ctrl+?

    # Other keys
    Runes
    Up
    Down
    Right
    Left
    ShiftTab
    Home
    End
    PgUp
    PgDown
    CtrlPgUp
    CtrlPgDown
    Delete
    Insert
    Space
    CtrlUp
    CtrlDown
    CtrlRight
    CtrlLeft
    CtrlHome
    CtrlEnd
    ShiftUp
    ShiftDown
    ShiftRight
    ShiftLeft
    ShiftHome
    ShiftEnd
    CtrlShiftUp
    CtrlShiftDown
    CtrlShiftLeft
    CtrlShiftRight
    CtrlShiftHome
    CtrlShiftEnd
    F1
    F2
    F3
    F4
    F5
    F6
    F7
    F8
    F9
    F10
    F11
    F12
    F13
    F14
    F15
    F16
    F17
    F18
    F19
    F20
    FocusIn
    FocusOut

    def to_s : String
      KEY_NAMES[self]? || ""
    end
  end

  # Human-readable names for key types.
  #
  # Maps `KeyType` enum values to their string representations used
  # in `Key#to_s` and for matching in `Key#matches?`.
  #
  # ```
  # Term2::KEY_NAMES[KeyType::CtrlC] # => "ctrl+c"
  # Term2::KEY_NAMES[KeyType::Up]    # => "up"
  # Term2::KEY_NAMES[KeyType::F1]    # => "f1"
  # ```
  KEY_NAMES = {
    # Control keys
    KeyType::Null             => "ctrl+@",
    KeyType::CtrlA            => "ctrl+a",
    KeyType::CtrlB            => "ctrl+b",
    KeyType::CtrlC            => "ctrl+c",
    KeyType::CtrlD            => "ctrl+d",
    KeyType::CtrlE            => "ctrl+e",
    KeyType::CtrlF            => "ctrl+f",
    KeyType::CtrlG            => "ctrl+g",
    KeyType::CtrlH            => "ctrl+h",
    KeyType::Tab              => "tab",
    KeyType::CtrlJ            => "ctrl+j",
    KeyType::CtrlK            => "ctrl+k",
    KeyType::CtrlL            => "ctrl+l",
    KeyType::Enter            => "enter",
    KeyType::CtrlN            => "ctrl+n",
    KeyType::CtrlO            => "ctrl+o",
    KeyType::CtrlP            => "ctrl+p",
    KeyType::CtrlQ            => "ctrl+q",
    KeyType::CtrlR            => "ctrl+r",
    KeyType::CtrlS            => "ctrl+s",
    KeyType::CtrlT            => "ctrl+t",
    KeyType::CtrlU            => "ctrl+u",
    KeyType::CtrlV            => "ctrl+v",
    KeyType::CtrlW            => "ctrl+w",
    KeyType::CtrlX            => "ctrl+x",
    KeyType::CtrlY            => "ctrl+y",
    KeyType::CtrlZ            => "ctrl+z",
    KeyType::Esc              => "esc",
    KeyType::CtrlBackslash    => "ctrl+\\",
    KeyType::CtrlCloseBracket => "ctrl+]",
    KeyType::CtrlCaret        => "ctrl+^",
    KeyType::CtrlUnderscore   => "ctrl+_",
    KeyType::Backspace        => "backspace",

    # Other keys
    KeyType::Runes          => "runes",
    KeyType::Up             => "up",
    KeyType::Down           => "down",
    KeyType::Right          => "right",
    KeyType::Left           => "left",
    KeyType::ShiftTab       => "shift+tab",
    KeyType::Home           => "home",
    KeyType::End            => "end",
    KeyType::CtrlHome       => "ctrl+home",
    KeyType::CtrlEnd        => "ctrl+end",
    KeyType::ShiftHome      => "shift+home",
    KeyType::ShiftEnd       => "shift+end",
    KeyType::CtrlShiftHome  => "ctrl+shift+home",
    KeyType::CtrlShiftEnd   => "ctrl+shift+end",
    KeyType::PgUp           => "pgup",
    KeyType::PgDown         => "pgdown",
    KeyType::CtrlPgUp       => "ctrl+pgup",
    KeyType::CtrlPgDown     => "ctrl+pgdown",
    KeyType::Delete         => "delete",
    KeyType::Insert         => "insert",
    KeyType::Space          => " ",
    KeyType::CtrlUp         => "ctrl+up",
    KeyType::CtrlDown       => "ctrl+down",
    KeyType::CtrlRight      => "ctrl+right",
    KeyType::CtrlLeft       => "ctrl+left",
    KeyType::ShiftUp        => "shift+up",
    KeyType::ShiftDown      => "shift+down",
    KeyType::ShiftRight     => "shift+right",
    KeyType::ShiftLeft      => "shift+left",
    KeyType::CtrlShiftUp    => "ctrl+shift+up",
    KeyType::CtrlShiftDown  => "ctrl+shift+down",
    KeyType::CtrlShiftLeft  => "ctrl+shift+left",
    KeyType::CtrlShiftRight => "ctrl+shift+right",
    KeyType::F1             => "f1",
    KeyType::F2             => "f2",
    KeyType::F3             => "f3",
    KeyType::F4             => "f4",
    KeyType::F5             => "f5",
    KeyType::F6             => "f6",
    KeyType::F7             => "f7",
    KeyType::F8             => "f8",
    KeyType::F9             => "f9",
    KeyType::F10            => "f10",
    KeyType::F11            => "f11",
    KeyType::F12            => "f12",
    KeyType::F13            => "f13",
    KeyType::F14            => "f14",
    KeyType::F15            => "f15",
    KeyType::F16            => "f16",
    KeyType::F17            => "f17",
    KeyType::F18            => "f18",
    KeyType::F19            => "f19",
    KeyType::F20            => "f20",
    KeyType::FocusIn        => "focus_in",
    KeyType::FocusOut       => "focus_out",
  }

  # Internal message that signals the program should terminate.
  # Use `Cmds.quit` to send this message.
  class QuitMsg < Message
  end

  # Message to enter alternate screen mode.
  # Use `Cmds.enter_alt_screen` to send this message.
  class EnterAltScreenMsg < Message
  end

  # Message to exit alternate screen mode.
  # Use `Cmds.exit_alt_screen` to send this message.
  class ExitAltScreenMsg < Message
  end

  # Message to suspend the program (parity with Bubble Tea).
  # Use `Cmds.suspend` to send this message.
  class SuspendMsg < Message
  end

  # Message sent when program resumes after a suspend.
  class ResumeMsg < Message
  end

  # Message to interrupt (parity with Bubble Tea).
  class InterruptMsg < Message
  end

  # Message to show the cursor.
  # Use `Cmds.show_cursor` to send this message.
  class ShowCursorMsg < Message
  end

  # Message to hide the cursor.
  # Use `Cmds.hide_cursor` to send this message.
  class HideCursorMsg < Message
  end

  # Message sent when the terminal window gains focus.
  # Only received if focus reporting is enabled via `program.enable_focus_reporting`.
  class FocusMsg < Message
    def ==(other : FocusMsg) : Bool
      true
    end
  end

  # Message sent when the terminal window loses focus.
  # Only received if focus reporting is enabled via `program.enable_focus_reporting`.
  class BlurMsg < Message
    def ==(other : BlurMsg) : Bool
      true
    end
  end

  # Message sent when a zone receives focus via tab navigation.
  # Contains the zone ID that should receive focus.
  class ZoneFocusMsg < Message
    getter zone_id : String

    def initialize(@zone_id : String)
    end
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

  # Raised when program is killed.
  class ProgramKilled < Exception
  end

  # Raised when the program panics (uncaught exception) and recovery is enabled.
  class ProgramPanic < Exception
  end

  # ClearScreenMsg signals a request to clear the screen
  class ClearScreenMsg < Message
  end

  # SetWindowTitleMsg signals a request to set the terminal window title
  class SetWindowTitleMsg < Message
    getter title : String

    def initialize(@title : String)
    end
  end

  # RequestWindowSizeMsg signals a request for the current window size
  class RequestWindowSizeMsg < Message
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

  # EnableBracketedPasteMsg signals enabling bracketed paste mode
  class EnableBracketedPasteMsg < Message
  end

  # DisableBracketedPasteMsg signals disabling bracketed paste mode
  class DisableBracketedPasteMsg < Message
  end

  # EnableReportFocusMsg signals enabling focus reporting
  class EnableReportFocusMsg < Message
  end

  # DisableReportFocusMsg signals disabling focus reporting
  class DisableReportFocusMsg < Message
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

    def ==(other : KeyMsg) : Bool
      @key == other.key
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

  module Cmds
    # No-op command (nil)
    def self.none : ::Term2::Cmd
      nil
    end

    # Immediately emit a single message.
    def self.message(msg : Msg) : ::Term2::Cmd
      -> : Msg? { msg.as(Msg) }
    end

    # Run several commands concurrently.
    def self.batch : ::Term2::Cmd
      none
    end

    def self.batch(*cmds : ::Term2::Cmd) : ::Term2::Cmd
      normalized = cmds.to_a.compact
      return none if normalized.empty?
      return normalized.first if normalized.size == 1

      -> : Msg? { BatchMsg.new(normalized).as(Msg) }
    end

    # Accept enumerable collections of Cmd (e.g., arrays)
    def self.batch(cmds : Enumerable(::Term2::Cmd)) : ::Term2::Cmd
      normalized = cmds.to_a.compact
      return none if normalized.empty?
      return normalized.first if normalized.size == 1

      -> : Msg? { BatchMsg.new(normalized).as(Msg) }
    end

    # Run commands sequentially.
    def self.sequence : ::Term2::Cmd
      none
    end

    def self.sequence(*cmds : ::Term2::Cmd) : ::Term2::Cmd
      normalized = cmds.to_a.compact
      return none if normalized.empty?
      return normalized.first if normalized.size == 1

      -> : Msg? { SequenceMsg.new(normalized).as(Msg) }
    end

    def self.sequence(cmds : Enumerable(::Term2::Cmd)) : ::Term2::Cmd
      normalized = cmds.to_a.compact
      return none if normalized.empty?
      return normalized.first if normalized.size == 1

      -> : Msg? { SequenceMsg.new(normalized).as(Msg) }
    end

    # Sequentially executes commands in order, returning the first non-nil message.
    # Mirrors Bubble Tea's Sequentially helper.
    def self.sequentially(*cmds : ::Term2::Cmd) : ::Term2::Cmd
      normalized = cmds.to_a.compact
      return none if normalized.empty?

      -> {
        normalized.each do |cmd|
          next unless cmd
          if msg = cmd.call
            return msg
          end
        end
        nil
      }
    end

    def self.sequentially(cmds : Array(::Term2::Cmd)) : ::Term2::Cmd
      normalized = cmds.compact
      return none if normalized.empty?
      -> {
        normalized.each do |cmd|
          next unless cmd
          if msg = cmd.call
            return msg
          end
        end
        nil
      }
    end

    # Map the result of a command.
    def self.map(cmd : ::Term2::Cmd, &block : Msg -> Msg) : ::Term2::Cmd
      return none unless cmd
      -> : Msg? {
        msg = cmd.call
        return unless msg
        block.call(msg)
      }
    end

    # Every is a command that ticks after a duration.
    # Like Bubble Tea, this sends a single message - to tick repeatedly,
    # return another Every command from your update function.
    def self.every(duration : Time::Span, &block : Time -> Msg) : ::Term2::Cmd
      return none if duration <= Time::Span.zero
      -> : Msg? {
        CML.sync(CML.timeout(duration))
        block.call(Time.utc)
      }
    end

    # Tick sends a message after a duration (alias for every).
    def self.tick(duration : Time::Span, &block : Time -> Msg) : ::Term2::Cmd
      every(duration, &block)
    end

    # Schedule a message after a duration.
    def self.after(duration : Time::Span, msg : Msg) : ::Term2::Cmd
      -> : Msg? {
        CML.sync(CML.timeout(duration)) unless duration <= Time::Span.zero
        msg.as(Msg)
      }
    end

    def self.after(duration : Time::Span, &block : -> Msg) : ::Term2::Cmd
      -> : Msg? {
        CML.sync(CML.timeout(duration)) unless duration <= Time::Span.zero
        block.call.as(Msg)
      }
    end

    def self.deadline(target : Time, msg : Msg) : ::Term2::Cmd
      span = duration_until(target)
      after(span, msg)
    end

    def self.deadline(target : Time, &block : -> Msg) : ::Term2::Cmd
      span = duration_until(target)
      after(span, &block)
    end

    def self.timeout(duration : Time::Span, timeout_message : Msg, &block : -> Msg) : ::Term2::Cmd
      -> : Msg? {
        result_ch = Channel(Msg).new

        # Spawn the work
        spawn do
          result_ch.send(block.call)
        end

        # Race between work and timeout
        select
        when msg = result_ch.receive
          msg
        when timeout(duration)
          timeout_message
        end
      }
    end

    def self.from_event(evt : CML::Event(Msg)) : ::Term2::Cmd
      -> : Msg? {
        CML.sync(evt)
      }
    end

    def self.perform(&block : -> Msg) : ::Term2::Cmd
      -> : Msg? { block.call }
    end

    def self.quit : ::Term2::Cmd
      message(QuitMsg.new)
    end

    # Internal/terminal related helper constructors mirror the
    # old Cmd API for convenience.
    def self.enter_alt_screen : ::Term2::Cmd
      message(EnterAltScreenMsg.new)
    end

    def self.exit_alt_screen : ::Term2::Cmd
      message(ExitAltScreenMsg.new)
    end

    def self.suspend : ::Term2::Cmd
      message(SuspendMsg.new)
    end

    def self.resume : ::Term2::Cmd
      message(ResumeMsg.new)
    end

    def self.interrupt : ::Term2::Cmd
      message(InterruptMsg.new)
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

    private def self.duration_until(target : Time) : Time::Span
      span = target - Time.utc
      span > Time::Span.zero ? span : Time::Span.zero
    end
  end
end
