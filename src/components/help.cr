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

      # Styles for the help bubble (v2‑exp API)
      struct Styles
        property ellipsis : Lipgloss::Style

        # Styling for the short help
        property short_key : Lipgloss::Style
        property short_desc : Lipgloss::Style
        property short_separator : Lipgloss::Style

        # Styling for the full help
        property full_key : Lipgloss::Style
        property full_desc : Lipgloss::Style
        property full_separator : Lipgloss::Style

        def initialize(
          @ellipsis = Lipgloss::Style.new,
          @short_key = Lipgloss::Style.new.faint(true),
          @short_desc = Lipgloss::Style.new.faint(true),
          @short_separator = Lipgloss::Style.new.faint(true),
          @full_key = Lipgloss::Style.new.faint(true),
          @full_desc = Lipgloss::Style.new.faint(true),
          @full_separator = Lipgloss::Style.new.faint(true),
        )
        end

        def self.default_dark : Styles
          key_color = Lipgloss::Color.from_hex("#626262")
          desc_color = Lipgloss::Color.from_hex("#4A4A4A")
          sep_color = Lipgloss::Color.from_hex("#3C3C3C")

          Styles.new(
            ellipsis: Lipgloss::Style.new.foreground(sep_color),
            short_key: Lipgloss::Style.new.foreground(key_color),
            short_desc: Lipgloss::Style.new.foreground(desc_color),
            short_separator: Lipgloss::Style.new.foreground(sep_color),
            full_key: Lipgloss::Style.new.foreground(key_color),
            full_desc: Lipgloss::Style.new.foreground(desc_color),
            full_separator: Lipgloss::Style.new.foreground(sep_color)
          )
        end

        def self.default_light : Styles
          key_color = Lipgloss::Color.from_hex("#909090")
          desc_color = Lipgloss::Color.from_hex("#B2B2B2")
          sep_color = Lipgloss::Color.from_hex("#DADADA")

          Styles.new(
            ellipsis: Lipgloss::Style.new.foreground(sep_color),
            short_key: Lipgloss::Style.new.foreground(key_color),
            short_desc: Lipgloss::Style.new.foreground(desc_color),
            short_separator: Lipgloss::Style.new.foreground(sep_color),
            full_key: Lipgloss::Style.new.foreground(key_color),
            full_desc: Lipgloss::Style.new.foreground(desc_color),
            full_separator: Lipgloss::Style.new.foreground(sep_color)
          )
        end
      end

      property? show_all : Bool = false
      property width : Int32 = 80

      # Styles (v2‑exp API)
      property styles : Styles = Styles.default_dark

      # Separators and ellipsis
      property short_separator : String = " • "
      property full_separator : String = "  "
      property ellipsis : String = "…"

      # Legacy style properties (deprecated, map to styles)
      def key_style : Lipgloss::Style
        @styles.short_key
      end

      def key_style=(style : Lipgloss::Style)
        @styles.short_key = style
        @styles.full_key = style
      end

      def desc_style : Lipgloss::Style
        @styles.short_desc
      end

      def desc_style=(style : Lipgloss::Style)
        @styles.short_desc = style
        @styles.full_desc = style
      end

      def separator_style : Lipgloss::Style
        @styles.short_separator
      end

      def separator_style=(style : Lipgloss::Style)
        @styles.short_separator = style
        @styles.full_separator = style
      end

      def ellipsis_style : Lipgloss::Style
        @styles.ellipsis
      end

      def ellipsis_style=(style : Lipgloss::Style)
        @styles.ellipsis = style
      end

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

        sep = styles.short_separator.inline(true).render(@short_separator)
        total_width = 0

        parts = [] of String
        bindings.each_with_index do |binding, idx|
          next unless binding.enabled?

          item = "#{styles.short_key.inline(true).render(binding.help_key)} #{styles.short_desc.inline(true).render(binding.help_desc)}"
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
        separator = styles.full_separator.inline(true).render(@full_separator)

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
              styles.full_key.render(keys.join("\n")),
              " ",
              styles.full_desc.render(descs.join("\n")),
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
          tail = " " + styles.ellipsis.inline(true).render(@ellipsis)
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
