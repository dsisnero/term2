# Port of lipgloss list/none example to term2
# Original Go code: https://github.com/charmbracelet/lipgloss/blob/main/examples/list/none/main.go
#
# This example demonstrates lists without enumeration.

puts "Lipgloss List/None Example Ported to Term2"
puts "=" * 60

# Simple text formatter for lists
def format_list(items : Array(String), indent : Int32 = 0, &block : Int32 -> String) : String
  String.build do |io|
    items.each_with_index do |item, i|
      prefix = block.call(i)
      io << " " * indent << prefix << item << "\n"
    end
  end
end

# Simple text formatter for lists without block
def format_list(items : Array(String), indent : Int32 = 0) : String
  String.build do |io|
    items.each_with_index do |item, _|
      io << " " * indent << item << "\n"
    end
  end
end

# Create a list without enumeration
items = ["Item one", "Item two", "Item three"]

puts "List without enumeration:"
puts format_list(items, 2)

puts "=" * 60