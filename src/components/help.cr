require "../term2"
require "./key"

module Term2
  module Components
    class Help
      include Model

      module KeyMap
        abstract def short_help : Array(Key::Binding)
        abstract def full_help : Array(Array(Key::Binding))

        # Build bindings from a collection of named tuples containing
        # keys/help/description, mirroring bubbles key bindings helpers.
        def self.bindings(entries : Array(NamedTuple(keys: Array(String), help: String, description: String))) : Array(Key::Binding)
          entries.map { |entry| Key::Binding.new(entry[:keys], entry[:help], entry[:description]) }
        end

        # Build bindings from positional tuples {keys, help, description}.
        def self.bindings(entries : Array(Tuple(Array(String), String, String))) : Array(Key::Binding)
          entries.map do |keys, help, desc|
            Key::Binding.new(keys, help, desc)
          end
        end
      end

      property short_separator : String = " • "
      property full_separator : String = "    "
      property ellipsis : String = "…"
      property? show_all : Bool = false
      property width : Int32 = 80

      # Styles
      property key_style : Style = Style.new.faint(true)
      property desc_style : Style = Style.new.faint(true)
      property separator_style : Style = Style.new.faint(true)
      property ellipsis_style : Style = Style.new.faint(true)

      def initialize
      end

      def update(msg : Msg) : {Help, Cmd}
        {self, Cmds.none}
      end

      def view : String
        ""
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
          "#{key_style.render(binding.help_key)} #{desc_style.render(binding.help_desc)}"
        end

        line = parts.join(separator_style.render(@short_separator))
        # Handle width truncation with ellipsis if needed
        if @width > 0 && Term2::Text.width(line) > @width
          ell = " " + ellipsis_style.render(@ellipsis)
          usable_width = @width - Term2::Text.width(ell)
          line = line[0, usable_width] + ell if usable_width > 0
        end
        line
      end

      def view_full(key_map : KeyMap) : String
        groups = key_map.full_help
        return "" if groups.empty?

        sep_rendered = separator_style.render(@full_separator)
        sep_width = Term2::Text.width(sep_rendered)

        columns = [] of {lines: Array(String), width: Int32}
        groups.each do |group|
          bindings = group.compact_map { |binding| binding if binding.enabled? }
          next if bindings.empty?

          keys = bindings.map(&.help_key)
          descs = bindings.map(&.help_desc)
          max_key_width = keys.max_of { |k| Term2::Text.width(k) }
          max_desc_width = descs.max_of { |d| Term2::Text.width(d) }

          col_lines = keys.zip(descs).map do |k, d|
            padded_key = k.ljust(max_key_width)
            "#{key_style.render(padded_key)} #{desc_style.render(d)}"
          end

          col_width = max_key_width + 1 + max_desc_width
          columns << {lines: col_lines, width: col_width}
        end
        return "" if columns.empty?

        selected = [] of {lines: Array(String), width: Int32}
        total_width = 0
        ellipsis_needed = false

        columns.each do |col|
          projected = total_width
          projected += sep_width if !selected.empty?
          projected += col[:width]

          if @width > 0 && projected > @width
            ellipsis_needed = true
            break
          end

          total_width = projected
          selected << col
        end

        return "" if selected.empty?

        max_lines = selected.max_of?(&.[:lines].size) || 0
        output_lines = Array(String).new(max_lines, "")

        max_lines.times do |line_idx|
          line_parts = [] of String
          selected.each_with_index do |col, idx|
            separator = if idx.zero?
                          ""
                        else
                          line_idx.zero? ? sep_rendered : " " * sep_width
                        end
            line_parts << separator
            content = col[:lines][line_idx]? || ""
            pad_len = col[:width] - Term2::Text.width(content)
            line_parts << content
            line_parts << " " * pad_len if pad_len > 0 && idx < selected.size - 1
          end
          line = line_parts.join
          if ellipsis_needed && line_idx == 0
            ell = " " + ellipsis_style.render(@ellipsis)
            line += ell if @width <= 0 || Term2::Text.width(line + ell) <= @width
          end
          output_lines[line_idx] = line
        end

        output_lines.join("\n")
      end
    end
  end
end
