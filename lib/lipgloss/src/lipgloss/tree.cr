require "./children"
require "./enumerator"
require "./renderer"

module Lipgloss::Tree
  VERSION = "0.1.0"

  module Node
    abstract def value : String
    abstract def value=(value : String)
    abstract def children : Children
    abstract def hidden? : Bool
  end

  class Leaf
    include Node

    property value : String
    property? hidden : Bool

    def initialize(value = nil, hidden : Bool = false)
      @value = ""
      @hidden = hidden
      assign_value(value)
    end

    def children : Children
      NodeChildren.new
    end

    private def assign_value(value)
      case value
      when Node
        @value = value.to_s
      when Lipgloss::StyleTable::Table
        @value = value.string
      when String
        @value = value
      when Nil
        @value = ""
      else
        @value = value.to_s
      end
    end

    def to_s(io : IO) : Nil
      io << @value
    end
  end

  class Tree
    include Node

    property value : String
    property? hidden : Bool

    @children : Children
    @offset_start : Int32
    @offset_end : Int32
    @renderer : Renderer?

    def initialize
      @value = ""
      @hidden = false
      @children = NodeChildren.new
      @offset_start = 0
      @offset_end = 0
      @renderer = nil
    end

    def self.root(root_value) : Tree
      new.root(root_value)
    end

    def hide(hide : Bool) : Tree
      @hidden = hide
      self
    end

    def offset(start_idx : Int32, end_idx : Int32) : Tree
      start_pos = start_idx
      end_pos = end_idx

      if start_pos > end_pos
        start_pos, end_pos = end_pos, start_pos
      end

      start_pos = 0 if start_pos < 0
      if end_pos < 0 || end_pos > @children.length
        end_pos = @children.length
      end

      @offset_start = start_pos
      @offset_end = end_pos
      self
    end

    def to_s(io : IO) : Nil
      io << ensure_renderer.render(self, true, "")
    end

    def child(*children) : Tree
      children.each do |child_item|
        case child_item
        when Tree
          new_item, remove_index = ensure_parent(@children, child_item)
          if remove_index >= 0
            @children = @children.as(NodeChildren).remove(remove_index)
          end
          @children = @children.as(NodeChildren).append(new_item)
        when Children
          child_item.length.times do |child_index|
            node = child_item.at(child_index)
            @children = @children.as(NodeChildren).append(node) if node
          end
        when Node
          @children = @children.as(NodeChildren).append(child_item)
        when Lipgloss::StyleTable::Table
          @children = @children.as(NodeChildren).append(Leaf.new(child_item.string))
        when String
          @children = @children.as(NodeChildren).append(Leaf.new(child_item))
        when Array
          child_item.each { |nested| child(nested) }
        when Nil
          next
        else
          @children = @children.as(NodeChildren).append(Leaf.new(child_item.to_s))
        end
      end
      self
    end

    def enumerator_style(style : Lipgloss::Style) : Tree
      ensure_renderer.style.enumerator_func = ->(_children : Children, _index : Int32) { style }
      self
    end

    def enumerator_style_func(fn : StyleFunc?) : Tree
      renderer = ensure_renderer
      renderer.style.enumerator_func = fn || ->(_children : Children, _index : Int32) { Lipgloss::Style.new }
      self
    end

    def indenter_style(style : Lipgloss::Style) : Tree
      ensure_renderer.style.indenter_func = ->(_children : Children, _index : Int32) { style }
      self
    end

    def indenter_style_func(fn : StyleFunc?) : Tree
      renderer = ensure_renderer
      renderer.style.indenter_func = fn || ->(_children : Children, _index : Int32) { Lipgloss::Style.new }
      self
    end

    def root_style(style : Lipgloss::Style) : Tree
      ensure_renderer.style.root = style
      self
    end

    def item_style(style : Lipgloss::Style) : Tree
      ensure_renderer.style.item_func = ->(_children : Children, _index : Int32) { style }
      self
    end

    def item_style_func(fn : StyleFunc?) : Tree
      renderer = ensure_renderer
      renderer.style.item_func = fn || ->(_children : Children, _index : Int32) { Lipgloss::Style.new }
      self
    end

    def enumerator(enumerator_fn : Enumerator) : Tree
      ensure_renderer.enumerator = enumerator_fn
      self
    end

    def indenter(indenter_fn : Indenter) : Tree
      ensure_renderer.indenter = indenter_fn
      self
    end

    def width(width : Int32) : Tree
      ensure_renderer.width = width
      self
    end

    def children : Children
      data = NodeChildren.new
      start_idx = @offset_start
      end_idx = @children.length - @offset_end
      end_idx = start_idx if end_idx < start_idx

      i = start_idx
      while i < end_idx
        node = @children.at(i)
        data = data.append(node) if node
        i += 1
      end

      data
    end

    def root(root_value) : Tree
      case root_value
      when Tree
        @value = root_value.value
        child(root_value.children)
      when Node
        @value = root_value.to_s
      when Lipgloss::StyleTable::Table
        @value = root_value.string
      when String
        @value = root_value
      when Nil
        @value = ""
      else
        @value = root_value.to_s
      end
      self
    end

    def renderer : Renderer?
      @renderer
    end

    private def ensure_renderer : Renderer
      @renderer ||= Renderer.new
    end

    private def ensure_parent(nodes : Children, item : Tree) : {Tree, Int32}
      return {item, -1} if !item.value.empty? || nodes.length == 0

      parent_index = nodes.length - 1
      parent = nodes.at(parent_index)
      case parent
      when Tree
        item.children.length.times do |i|
          child_node = item.children.at(i)
          parent.child(child_node) if child_node
        end
        {parent, parent_index}
      when Leaf
        item.value = parent.value
        {item, parent_index}
      else
        {item, -1}
      end
    end
  end

  def self.new : Tree
    Tree.new
  end

  def self.root(root_value) : Tree
    Tree.root(root_value)
  end
end
