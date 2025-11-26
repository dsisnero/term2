require "../term2"
require "./key"

module Term2
  module Bubbles
    class Help < Model
      module KeyMap
        abstract def short_help : Array(Key::Binding)
        abstract def full_help : Array(Array(Key::Binding))
      end

      property? show_all : Bool = false
      property width : Int32 = 80

      # Styles
      property key_style : Style = Style.new(faint: true)
      property desc_style : Style = Style.new(faint: true)
      property separator_style : Style = Style.new(faint: true)

      def initialize
      end

      def view(key_map : KeyMap) : String
        if @show_all
          view_full(key_map)
        else
          view_short(key_map)
        end
      end

      def view_short(key_map : KeyMap) : String
        bindings = key_map.short_help
        return "" if bindings.empty?

        parts = bindings.compact_map do |binding|
          next if !binding.enabled?
          "#{key_style.apply(binding.help_key)} #{desc_style.apply(binding.help_desc)}"
        end

        parts.join(separator_style.apply(" • "))
      end

      def view_full(key_map : KeyMap) : String
        groups = key_map.full_help

        lines = [] of String
        groups.each do |group|
          group.each do |binding|
            next if !binding.enabled?
            lines << "#{key_style.apply(binding.help_key)}    #{desc_style.apply(binding.help_desc)}"
          end
          lines << "" unless lines.empty? || lines.last.empty?
        end

        lines.join("\n").chomp
      end
    end
  end
end
