module Term2
  module TestHelpers
    def self.uv_key(value : String) : UV::Key
      mod = 0
      code = 0
      text = ""

      value.split('+').each do |part|
        if mod_flag = UV::MOD_KEYWORDS[part]?
          mod |= mod_flag
          next
        end

        if key_type = UV::STRING_KEY_TYPE[part]?
          code = key_type
          next
        end

        if part.each_char.count { true } == 1
          char = part.each_char.first
          code = char.ord
          text = char.to_s
        else
          code = UV::KeyExtended
          text = part
        end
      end

      # UV only populates text for printable chars when no non-shift modifiers are set.
      unless (mod & ~(UV::ModShift | UV::ModCapsLock)) == 0
        text = ""
      end

      UV::Key.new(text: text, mod: mod, code: code)
    end

    def self.uv_key(value : Char) : UV::Key
      UV::Key.new(text: value.to_s, code: value.ord)
    end

    def self.uv_key(code : Int32) : UV::Key
      UV::Key.new(code: code)
    end

    def self.uv_mouse(x : Int32, y : Int32, button : UV::MouseButton, mod : UV::KeyMod = 0) : UV::Mouse
      UV::Mouse.new(x: x, y: y, button: button, mod: mod)
    end

    def self.mouse_click(x : Int32, y : Int32, button : UV::MouseButton = UV::MouseButton::Left, mod : UV::KeyMod = 0) : UV::MouseClickEvent
      UV::MouseClickEvent.new(uv_mouse(x, y, button, mod))
    end

    def self.mouse_release(x : Int32, y : Int32, button : UV::MouseButton = UV::MouseButton::Left, mod : UV::KeyMod = 0) : UV::MouseReleaseEvent
      UV::MouseReleaseEvent.new(uv_mouse(x, y, button, mod))
    end

    def self.mouse_wheel(x : Int32, y : Int32, button : UV::MouseButton, mod : UV::KeyMod = 0) : UV::MouseWheelEvent
      UV::MouseWheelEvent.new(uv_mouse(x, y, button, mod))
    end

    def self.mouse_motion(x : Int32, y : Int32, button : UV::MouseButton = UV::MouseButton::None, mod : UV::KeyMod = 0) : UV::MouseMotionEvent
      UV::MouseMotionEvent.new(uv_mouse(x, y, button, mod))
    end

    def self.mouse_event(
      x : Int32,
      y : Int32,
      button : UV::MouseButton,
      action : Symbol,
      *,
      alt : Bool = false,
      ctrl : Bool = false,
      shift : Bool = false
    ) : UVMouseEvent
      mod = 0
      mod |= UV::ModAlt if alt
      mod |= UV::ModCtrl if ctrl
      mod |= UV::ModShift if shift

      case action
      when :press
        if wheel_button?(button)
          mouse_wheel(x, y, button, mod)
        else
          mouse_click(x, y, button, mod)
        end
      when :release
        mouse_release(x, y, button, mod)
      when :drag
        mouse_motion(x, y, button, mod)
      else
        mouse_motion(x, y, button, mod)
      end
    end

    private def self.wheel_button?(button : UV::MouseButton) : Bool
      button == UV::MouseButton::WheelUp ||
        button == UV::MouseButton::WheelDown ||
        button == UV::MouseButton::WheelLeft ||
        button == UV::MouseButton::WheelRight
    end

    def self.key_msg(key : UV::Key) : UV::Key
      key
    end

    def self.key_msg(value : String) : UV::Key
      uv_key(value)
    end

    def self.key_msg(value : Char) : UV::Key
      uv_key(value)
    end

    def self.key_msg(value : Int32) : UV::Key
      uv_key(value)
    end
  end
end
