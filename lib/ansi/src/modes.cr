module Ansi
  class Modes
    def initialize
      @values = Hash(Mode, ModeSetting).new
    end

    def [](mode : Mode) : ModeSetting
      get(mode)
    end

    def []=(mode : Mode, setting : ModeSetting) : ModeSetting
      @values[mode] = setting
    end

    def get(mode : Mode) : ModeSetting
      @values[mode]? || ModeSetting::ModeNotRecognized
    end

    def delete(mode : Mode)
      @values.delete(mode)
    end

    def set(*modes : Mode)
      modes.each do |mode|
        @values[mode] = ModeSetting::ModeSet
      end
    end

    def permanently_set(*modes : Mode)
      modes.each do |mode|
        @values[mode] = ModeSetting::ModePermanentlySet
      end
    end

    def reset(*modes : Mode)
      modes.each do |mode|
        @values[mode] = ModeSetting::ModeReset
      end
    end

    def permanently_reset(*modes : Mode)
      modes.each do |mode|
        @values[mode] = ModeSetting::ModePermanentlyReset
      end
    end

    # ameba:disable Naming/PredicateName
    def is_set(mode : Mode) : Bool
      get(mode).is_set
    end

    # ameba:disable Naming/PredicateName
    def is_permanently_set(mode : Mode) : Bool
      get(mode).is_permanently_set
    end

    # ameba:disable Naming/PredicateName
    def is_reset(mode : Mode) : Bool
      get(mode).is_reset
    end

    # ameba:disable Naming/PredicateName
    def is_permanently_reset(mode : Mode) : Bool
      get(mode).is_permanently_reset
    end
  end
end
