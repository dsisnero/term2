require "../term2"

module Term2
  module Components
    # Tree is a static renderer for hierarchical tree structures.
    # Unlike the interactive List component, Tree is for display-only rendering.
    #
    # Example:
    # ```
    # tree = Tree.new("root")
    #   .child("child1")
    #   .child(
    #     Tree.new("child2")
    #       .child("grandchild1")
    #       .child("grandchild2")
    #   )
    #   .child("child3")
    #
    # puts tree.render
    # # root
    # # ├── child1
    # # ├── child2
    # # │   ├── grandchild1
    # # │   └── grandchild2
    # # └── child3
    # ```
    class Tree
      # Node represents a tree node (either a leaf or subtree)
      abstract class Node
        abstract def value : String
        abstract def children : Array(Node)
        abstract def hidden? : Bool

        property? hidden : Bool = false
      end

      # Leaf is a node without children
      class Leaf < Node
        property value : String

        def initialize(@value : String)
        end

        def children : Array(Node)
          [] of Node
        end

        def hidden? : Bool
          @hidden
        end
      end

      # Enumerator generates the branch prefix (├──, └──, etc.)
      # Takes children array and current index, returns the prefix string.
      alias Enumerator = Proc(Array(Node), Int32, String)

      # Indenter generates the indent prefix for nested items
      # Takes children array and current index, returns the indent string.
      alias Indenter = Proc(Array(Node), Int32, String)

      # StyleFunc determines the style of a node based on its siblings and index
      alias StyleFunc = Proc(Array(Node), Int32, Style)

      # Predefined enumerators
      module Enumerators
        # Default tree enumerator with sharp corners
        # ├── Foo
        # └── Bar
        Default = ->(children : Array(Node), index : Int32) {
          if children.size - 1 == index
            "└──"
          else
            "├──"
          end
        }

        # Rounded tree enumerator
        # ├── Foo
        # ╰── Bar
        Rounded = ->(children : Array(Node), index : Int32) {
          if children.size - 1 == index
            "╰──"
          else
            "├──"
          end
        }
      end

      # Predefined indenters
      module Indenters
        # Default indenter with vertical bars for connected siblings
        # │  (for items with siblings below)
        #    (for last item)
        Default = ->(children : Array(Node), index : Int32) {
          if children.size - 1 == index
            "   "
          else
            "│  "
          end
        }
      end

      # Tree is also a Node (can be nested)
      class Tree < Node
        property value : String
        property children_nodes : Array(Node) = [] of Node
        property offset_start : Int32 = 0
        property offset_end : Int32 = 0

        # Rendering options
        property enumerator : Enumerator = Enumerators::Default
        property indenter : Indenter = Indenters::Default
        property root_style : Style = Style.new
        property item_style : Style = Style.new
        property item_style_func : StyleFunc? = nil
        property enumerator_style : Style = Style.new
        property enumerator_style_func : StyleFunc? = nil

        def initialize(@value : String = "")
        end

        def children : Array(Node)
          effective_end = @children_nodes.size - @offset_end
          effective_end = @children_nodes.size if effective_end < 0 || effective_end > @children_nodes.size
          effective_start = @offset_start.clamp(0, effective_end)

          @children_nodes[effective_start...effective_end]
        end

        def hidden? : Bool
          @hidden
        end

        # Fluent API for building trees

        # Set the root value
        def root(value : String) : self
          @value = value
          self
        end

        # Add a child (string, Node, or another Tree)
        def child(item : String) : self
          @children_nodes << Leaf.new(item)
          self
        end

        def child(item : Node) : self
          @children_nodes << item
          self
        end

        def child(item : Tree) : self
          @children_nodes << item.as(Node)
          self
        end

        # Add multiple children
        def children(*items : String) : self
          items.each { |item| child(item) }
          self
        end

        def children(items : Array(String)) : self
          items.each { |item| child(item) }
          self
        end

        # Set offset to limit which children are rendered
        def offset(start_offset : Int32, end_offset : Int32) : self
          @offset_start = start_offset
          @offset_end = end_offset
          self
        end

        # Hide/show this tree
        def hide(hidden : Bool = true) : self
          @hidden = hidden
          self
        end

        # Set the enumerator (branch style)
        def enumerator(e : Enumerator) : self
          @enumerator = e
          self
        end

        # Set the indenter
        def indenter(i : Indenter) : self
          @indenter = i
          self
        end

        # Set root style
        def root_style(style : Style) : self
          @root_style = style
          self
        end

        # Set item style (applies to all items)
        def item_style(style : Style) : self
          @item_style = style
          @item_style_func = nil
          self
        end

        # Set item style function (for conditional styling)
        def item_style_func(func : StyleFunc) : self
          @item_style_func = func
          self
        end

        # Set enumerator style (applies to all enumerators)
        def enumerator_style(style : Style) : self
          @enumerator_style = style
          @enumerator_style_func = nil
          self
        end

        # Set enumerator style function (for conditional styling)
        def enumerator_style_func(func : StyleFunc) : self
          @enumerator_style_func = func
          self
        end

        # Get item style for a node
        private def get_item_style(nodes : Array(Node), index : Int32) : Style
          if func = @item_style_func
            func.call(nodes, index)
          else
            @item_style
          end
        end

        # Get enumerator style for a node
        private def get_enumerator_style(nodes : Array(Node), index : Int32) : Style
          if func = @enumerator_style_func
            func.call(nodes, index)
          else
            @enumerator_style
          end
        end

        # Render the tree to a string
        def render : String
          return "" if hidden?

          String.build do |io|
            render_to(io, true, "")
          end.chomp
        end

        # Alias for render (matches Lipgloss API)
        def to_s : String
          render
        end

        # Internal rendering method
        protected def render_to(io : IO, is_root : Bool, prefix : String)
          return if hidden?

          # Render root value if present
          unless @value.empty?
            if is_root
              io << @root_style.render(@value) << "\n"
            end
          end

          visible_children = children.reject(&.hidden?)

          visible_children.each_with_index do |child, index|
            # Get enumerator string and style
            enum_str = @enumerator.call(visible_children, index)
            enum_style = get_enumerator_style(visible_children, index)

            # Get item style
            item_style = get_item_style(visible_children, index)

            # Render the child value with prefix
            io << prefix
            io << enum_style.render(enum_str)
            io << " "
            io << item_style.render(child.value)
            io << "\n"

            # Render nested children if this is a subtree
            if child.is_a?(Tree) && !child.children.empty?
              indent = @indenter.call(visible_children, index)
              child.render_to(io, false, prefix + indent)
            end
          end
        end
      end

      # Module-level convenience methods

      # Create a new tree with a root value
      def self.new(root : String = "") : Tree
        Tree.new(root)
      end

      # Create a tree with a root value (alias for new)
      def self.root(root : String) : Tree
        new(root)
      end
    end
  end
end
