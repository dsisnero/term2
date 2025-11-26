require "../term2"

module Term2
  module Bubbles
    module Key
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

        # Check if the given message matches this binding
        def matches?(msg : Term2::KeyMsg) : Bool
          return false if @disabled
          @keys.includes?(msg.key.to_s)
        end
      end
    end
  end
end
