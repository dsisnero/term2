require "./base_types"

# Key sequence definitions for terminal input parsing
module Term2
  # KeySequences contains mappings from terminal escape sequences to Key objects
  module KeySequences
    # Constants used for testing and sequence detection
    FOCUS_IN_SEQ  = "\e[I"
    FOCUS_OUT_SEQ = "\e[O"

    # Kitty keyboard protocol constants
    KITTY_SHIFT     = 1 << 0
    KITTY_ALT       = 1 << 1
    KITTY_CTRL      = 1 << 2
    KITTY_SUPER     = 1 << 3
    KITTY_HYPER     = 1 << 4
    KITTY_META      = 1 << 5
    KITTY_CAPS_LOCK = 1 << 6
    KITTY_NUM_LOCK  = 1 << 7

    # Map numeric key codes from CSI u to KeyType
    NUMERIC_KEY_MAP = {
      # Arrow keys (CSI A, B, C, D)
      65 => KeyType::Up,    # 'A'
      66 => KeyType::Down,  # 'B'
      67 => KeyType::Right, # 'C'
      68 => KeyType::Left,  # 'D'

      # Function keys (CSI 11~, 12~, etc.) - approximate mapping
      # F1-F12 codes would need proper mapping

      # Special keys from Kitty protocol (partial)
       27 => KeyType::Esc,       # Escape
        9 => KeyType::Tab,       # Tab
       13 => KeyType::Enter,     # Enter
      127 => KeyType::Backspace, # Backspace

      # Home/End/PgUp/PgDown
      72 => KeyType::Home,   # H (CSI H)
      70 => KeyType::End,    # F (CSI F)
      53 => KeyType::PgUp,   # 5 (CSI 5~)
      54 => KeyType::PgDown, # 6 (CSI 6~)

      # Insert/Delete
      50 => KeyType::Insert, # 2 (CSI 2~)
      51 => KeyType::Delete, # 3 (CSI 3~)
    }

    private def self.kitty_mod_to_key_mod(kitty_mod : Int32) : KeyMod
      mod = KeyMod::None
      mod |= KeyMod::Shift if kitty_mod & KITTY_SHIFT != 0
      mod |= KeyMod::Alt if kitty_mod & KITTY_ALT != 0
      mod |= KeyMod::Ctrl if kitty_mod & KITTY_CTRL != 0
      mod |= KeyMod::Super if kitty_mod & KITTY_SUPER != 0
      mod |= KeyMod::Hyper if kitty_mod & KITTY_HYPER != 0
      mod |= KeyMod::Meta if kitty_mod & KITTY_META != 0
      mod |= KeyMod::CapsLock if kitty_mod & KITTY_CAPS_LOCK != 0
      mod |= KeyMod::NumLock if kitty_mod & KITTY_NUM_LOCK != 0
      mod
    end

    private def self.parse_csi_u(seq : Bytes, length : Int32) : Term2::Msg?
      # seq is the entire sequence including \e[ and terminator 'u'
      # length is the total length in bytes
      return if length < 4 # \e[ X u minimum
      return unless seq[length - 1] == 'u'.ord

      # Parse parameters: skip \e[ (2 bytes)
      param_start = 2
      is_keyboard_enhancement = false
      # Skip private mode indicator '?'
      if seq[param_start]? == '?'.ord
        param_start += 1
        is_keyboard_enhancement = true
      end
      param_end = length - 1 # before 'u'

      # Split parameters by ';'
      params = [] of Array(Int32)
      current_param = [] of Int32
      current_value = 0

      i = param_start
      while i < param_end
        b = seq[i]
        if b == ';'.ord
          current_param << current_value
          params << current_param
          current_param = [] of Int32
          current_value = 0
        elsif b == ':'.ord
          current_param << current_value
          current_value = 0
        elsif b >= '0'.ord && b <= '9'.ord
          current_value = current_value * 10 + (b - '0'.ord)
        else
          # Invalid character
          return
        end
        i += 1
      end

      # Add last parameter
      if current_value > 0 || !current_param.empty?
        current_param << current_value
        params << current_param unless current_param.empty?
      end

      # Handle keyboard enhancement response: \e[ ? flags u
      if is_keyboard_enhancement
        # This is a keyboard enhancement response
        # Format: \e[?flags;paramu where flags is first parameter, param second
        # Go test expects flags from second parameter.
        flags = params.size > 1 ? params[1][0]? || 0 : 0
        return KeyboardEnhancementsMsg.new(flags)
      end

      # Parse as key event
      # Basic format: \e[ codepoint ; modifiers u
      # Extended format: \e[ unicode:shifted:base ; modifiers:event_type ; text u

      if params.empty?
        return
      end

      # First parameter: key code
      key_code = params[0][0]? || 0

      # Second parameter: modifiers (default 1)
      modifiers = params.size > 1 ? params[1][0]? || 1 : 1

      # Third parameter: event type (if present in subparams)
      event_type = 1 # default: press
      is_repeat = false
      is_release = false

      if params.size > 1 && params[1].size > 1
        # modifiers:event_type format
        event_type = params[1][1]? || 1
        case event_type
        when 2
          is_repeat = true
        when 3
          is_release = true
        end
      end

      # Build key with modifiers
      mod = kitty_mod_to_key_mod(modifiers - 1) # Kitty mods are offset by 1

      # Check for shifted/base codes in first parameter subparams
      shifted_code = nil
      base_code = nil
      if params[0].size > 1
        shifted_code = params[0][1]?.try(&.unsafe_chr)
      end
      if params[0].size > 2
        base_code = params[0][2]?.try(&.unsafe_chr)
      end

      # Text from third parameter if present
      text = ""
      if params.size > 2
        params[2].each do |cp|
          text += cp.unsafe_chr if cp > 0
        end
      end

      # Create key based on key code
      key = if NUMERIC_KEY_MAP.has_key?(key_code)
              # Special key
              key_type = NUMERIC_KEY_MAP[key_code]
              Key.new(key_type, alt: mod.contains?(KeyMod::Alt), mod: mod,
                is_repeat: is_repeat, shifted_code: shifted_code, base_code: base_code)
            elsif key_code > 0 && key_code < 128 && text.empty?
              # Printable ASCII character
              Key.new(key_code.unsafe_chr, alt: mod.contains?(KeyMod::Alt), mod: mod,
                is_repeat: is_repeat, shifted_code: shifted_code, base_code: base_code)
            elsif !text.empty?
              # Use text from third parameter
              Key.new(text, alt: mod.contains?(KeyMod::Alt), mod: mod,
                is_repeat: is_repeat, shifted_code: shifted_code, base_code: base_code)
            else
              # Unknown key code, fallback to rune representation
              Key.new(key_code.unsafe_chr, alt: mod.contains?(KeyMod::Alt), mod: mod,
                is_repeat: is_repeat, shifted_code: shifted_code, base_code: base_code)
            end

      if is_release
        KeyReleaseMsg.new(key)
      else
        KeyPressMsg.new(key)
      end
    end

    private def self.parse_dcs(seq : Bytes, length : Int32) : Term2::Msg?
      # seq is the entire DCS sequence including \eP and terminator \e\
      # length is total length in bytes
      return if length < 5 # \eP X \e\ minimum
      return unless seq[0] == 0x1b && seq[1] == 'P'.ord
      return unless seq[length - 2] == 0x1b && seq[length - 1] == '\\'.ord

      # Skip \eP (2 bytes)
      i = 2
      # Skip parameter bytes (digits, ';', ':')
      while i < length - 2 && seq[i] >= '0'.ord && seq[i] <= ';'.ord
        i += 1
      end
      # Skip intermediate bytes (0x20-0x2F)
      while i < length - 2 && seq[i] >= 0x20 && seq[i] <= 0x2F
        i += 1
      end
      # Final byte must be in 0x40-0x7E
      return if i >= length - 2
      final_byte = seq[i]
      return unless final_byte >= 0x40 && final_byte <= 0x7E

      # Data starts after final byte
      data_start = i + 1
      data_end = length - 2 # before ESC \
      return if data_start >= data_end

      # Extract hex data (for XTGETTCAP)
      data = seq[data_start...data_end]
      content = String.new(data)
      CapabilityMsg.new(content)
    end

    # Sequence mappings for terminal escape sequences
    SEQUENCES = {
      # Arrow keys
      "\e[A" => Key.new(KeyType::Up),
      "\e[B" => Key.new(KeyType::Down),
      "\e[C" => Key.new(KeyType::Right),
      "\e[D" => Key.new(KeyType::Left),
      "\eOA" => Key.new(KeyType::Up),    # Powershell / vt100
      "\eOB" => Key.new(KeyType::Down),  # Powershell / vt100
      "\eOC" => Key.new(KeyType::Right), # Powershell / vt100
      "\eOD" => Key.new(KeyType::Left),  # Powershell / vt100

      # Shift + Arrow
      "\e[1;2A" => Key.new(KeyType::ShiftUp),
      "\e[1;2B" => Key.new(KeyType::ShiftDown),
      "\e[1;2C" => Key.new(KeyType::ShiftRight),
      "\e[1;2D" => Key.new(KeyType::ShiftLeft),
      "\e[OA"   => Key.new(KeyType::ShiftUp),    # DECCKM
      "\e[OB"   => Key.new(KeyType::ShiftDown),  # DECCKM
      "\e[OC"   => Key.new(KeyType::ShiftRight), # DECCKM
      "\e[OD"   => Key.new(KeyType::ShiftLeft),  # DECCKM
      "\e[a"    => Key.new(KeyType::ShiftUp),    # urxvt
      "\e[b"    => Key.new(KeyType::ShiftDown),  # urxvt
      "\e[c"    => Key.new(KeyType::ShiftRight), # urxvt
      "\e[d"    => Key.new(KeyType::ShiftLeft),  # urxvt

      # Alt + Arrow
      "\e[1;3A" => Key.new(KeyType::Up, alt: true),
      "\e[1;3B" => Key.new(KeyType::Down, alt: true),
      "\e[1;3C" => Key.new(KeyType::Right, alt: true),
      "\e[1;3D" => Key.new(KeyType::Left, alt: true),

      # Alt + Shift + Arrow
      "\e[1;4A" => Key.new(KeyType::ShiftUp, alt: true),
      "\e[1;4B" => Key.new(KeyType::ShiftDown, alt: true),
      "\e[1;4C" => Key.new(KeyType::ShiftRight, alt: true),
      "\e[1;4D" => Key.new(KeyType::ShiftLeft, alt: true),

      # Control keys with modifiers
      "\e[1;5A" => Key.new(KeyType::CtrlUp),
      "\e[1;5B" => Key.new(KeyType::CtrlDown),
      "\e[1;5C" => Key.new(KeyType::CtrlRight),
      "\e[1;5D" => Key.new(KeyType::CtrlLeft),
      "\e[Oa"   => Key.new(KeyType::CtrlUp, alt: true),    # urxvt
      "\e[Ob"   => Key.new(KeyType::CtrlDown, alt: true),  # urxvt
      "\e[Oc"   => Key.new(KeyType::CtrlRight, alt: true), # urxvt
      "\e[Od"   => Key.new(KeyType::CtrlLeft, alt: true),  # urxvt

      # Ctrl + Shift + Arrow
      "\e[1;6A" => Key.new(KeyType::CtrlShiftUp),
      "\e[1;6B" => Key.new(KeyType::CtrlShiftDown),
      "\e[1;6C" => Key.new(KeyType::CtrlShiftRight),
      "\e[1;6D" => Key.new(KeyType::CtrlShiftLeft),

      # Ctrl + Alt + Arrow
      "\e[1;7A" => Key.new(KeyType::CtrlUp, alt: true),
      "\e[1;7B" => Key.new(KeyType::CtrlDown, alt: true),
      "\e[1;7C" => Key.new(KeyType::CtrlRight, alt: true),
      "\e[1;7D" => Key.new(KeyType::CtrlLeft, alt: true),

      # Ctrl + Shift + Alt + Arrow
      "\e[1;8A" => Key.new(KeyType::CtrlShiftUp, alt: true),
      "\e[1;8B" => Key.new(KeyType::CtrlShiftDown, alt: true),
      "\e[1;8C" => Key.new(KeyType::CtrlShiftRight, alt: true),
      "\e[1;8D" => Key.new(KeyType::CtrlShiftLeft, alt: true),

      # Miscellaneous keys
      "\e[Z" => Key.new(KeyType::ShiftTab),

      "\e[2~"   => Key.new(KeyType::Insert),
      "\e[3;2~" => Key.new(KeyType::Insert, alt: true),

      "\e[3~"   => Key.new(KeyType::Delete),
      "\e[3;3~" => Key.new(KeyType::Delete, alt: true),

      "\e[5~"   => Key.new(KeyType::PgUp),
      "\e[5;3~" => Key.new(KeyType::PgUp, alt: true),
      "\e[5;5~" => Key.new(KeyType::CtrlPgUp),
      "\e[5^"   => Key.new(KeyType::CtrlPgUp), # urxvt
      "\e[5;7~" => Key.new(KeyType::CtrlPgUp, alt: true),

      "\e[6~"   => Key.new(KeyType::PgDown),
      "\e[6;3~" => Key.new(KeyType::PgDown, alt: true),
      "\e[6;5~" => Key.new(KeyType::CtrlPgDown),
      "\e[6^"   => Key.new(KeyType::CtrlPgDown), # urxvt
      "\e[6;7~" => Key.new(KeyType::CtrlPgDown, alt: true),

      "\e[1~"   => Key.new(KeyType::Home),
      "\e[H"    => Key.new(KeyType::Home),
      "\e[1;3H" => Key.new(KeyType::Home, alt: true),
      "\e[1;5H" => Key.new(KeyType::CtrlHome),
      "\e[1;7H" => Key.new(KeyType::CtrlHome, alt: true),
      "\e[1;2H" => Key.new(KeyType::ShiftHome),
      "\e[1;4H" => Key.new(KeyType::ShiftHome, alt: true),
      "\e[1;6H" => Key.new(KeyType::CtrlShiftHome),
      "\e[1;8H" => Key.new(KeyType::CtrlShiftHome, alt: true),

      "\e[4~"   => Key.new(KeyType::End),
      "\e[F"    => Key.new(KeyType::End),
      "\e[1;3F" => Key.new(KeyType::End, alt: true),
      "\e[1;5F" => Key.new(KeyType::CtrlEnd),
      "\e[1;7F" => Key.new(KeyType::CtrlEnd, alt: true),
      "\e[1;2F" => Key.new(KeyType::ShiftEnd),
      "\e[1;4F" => Key.new(KeyType::ShiftEnd, alt: true),
      "\e[1;6F" => Key.new(KeyType::CtrlShiftEnd),
      "\e[1;8F" => Key.new(KeyType::CtrlShiftEnd, alt: true),

      "\e[7~" => Key.new(KeyType::Home),          # urxvt
      "\e[7^" => Key.new(KeyType::CtrlHome),      # urxvt
      "\e[7$" => Key.new(KeyType::ShiftHome),     # urxvt
      "\e[7@" => Key.new(KeyType::CtrlShiftHome), # urxvt

      "\e[8~" => Key.new(KeyType::End),          # urxvt
      "\e[8^" => Key.new(KeyType::CtrlEnd),      # urxvt
      "\e[8$" => Key.new(KeyType::ShiftEnd),     # urxvt
      "\e[8@" => Key.new(KeyType::CtrlShiftEnd), # urxvt

      # Function keys
      "\e[[A" => Key.new(KeyType::F1), # linux console
      "\e[[B" => Key.new(KeyType::F2), # linux console
      "\e[[C" => Key.new(KeyType::F3), # linux console
      "\e[[D" => Key.new(KeyType::F4), # linux console
      "\e[[E" => Key.new(KeyType::F5), # linux console

      "\eOP" => Key.new(KeyType::F1),
      "\eOQ" => Key.new(KeyType::F2),
      "\eOR" => Key.new(KeyType::F3),
      "\eOS" => Key.new(KeyType::F4),

      "\e[1;3P" => Key.new(KeyType::F1, alt: true),
      "\e[1;3Q" => Key.new(KeyType::F2, alt: true),
      "\e[1;3R" => Key.new(KeyType::F3, alt: true),
      "\e[1;3S" => Key.new(KeyType::F4, alt: true),

      "\e[11~" => Key.new(KeyType::F1), # urxvt
      "\e[12~" => Key.new(KeyType::F2), # urxvt
      "\e[13~" => Key.new(KeyType::F3), # urxvt
      "\e[14~" => Key.new(KeyType::F4), # urxvt

      "\e[15~"   => Key.new(KeyType::F5),
      "\e[15;3~" => Key.new(KeyType::F5, alt: true),

      "\e[17~" => Key.new(KeyType::F6),
      "\e[18~" => Key.new(KeyType::F7),
      "\e[19~" => Key.new(KeyType::F8),
      "\e[20~" => Key.new(KeyType::F9),
      "\e[21~" => Key.new(KeyType::F10),

      "\e[17;3~" => Key.new(KeyType::F6, alt: true),
      "\e[18;3~" => Key.new(KeyType::F7, alt: true),
      "\e[19;3~" => Key.new(KeyType::F8, alt: true),
      "\e[20;3~" => Key.new(KeyType::F9, alt: true),
      "\e[21;3~" => Key.new(KeyType::F10, alt: true),

      "\e[23~" => Key.new(KeyType::F11),
      "\e[24~" => Key.new(KeyType::F12),

      "\e[23;3~" => Key.new(KeyType::F11, alt: true),
      "\e[24;3~" => Key.new(KeyType::F12, alt: true),

      "\e[1;2P" => Key.new(KeyType::F13),
      "\e[1;2Q" => Key.new(KeyType::F14),

      "\e[25~" => Key.new(KeyType::F13),
      "\e[26~" => Key.new(KeyType::F14),

      "\e[25;3~" => Key.new(KeyType::F13, alt: true),
      "\e[26;3~" => Key.new(KeyType::F14, alt: true),

      "\e[1;2R" => Key.new(KeyType::F15),
      "\e[1;2S" => Key.new(KeyType::F16),

      "\e[28~" => Key.new(KeyType::F15),
      "\e[29~" => Key.new(KeyType::F16),

      "\e[28;3~" => Key.new(KeyType::F15, alt: true),
      "\e[29;3~" => Key.new(KeyType::F16, alt: true),

      "\e[15;2~" => Key.new(KeyType::F17),
      "\e[17;2~" => Key.new(KeyType::F18),
      "\e[18;2~" => Key.new(KeyType::F19),
      "\e[19;2~" => Key.new(KeyType::F20),

      "\e[31~" => Key.new(KeyType::F17),
      "\e[32~" => Key.new(KeyType::F18),
      "\e[33~" => Key.new(KeyType::F19),
      "\e[34~" => Key.new(KeyType::F20),

      # Alt+key combinations
      "\e "  => Key.new(' ', alt: true),
      "\e!"  => Key.new('!', alt: true),
      "\e\"" => Key.new('"', alt: true),
      "\e#"  => Key.new('#', alt: true),
      "\e$"  => Key.new('$', alt: true),
      "\e%"  => Key.new('%', alt: true),
      "\e&"  => Key.new('&', alt: true),
      "\e'"  => Key.new('\'', alt: true),
      "\e("  => Key.new('(', alt: true),
      "\e)"  => Key.new(')', alt: true),
      "\e*"  => Key.new('*', alt: true),
      "\e+"  => Key.new('+', alt: true),
      "\e,"  => Key.new(',', alt: true),
      "\e-"  => Key.new('-', alt: true),
      "\e."  => Key.new('.', alt: true),
      "\e/"  => Key.new('/', alt: true),
      "\e0"  => Key.new('0', alt: true),
      "\e1"  => Key.new('1', alt: true),
      "\e2"  => Key.new('2', alt: true),
      "\e3"  => Key.new('3', alt: true),
      "\e4"  => Key.new('4', alt: true),
      "\e5"  => Key.new('5', alt: true),
      "\e6"  => Key.new('6', alt: true),
      "\e7"  => Key.new('7', alt: true),
      "\e8"  => Key.new('8', alt: true),
      "\e9"  => Key.new('9', alt: true),
      "\e:"  => Key.new(':', alt: true),
      "\e;"  => Key.new(';', alt: true),
      "\e<"  => Key.new('<', alt: true),
      "\e="  => Key.new('=', alt: true),
      "\e>"  => Key.new('>', alt: true),
      "\e?"  => Key.new('?', alt: true),
      "\e@"  => Key.new('@', alt: true),
      "\eA"  => Key.new('A', alt: true),
      "\eB"  => Key.new('B', alt: true),
      "\eC"  => Key.new('C', alt: true),
      "\eD"  => Key.new('D', alt: true),
      "\eE"  => Key.new('E', alt: true),
      "\eF"  => Key.new('F', alt: true),
      "\eG"  => Key.new('G', alt: true),
      "\eH"  => Key.new('H', alt: true),
      "\eI"  => Key.new('I', alt: true),
      "\eJ"  => Key.new('J', alt: true),
      "\eK"  => Key.new('K', alt: true),
      "\eL"  => Key.new('L', alt: true),
      "\eM"  => Key.new('M', alt: true),
      "\eN"  => Key.new('N', alt: true),
      "\eO"  => Key.new('O', alt: true),
      "\eP"  => Key.new('P', alt: true),
      "\eQ"  => Key.new('Q', alt: true),
      "\eR"  => Key.new('R', alt: true),
      "\eS"  => Key.new('S', alt: true),
      "\eT"  => Key.new('T', alt: true),
      "\eU"  => Key.new('U', alt: true),
      "\eV"  => Key.new('V', alt: true),
      "\eW"  => Key.new('W', alt: true),
      "\eX"  => Key.new('X', alt: true),
      "\eY"  => Key.new('Y', alt: true),
      "\eZ"  => Key.new('Z', alt: true),
      # "\e[" is a prefix for longer sequences, not a complete sequence
      "\e\\" => Key.new('\\', alt: true),
      "\e]"  => Key.new(']', alt: true),
      "\e^"  => Key.new('^', alt: true),
      "\e_"  => Key.new('_', alt: true),
      "\e`"  => Key.new('`', alt: true),
      "\ea"  => Key.new('a', alt: true),
      "\eb"  => Key.new('b', alt: true),
      "\ec"  => Key.new('c', alt: true),
      "\ed"  => Key.new('d', alt: true),
      "\ee"  => Key.new('e', alt: true),
      "\ef"  => Key.new('f', alt: true),
      "\eg"  => Key.new('g', alt: true),
      "\eh"  => Key.new('h', alt: true),
      "\ei"  => Key.new('i', alt: true),
      "\ej"  => Key.new('j', alt: true),
      "\ek"  => Key.new('k', alt: true),
      "\el"  => Key.new('l', alt: true),
      "\em"  => Key.new('m', alt: true),
      "\en"  => Key.new('n', alt: true),
      "\eo"  => Key.new('o', alt: true),
      "\ep"  => Key.new('p', alt: true),
      "\eq"  => Key.new('q', alt: true),
      "\er"  => Key.new('r', alt: true),
      "\es"  => Key.new('s', alt: true),
      "\et"  => Key.new('t', alt: true),
      "\eu"  => Key.new('u', alt: true),
      "\ev"  => Key.new('v', alt: true),
      "\ew"  => Key.new('w', alt: true),
      "\ex"  => Key.new('x', alt: true),
      "\ey"  => Key.new('y', alt: true),
      "\ez"  => Key.new('z', alt: true),
      "\e{"  => Key.new('{', alt: true),
      "\e|"  => Key.new('|', alt: true),
      "\e}"  => Key.new('}', alt: true),
      "\e~"  => Key.new('~', alt: true),
    }

    # Lazy-initialized prefix set for fast prefix lookups
    @@prefixes : Set(String)? = nil

    private def self.build_prefixes : Set(String)
      prefixes = Set(String).new
      SEQUENCES.keys.each do |seq|
        (1...seq.size).each do |len|
          prefixes << seq[0, len]
        end
      end
      prefixes
    end

    private def self.prefixes : Set(String)
      @@prefixes ||= build_prefixes
    end

    # Get all known sequences
    def self.sequences : Hash(String, Key)
      SEQUENCES
    end

    # Find a key for a given sequence
    def self.find(sequence : String) : Key?
      return Key.new(KeyType::FocusIn) if sequence == FOCUS_IN_SEQ
      return Key.new(KeyType::FocusOut) if sequence == FOCUS_OUT_SEQ
      SEQUENCES[sequence]?
    end

    # Check if a sequence is a prefix of any known sequence
    def self.prefix?(sequence : String) : Bool
      prefixes.includes?(sequence)
    end

    # Get all sequences that start with the given prefix
    def self.sequences_with_prefix(prefix : String) : Array(String)
      SEQUENCES.keys.select(&.starts_with?(prefix))
    end

    # Detects if the given bytes contain a complete key sequence at the start.
    # Returns {has_sequence, width_in_bytes, message}
    def self.detect_sequence(data : Bytes) : {Bool, Int32, Term2::Msg?}
      return {false, 0, nil} if data.empty?

      # Meta (Alt) prefix: leading ESC before another sequence
      if data.size >= 2 && data[0] == 0x1b && data[1] == 0x1b
        sub = data[1, data.size - 1]
        has, width, nested_msg = detect_sequence(sub)
        if has
          alt_msg = case nested_msg
                    when KeyMsg
                      k = nested_msg.key
                      KeyMsg.new(Key.new(k.type, k.runes, alt: true))
                    else
                      nested_msg
                    end
          return {true, width + 1, alt_msg}
        end
      end

      # 1. Check Control Characters (0x00-0x1F) excluding ESC (0x1b), and DEL (0x7F)
      byte = data[0]
      if byte <= 0x1F && byte != 0x1b
        k = Key.new(KeyType.new(byte.to_i))
        return {true, 1, KeyMsg.new(k)}
      elsif byte == 0x7F
        k = Key.new(KeyType::Backspace)
        return {true, 1, KeyMsg.new(k)}
      elsif byte == 0x1b
        # Focus reporting sequences
        if data.size == FOCUS_IN_SEQ.bytesize && data[0, FOCUS_IN_SEQ.bytesize] == FOCUS_IN_SEQ.to_slice
          return {true, FOCUS_IN_SEQ.bytesize, FocusMsg.new}
        elsif data.size == FOCUS_OUT_SEQ.bytesize && data[0, FOCUS_OUT_SEQ.bytesize] == FOCUS_OUT_SEQ.to_slice
          return {true, FOCUS_OUT_SEQ.bytesize, BlurMsg.new}
        end

        if data.size == 1
          k = Key.new(KeyType::Esc)
          return {true, 1, KeyMsg.new(k)}
        end

        # Check for DCS (Device Control String) starting with ESC P
        if data.size >= 3 && data[1] == 'P'.ord
          # DCS format: ESC P <intermediate> <parameter>... <data> ESC \
          # For XTGETTCAP responses: ESC P 1 + r <hexdata> ESC \
          # We'll scan for terminator ESC \
          i = 2 # Skip ESC P
          while i < data.size
            if data[i] == 0x1b && i + 1 < data.size && data[i + 1] == '\\'.ord
              # Found terminator
              seq = data[0, i + 2]
              if msg = parse_dcs(seq, i + 2)
                return {true, i + 2, msg}
              else
                # Fallback: return raw content as CapabilityMsg
                content = String.new(seq[2...i]) # Skip ESC P and terminator
                return {true, i + 2, CapabilityMsg.new(content)}
              end
            end
            i += 1
          end
          # Incomplete DCS sequence
          return {false, 0, nil}
        end

        # 3. Check known sequences
        # Limit check to max sequence length to avoid excessive string allocation
        check_len = [data.size, 16].min
        check_str = String.new(data[0, check_len])

        best_len = 0
        best_key = nil

        SEQUENCES.each do |seq, key|
          if check_str.starts_with?(seq)
            if seq.size > best_len
              best_len = seq.size
              best_key = key
            end
          end
        end

        if best_key && best_len > 0
          return {true, best_len, KeyMsg.new(best_key)}
        end

        # 4. Check for Alt+Key (Esc + Char)
        # BubbleTea: if data[1] is not '[' or 'O', treat as Alt+Key.
        if data.size >= 2
          b2 = data[1]
          if b2 != '['.ord && b2 != 'O'.ord
            # Decode rune
            slice = data[1, data.size - 1]
            begin
              s = String.new(slice)
              if s.size > 0
                char = s[0]
                char_len = char.bytesize
                # Construct Alt Key
                k = if char.control?
                      if char.ord == 127
                        Key.new(KeyType::Backspace, alt: true)
                      else
                        Key.new(KeyType.new(char.ord), alt: true)
                      end
                    else
                      Key.new(char, alt: true)
                    end
                return {true, 1 + char_len, KeyMsg.new(k)}
              end
            rescue
              # conversion failed
            end
          end
        end

        # 5. Check for Unknown CSI (\e[ ... )
        if data.size >= 2 && data[1] == '['.ord
          # Scan for terminator 0x40-0x7E
          i = 2
          while i < data.size
            b = data[i]
            if b >= 0x40 && b <= 0x7E
              # Found it
              seq = data[0, i + 1]
              # Check for CSI u (Kitty keyboard protocol or keyboard enhancements)
              if b == 'u'.ord
                if msg = parse_csi_u(seq, i + 1)
                  return {true, i + 1, msg}
                end
              end
              return {true, i + 1, UnknownCSISequenceMsg.new(seq)}
            end
            i += 1
          end
        end
      else
        # 6. Plain runes
        begin
          s = String.new(data)
          if s.size > 0
            char = s[0]
            return {true, char.bytesize, KeyMsg.new(Key.new(char))}
          end
        rescue
        end
      end

      {false, 0, nil}
    end

    # Detects a single message from the byte buffer (sequence or rune).
    def self.detect_one_msg(data : Bytes) : {Bool, Int32, Term2::Msg?}
      has, width, msg = detect_sequence(data)
      if has
        converted = case msg
                    when KeyMsg
                      if msg.key.type == KeyType::FocusIn
                        FocusMsg.new
                      elsif msg.key.type == KeyType::FocusOut
                        BlurMsg.new
                      else
                        msg
                      end
                    else
                      msg
                    end
        return {has, width, converted}
      end

      return {false, 0, nil} if data.empty?

      # Try to decode a rune
      begin
        s = String.new(data)
        if s.size > 0
          char = s[0]
          return {true, char.bytesize, KeyMsg.new(Key.new(char))}
        end
      rescue
      end

      {false, 0, nil}
    end
  end
end
