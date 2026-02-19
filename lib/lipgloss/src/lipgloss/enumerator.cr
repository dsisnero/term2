module Lipgloss::Tree
  alias Enumerator = Proc(Children, Int32, String)
  alias Indenter = Proc(Children, Int32, String)

  def self.default_enumerator(children : Children, index : Int32) : String
    children.length - 1 == index ? "└──" : "├──"
  end

  def self.rounded_enumerator(children : Children, index : Int32) : String
    children.length - 1 == index ? "╰──" : "├──"
  end

  def self.default_indenter(children : Children, index : Int32) : String
    children.length - 1 == index ? "   " : "│  "
  end
end
