require "./canvas"
require "./geometry"

module Lipgloss
  # Layer represents a visual layer with content and positioning.
  class Layer
    @id : String = ""
    @content : String
    @width : Int32 = 0
    @height : Int32 = 0
    @x : Int32 = 0
    @y : Int32 = 0
    @z : Int32 = 0
    @layers : Array(Layer) = [] of Layer

    def initialize(@content : String)
      add_layers
    end

    def initialize(@content : String, *layers : Layer)
      add_layers(*layers)
    end

    def content : String
      @content
    end

    def content : String
      @content
    end

    def width : Int32
      @width
    end

    def height : Int32
      @height
    end

    def id : String
      @id
    end

    def id : String
      @id
    end

    def id(id : String) : Layer
      @id = id
      self
    end

    def x(x : Int32) : Layer
      @x = x
      self
    end

    def y(y : Int32) : Layer
      @y = y
      self
    end

    def z(z : Int32) : Layer
      @z = z
      self
    end

    def x : Int32
      @x
    end

    def y : Int32
      @y
    end

    def z : Int32
      @z
    end

    def add_layers : Layer
      area = bounds_with_offset(0, 0)
      @width = area.dx
      @height = area.dy
      self
    end

    def add_layers(*layers : Layer?) : Layer
      layers.each_with_index do |layer, idx|
        raise "layer at index #{idx} is nil" if layer.nil?
        @layers << layer
      end
      add_layers
    end

    def get_layer(id : String) : Layer?
      return if id.empty?
      return self if @id == id
      @layers.each do |child|
        found = child.get_layer(id)
        return found if found
      end
      nil
    end

    def max_z : Int32
      max = @z
      @layers.each do |child|
        child_max = child.max_z
        max = child_max if child_max > max
      end
      max
    end

    def layers : Array(Layer)
      @layers
    end

    def draw(scr : Canvas, area : Rectangle) : Nil
      scr.draw_string(@content, area.min.x, area.min.y)
    end

    protected def bounds_with_offset(parent_x : Int32, parent_y : Int32) : Rectangle
      abs_x = @x + parent_x
      abs_y = @y + parent_y
      width = Lipgloss.width(@content)
      height = Lipgloss.height(@content)

      bounds = Rectangle.from_xywh(abs_x, abs_y, width, height)
      @layers.each do |child|
        bounds = bounds.union(child.bounds_with_offset(abs_x, abs_y))
      end
      bounds
    end
  end

  struct LayerHit
    getter id : String
    getter layer : Layer?
    getter bounds : Rectangle

    def initialize(@id : String, @layer : Layer?, @bounds : Rectangle)
    end

    def self.empty : LayerHit
      LayerHit.new("", nil, Rectangle.zero)
    end

    def empty? : Bool
      @layer.nil?
    end
  end

  class Compositor
    @root : Layer
    @layers : Array(CompositeLayer) = [] of CompositeLayer
    @index : Hash(String, Layer) = {} of String => Layer
    @bounds : Rectangle = Rectangle.zero

    private struct CompositeLayer
      getter layer : Layer
      getter abs_x : Int32
      getter abs_y : Int32
      getter bounds : Rectangle

      def initialize(@layer : Layer, @abs_x : Int32, @abs_y : Int32, @bounds : Rectangle)
      end
    end

    def initialize
      @root = Layer.new("")
      flatten
    end

    def initialize(*layers : Layer)
      @root = Layer.new("")
      @root.add_layers(*layers)
      flatten
    end

    def add_layers : Compositor
      @root.add_layers
      flatten
      self
    end

    def add_layers(*layers : Layer) : Compositor
      @root.add_layers(*layers)
      flatten
      self
    end

    def bounds : Rectangle
      @bounds
    end

    def draw(scr : Canvas, area : Rectangle) : Nil
      @layers.each do |composite_layer|
        next unless composite_layer.bounds.overlaps?(area)
        composite_layer.layer.draw(scr, composite_layer.bounds)
      end
    end

    def hit(x : Int32, y : Int32) : LayerHit
      (@layers.size - 1).downto(0) do |i|
        composite_layer = @layers[i]
        next if composite_layer.layer.id.empty?
        if composite_layer.bounds.contains?(x, y)
          return LayerHit.new(composite_layer.layer.id, composite_layer.layer, composite_layer.bounds)
        end
      end
      LayerHit.empty
    end

    def get_layer(id : String) : Layer?
      return if id.empty?
      @index[id]?
    end

    def refresh : Nil
      flatten
    end

    def render : String
      width = @bounds.dx
      height = @bounds.dy
      return "" if width <= 0 || height <= 0
      canvas = Canvas.new(width, height)
      canvas.compose(self)
      canvas.render
    end

    private def flatten : Nil
      @layers.clear
      @index.clear
      flatten_recursive(@root, 0, 0)
      @layers.sort_by!(&.layer.z)

      if @layers.empty?
        @bounds = Rectangle.zero
        return
      end

      overall = @layers[0].bounds
      @layers.each_with_index do |composite_layer, idx|
        next if idx == 0
        overall = overall.union(composite_layer.bounds)
      end
      @bounds = overall
    end

    private def flatten_recursive(layer : Layer, parent_x : Int32, parent_y : Int32) : Nil
      abs_x = layer.x + parent_x
      abs_y = layer.y + parent_y
      width = Lipgloss.width(layer.content)
      height = Lipgloss.height(layer.content)
      bounds = Rectangle.from_xywh(abs_x, abs_y, width, height)

      @layers << CompositeLayer.new(layer, abs_x, abs_y, bounds)
      @index[layer.id] = layer unless layer.id.empty?

      layer.layers.each do |child|
        flatten_recursive(child, abs_x, abs_y)
      end
    end
  end

  def self.new_layer(content : String) : Layer
    Layer.new(content)
  end

  def self.new_layer(content : String, *layers : Layer) : Layer
    Layer.new(content, *layers)
  end

  def self.new_compositor : Compositor
    Compositor.new
  end

  def self.new_compositor(*layers : Layer) : Compositor
    Compositor.new(*layers)
  end
end
