# Base types for Term2
require "cml"
require "cml/mailbox"

module Term2
  # Base class for application state.
  #
  # Your application's model must inherit from this class.
  # The model represents all of your application's state.
  #
  # ```
  # class MyModel < Term2::Model
  #   getter count : Int32
  #   getter name : String
  #
  #   def initialize(@count = 0, @name = "")
  #   end
  # end
  # ```
  abstract class Model
    # Init is the first function that will be called. It returns an optional
    # initial command. To not perform an initial command return `Cmd.none`.
    def init : Cmd
      Cmd.none
    end

    # Update is called when a message is received. Use it to inspect the
    # message and, in response, update the model and/or send a command.
    abstract def update(msg : Message) : {Model, Cmd}

    # View renders the program's UI, which is just a string. The view is
    # rendered after every update.
    abstract def view : String
  end

  # Base class for all messages in the system.
  #
  # Messages are the only way to update your model. They represent
  # events like key presses, mouse clicks, timers, or custom events.
  #
  # ```
  # class IncrementMsg < Term2::Message
  # end
  #
  # class SetNameMsg < Term2::Message
  #   getter name : String
  #
  #   def initialize(@name); end
  # end
  # ```
  abstract class Message
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
  end

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

    # Clear the screen and move cursor to home position
    def self.clear_screen : self
      message(ClearScreenMsg.new)
    end

    # Set the terminal window title
    def self.window_title=(title : String) : self
      message(SetWindowTitleMsg.new(title))
    end

    # Request the current window size (results in WindowSizeMsg)
    def self.window_size : self
      message(RequestWindowSizeMsg.new)
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

    # Enable bracketed paste mode
    def self.enable_bracketed_paste : self
      message(EnableBracketedPasteMsg.new)
    end

    # Disable bracketed paste mode
    def self.disable_bracketed_paste : self
      message(DisableBracketedPasteMsg.new)
    end

    # Enable focus reporting
    def self.enable_report_focus : self
      message(EnableReportFocusMsg.new)
    end

    # Disable focus reporting
    def self.disable_report_focus : self
      message(DisableReportFocusMsg.new)
    end

    private def self.duration_until(target : Time) : Time::Span
      span = target - Time.utc
      span > Time::Span.zero ? span : Time::Span.zero
    end
  end
end
