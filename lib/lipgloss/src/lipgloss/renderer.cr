module Lipgloss::Tree
  alias StyleFunc = Proc(Children, Int32, Lipgloss::Style)

  class RenderStyle
    property enumerator_func : StyleFunc
    property indenter_func : StyleFunc
    property item_func : StyleFunc
    property root : Lipgloss::Style

    def initialize
      @enumerator_func = ->(_children : Children, _index : Int32) { Lipgloss::Style.new.padding_right(1) }
      @indenter_func = ->(_children : Children, _index : Int32) { Lipgloss::Style.new.padding_right(1) }
      @item_func = ->(_children : Children, _index : Int32) { Lipgloss::Style.new }
      @root = Lipgloss::Style.new
    end
  end

  class Renderer
    property style : RenderStyle
    property enumerator : Enumerator
    property indenter : Indenter
    property width : Int32

    def initialize
      @style = RenderStyle.new
      @enumerator = ->(children : Children, index : Int32) { ::Lipgloss::Tree.default_enumerator(children, index) }
      @indenter = ->(children : Children, index : Int32) { ::Lipgloss::Tree.default_indenter(children, index) }
      @width = 0
    end

    def render(node : Node, root : Bool, prefix : String) : String
      return "" if node.hidden?

      visible_children = NodeChildren.new
      i = 0
      while i < node.children.length
        child = node.children.at(i)
        visible_children = visible_children.append(child) if child && !child.hidden?
        i += 1
      end

      lines = [] of String
      if root && !node.value.empty?
        line = @style.root.render(node.value)
        if (pad = @width - Lipgloss::Text.width(line)) > 0
          line = line + @style.root.render(" " * pad)
        end
        lines << line
      end

      max_prefix_width = 0
      i = 0
      while i < visible_children.length
        prefix_text = @enumerator.call(visible_children, i)
        styled_prefix = @style.enumerator_func.call(visible_children, i).render(prefix_text)
        max_prefix_width = {max_prefix_width, Lipgloss::Text.width(styled_prefix)}.max
        i += 1
      end

      i = 0
      while i < visible_children.length
        child = visible_children.at(i)
        break unless child

        indent_style = @style.indenter_func.call(visible_children, i)
        enum_style = @style.enumerator_func.call(visible_children, i)
        item_style = @style.item_func.call(visible_children, i)

        indent = indent_style.render(@indenter.call(visible_children, i))
        node_prefix = enum_style.render(@enumerator.call(visible_children, i))

        if (pad = max_prefix_width - Lipgloss::Text.width(node_prefix)) > 0
          node_prefix = (" " * pad) + node_prefix
        end

        item = item_style.render(child.value)
        multiline_prefix = prefix

        while render_height(item) > render_height(node_prefix)
          node_prefix = Lipgloss::Style.join_vertical(Lipgloss::Position::Left, node_prefix, indent)
        end

        while render_height(node_prefix) > render_height(multiline_prefix)
          multiline_prefix = Lipgloss::Style.join_vertical(Lipgloss::Position::Left, multiline_prefix, prefix)
        end

        line = Lipgloss::Style.join_horizontal(
          Lipgloss::Position::Top,
          multiline_prefix,
          node_prefix,
          item
        )

        if (pad = @width - Lipgloss::Text.width(line)) > 0
          line += item_style.render(" " * pad)
        end
        lines << line

        nested_renderer = self
        if child.is_a?(Tree)
          nested_renderer = child.renderer || self
        end

        nested = nested_renderer.render(child, false, prefix + indent)
        lines << nested unless nested.empty?

        i += 1
      end

      normalize_sgr_reset(lines.join('\n'))
    end

    private def render_height(value : String) : Int32
      h = Lipgloss::Text.height(value)
      h == 0 ? 1 : h
    end

    private def normalize_sgr_reset(value : String) : String
      value.gsub("\e[0m", "\e[m")
    end
  end
end
