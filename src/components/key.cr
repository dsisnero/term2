require "../term2"

module Term2
  module Components
    module Key
      # Helper methods to match Bubble Tea's API style
      def self.with_keys(*keys : String) : Array(String)
        keys.to_a
      end

      def self.with_help(key : String, desc : String) : Help
        Help.new(key, desc)
      end

      # Help contains the key and description for a key binding
      struct Help
        getter key : String
        getter desc : String

        def initialize(@key : String, @desc : String)
        end
      end

      # Binding describes a set of keybindings and their associated help text
      class Binding
        getter keys : Array(String)
        getter help : Help
        property? disabled : Bool

        def initialize(@keys : Array(String), @help : Help, @disabled : Bool = false)
        end

        def self.new(keys : Array(String))
          new(keys, Help.new("", ""))
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
          !@disabled
        end

        # Set the enabled state explicitly.
        def enabled=(v : Bool) : Bool
          @disabled = !v
          v
        end

        def set_enabled(v : Bool) : Nil
          self.enabled = v
        end

        def unbind
          @disabled = true
        end

        # Check if the given message matches this binding
        def matches?(msg : UV::Key) : Bool
          return false if @disabled
          @keys.any? { |key| msg.match_string(key) || msg.string == key }
        end
      end
    end
  end
end
