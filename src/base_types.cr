# Base types for Term2
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
end
