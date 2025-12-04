require "../term2"

module Term2
  module Components
    module Key
      # Configuration proc used to build bindings (parity with Bubbles options API)
      alias BindingOpt = Proc(Binding, Nil)

      # Help contains the key and description for a key binding
      struct Help
        getter key : String
        getter desc : String

        def initialize(@key : String, @desc : String)
        end
      end

      # Binding describes a set of keybindings and their associated help text
      class Binding
        property keys : Array(String)
        property help : Help
        property? disabled : Bool

        def initialize(@keys : Array(String) = [] of String, @help : Help = Help.new("", ""), @disabled : Bool = false)
        end

        # Option-style initializer (mirrors Bubbles Binding options)
        def self.new(*opts : BindingOpt)
          binding = Binding.new
          opts.each(&.call(binding))
          binding
        end

        # Create a new binding with keys and help
        def self.new(keys : Array(String), help_key : String, help_desc : String, disabled : Bool = false)
          new(keys, Help.new(help_key, help_desc), disabled)
        end

        def help_key : String
          @help.key
        end

        def help_desc : String
          @help.desc
        end

        # Check if the binding is enabled
        def enabled? : Bool
          !@disabled && !@keys.empty?
        end

        def set_enabled(value : Bool)
          @disabled = !value
        end

        def enabled=(value : Bool)
          set_enabled(value)
        end

        def set_keys(*keys : String)
          @keys = keys.to_a
        end

        def set_help(key : String, desc : String)
          @help = Help.new(key, desc)
        end

        # Clear keys and help (beyond disabling)
        def unbind
          @keys = [] of String
          @help = Help.new("", "")
        end

        # Check if the given message matches this binding
        def matches?(msg : Term2::KeyMsg) : Bool
          return false if @disabled
          @keys.includes?(msg.key.to_s)
        end
      end

      # Option helpers (mirroring the Go API)
      def self.with_keys(*keys : String) : BindingOpt
        ->(b : Binding) { b.keys = keys.to_a }
      end

      def self.with_help(key : String, desc : String) : BindingOpt
        ->(b : Binding) { b.help = Help.new(key, desc) }
      end

      def self.with_disabled : BindingOpt
        ->(b : Binding) { b.disabled = true }
      end
    end
  end
end
