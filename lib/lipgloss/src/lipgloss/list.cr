module Lipgloss::List
  VERSION = "0.1.0"

  alias Items = Lipgloss::Tree::Children
  alias StyleFunc = Proc(Items, Int32, Lipgloss::Style)
  alias Enumerator = Proc(Items, Int32, String)
  alias Indenter = Proc(Items, Int32, String)

  class List
    getter tree : Lipgloss::Tree::Tree

    def initialize
      @tree = Lipgloss::Tree.new
    end

    def self.create(*items) : List
      list = List.new
      list.items(*items)
      list.enumerator(->(list_items : Items, index : Int32) { ::Lipgloss::List.bullet(list_items, index) })
      list.indenter(->(_list_items : Items, _index : Int32) { " " })
      list
    end

    def hidden? : Bool
      @tree.hidden?
    end

    def hide(hide : Bool) : List
      @tree.hide(hide)
      self
    end

    def offset(start_idx : Int32, end_idx : Int32) : List
      @tree.offset(start_idx, end_idx)
      self
    end

    def value : String
      @tree.value
    end

    def to_s(io : IO) : Nil
      io << @tree.to_s
    end

    def enumerator_style(style : Lipgloss::Style) : List
      @tree.enumerator_style(style)
      self
    end

    def enumerator_style_func(fn : StyleFunc) : List
      @tree.enumerator_style_func(->(children : Lipgloss::Tree::Children, index : Int32) { fn.call(children, index) })
      self
    end

    def indenter_style(style : Lipgloss::Style) : List
      @tree.indenter_style(style)
      self
    end

    def indenter_style_func(fn : StyleFunc) : List
      @tree.indenter_style_func(->(children : Lipgloss::Tree::Children, index : Int32) { fn.call(children, index) })
      self
    end

    def indenter(indenter_fn : Indenter) : List
      @tree.indenter(->(children : Lipgloss::Tree::Children, index : Int32) { indenter_fn.call(children, index) })
      self
    end

    def item_style(style : Lipgloss::Style) : List
      @tree.item_style(style)
      self
    end

    def item_style_func(fn : StyleFunc) : List
      @tree.item_style_func(->(children : Lipgloss::Tree::Children, index : Int32) { fn.call(children, index) })
      self
    end

    def item(item_value) : List
      case item_value
      when List
        @tree.child(item_value.tree)
      else
        @tree.child(item_value)
      end
      self
    end

    def items(*items_values) : List
      items_values.each { |item_value| item(item_value) }
      self
    end

    def enumerator(enumerator_fn : Enumerator) : List
      @tree.enumerator(->(children : Lipgloss::Tree::Children, index : Int32) { enumerator_fn.call(children, index) })
      self
    end
  end

  def self.new(*items) : List
    List.create(*items)
  end

  ABC_LEN = 26

  def self.alphabet(_items : Items, index : Int32) : String
    if index >= ABC_LEN * ABC_LEN + ABC_LEN
      one = ('A'.ord + index // ABC_LEN // ABC_LEN - 1).chr
      two = ('A'.ord + (index // ABC_LEN) % ABC_LEN - 1).chr
      three = ('A'.ord + index % ABC_LEN).chr
      return "#{one}#{two}#{three}."
    end

    if index >= ABC_LEN
      one = ('A'.ord + index // ABC_LEN - 1).chr
      two = ('A'.ord + index % ABC_LEN).chr
      return "#{one}#{two}."
    end

    "#{('A'.ord + index % ABC_LEN).chr}."
  end

  def self.arabic(_items : Items, index : Int32) : String
    "#{index + 1}."
  end

  ROMAN = [
    {1000, "M"},
    {900, "CM"},
    {500, "D"},
    {400, "CD"},
    {100, "C"},
    {90, "XC"},
    {50, "L"},
    {40, "XL"},
    {10, "X"},
    {9, "IX"},
    {5, "V"},
    {4, "IV"},
    {1, "I"},
  ]

  def self.roman(_items : Items, index : Int32) : String
    value = index + 1
    result = String.build do |io|
      ROMAN.each do |arabic, roman|
        while value >= arabic
          io << roman
          value -= arabic
        end
      end
      io << '.'
    end
    result
  end

  def self.bullet(_items : Items, _index : Int32) : String
    "•"
  end

  def self.asterisk(_items : Items, _index : Int32) : String
    "*"
  end

  def self.dash(_items : Items, _index : Int32) : String
    "-"
  end
end
