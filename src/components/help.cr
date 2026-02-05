require "../term2"
require "./key"

module Term2
  module Components
    class Help
      include Model

      module KeyMap
        abstract def short_help : Array(Key::Binding)
        abstract def full_help : Array(Array(Key::Binding))

        def self.bindings(entries : Array(NamedTuple(keys: Array(String), help: String, description: String))) : Array(Key::Binding)
          entries.map do |entry|
            Key::Binding.new(entry[:keys], entry[:help], entry[:description])
          end
        end

        def self.bindings(entries : Array(Tuple(Array(String), String, String))) : Array(Key::Binding)
          entries.map do |entry|
            Key::Binding.new(entry[0], entry[1], entry[2])
          end
        end
      end

      property? show_all : Bool = false
      property width : Int32 = 80

      # Styles
      property key_style : Lipgloss::Style = Lipgloss::Style.new.faint(true)
      property desc_style : Lipgloss::Style = Lipgloss::Style.new.faint(true)
      property separator_style : Lipgloss::Style = Lipgloss::Style.new.faint(true)
      property ellipsis_style : Lipgloss::Style = Lipgloss::Style.new
      property full_separator : String = "  "
      property ellipsis : String = "…"

      def initialize
      end

      def update(msg : Msg) : {Help, Cmd}
        {self, Cmds.none}
      end

      def view : View
        View.new(content: "")
      end

      def view(key_map : KeyMap) : View
        if @show_all
          view_full(key_map)
        else
          view_short(key_map)
        end
      end

      def view_short(key_map : KeyMap) : View
        bindings = key_map.short_help
        return View.new(content: "") if bindings.empty?

        sep = separator_style.inline(true).render(" • ")
        total_width = 0

        parts = [] of String
        bindings.each_with_index do |binding, idx|
          next unless binding.enabled?

          item = "#{key_style.inline(true).render(binding.help_key)} #{desc_style.inline(true).render(binding.help_desc)}"
          item = sep + item if total_width > 0 && idx < bindings.size

          w = Lipgloss::Text.width(item)
          tail, ok = should_add_item(total_width, w)
          unless ok
            parts << tail unless tail.empty?
            break
          end

          total_width += w
          parts << item
        end

        View.new(content: parts.join(""))
      end

      def view_full(key_map : KeyMap) : View
        groups = key_map.full_help
        return View.new(content: "") if groups.empty?

        blocks = [] of String
        total_width = 0
        separator = separator_style.inline(true).render(@full_separator)

        groups.each_with_index do |group, idx|
          next if group.nil? || group.empty? || !should_render_column?(group)

          sep = total_width > 0 && idx < groups.size ? separator : ""

          keys = [] of String
          descs = [] of String

          group.each do |binding|
            next unless binding.enabled?
            keys << binding.help_key
            descs << binding.help_desc
          end

          col = Lipgloss::Style.join_horizontal(
            Lipgloss::Position::Top,
            [
              sep,
              key_style.render(keys.join("\n")),
              " ",
              desc_style.render(descs.join("\n")),
            ]
          )

          w = Lipgloss::Text.width(col)
          tail, ok = should_add_item(total_width, w)
          unless ok
            blocks << tail unless tail.empty?
            break
          end

          total_width += w
          blocks << col
        end

        View.new(content: Lipgloss::Style.join_horizontal(Lipgloss::Position::Top, blocks))
      end

      private def should_add_item(total_width : Int32, width : Int32) : {String, Bool}
        if @width > 0 && total_width + width > @width
          tail = " " + ellipsis_style.inline(true).render(@ellipsis)
          return {tail, false} if total_width + Lipgloss::Text.width(tail) < @width
        end
        {"", true}
      end

      private def should_render_column?(bindings : Array(Key::Binding)) : Bool
        bindings.any?(&.enabled?)
      end
    end
  end
end
