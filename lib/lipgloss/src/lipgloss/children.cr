module Lipgloss::Tree
  module Children
    abstract def at(index : Int32) : Node?
    abstract def length : Int32
  end

  class NodeChildren
    include Children

    getter nodes : Array(Node)

    def initialize(@nodes = [] of Node)
    end

    def append(child : Node) : NodeChildren
      NodeChildren.new(@nodes + [child])
    end

    def remove(index : Int32) : NodeChildren
      return self if index < 0 || index >= @nodes.size

      result = @nodes.dup
      result.delete_at(index)
      NodeChildren.new(result)
    end

    def length : Int32
      @nodes.size
    end

    def at(index : Int32) : Node?
      return nil if index < 0 || index >= @nodes.size
      @nodes[index]
    end
  end

  def self.new_string_data(*data : String) : Children
    children = NodeChildren.new
    data.each do |value|
      children = children.append(Leaf.new(value))
    end
    children
  end

  class Filter
    include Children

    @data : Children
    @filter : Proc(Int32, Bool)

    def initialize(data : Children?)
      @data = data || NodeChildren.new
      @filter = ->(_index : Int32) { true }
    end

    def at(index : Int32) : Node?
      visible_index = 0
      i = 0
      while i < @data.length
        if @filter.call(i)
          if visible_index == index
            return @data.at(i)
          end
          visible_index += 1
        end
        i += 1
      end
      nil
    end

    def filter(fn : Proc(Int32, Bool)) : Filter
      @filter = fn
      self
    end

    def length : Int32
      total = 0
      i = 0
      while i < @data.length
        total += 1 if @filter.call(i)
        i += 1
      end
      total
    end
  end

  def self.new_filter(data : Children?) : Filter
    Filter.new(data)
  end
end
