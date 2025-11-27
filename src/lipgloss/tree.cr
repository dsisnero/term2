module Term2
  module LipGloss
    class Tree
      property root : String
      property children : Array(Tree | String)
      property item_style : Style
      property enumerator_style : Style
      property? hidden : Bool = false

      def initialize(root : String = "")
        @root = root
        @children = [] of Tree | String
        @item_style = Style.new
        @enumerator_style = Style.new
      end

      def root(r : String)
        @root = r
        self
      end

      def child(c : Tree | String)
        @children << c
        self
      end

      def hide(val : Bool)
        @hidden = val
        self
      end

      def item_style(s : Style)
        @item_style = s
        self
      end

      def enumerator_style(s : Style)
        @enumerator_style = s
        self
      end

      def render : String
        render_tree(self)
      end

      private def render_tree(tree : Tree) : String
        return "" if tree.hidden?

        lines = [] of String
        lines << @item_style.render(tree.root)

        # Filter out hidden children
        visible_children = tree.children.select do |child|
          child.is_a?(Tree) ? !child.hidden? : true
        end

        visible_children.each_with_index do |child, i|
          is_last = (i == visible_children.size - 1)
          connector = is_last ? "└── " : "├── "
          child_prefix = is_last ? "    " : "│   "

          # Apply enumerator style to connector/prefix
          connector = @enumerator_style.render(connector)
          child_prefix = @enumerator_style.render(child_prefix)

          child_content = ""
          if child.is_a?(Tree)
            child_content = render_tree(child)
          else
            child_content = @item_style.render(child.to_s)
          end

          child_lines = child_content.split('\n')

          if !child_lines.empty? && !child_content.empty?
            # First line
            lines << "#{connector}#{child_lines[0]}"

            # Subsequent lines
            child_lines[1..-1].each do |line|
              lines << "#{child_prefix}#{line}"
            end
          end
        end

        lines.join("\n")
      end
    end
  end
end
