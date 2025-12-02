# Port of lipgloss list/simple example to term2
# Original Go code: https://github.com/charmbracelet/lipgloss/blob/main/examples/list/simple/main.go
#
# This example demonstrates a simple text formatter that mimics lipgloss's
# list behavior, since term2's List component is designed for interactive UI.

require "../list_helpers"

include LipglossListHelpers

puts "Lipgloss List/Simple Example Ported to Term2"
puts "=" * 60

# Create the main list
main_items = ["A", "B", "C", "G"]

# Create the sublist with Roman enumeration
sublist_items = ["D", "E", "F"]

# Render the main list
main_list = format_list(main_items)

# Render the sublist with Roman numerals
sublist = format_list(sublist_items, 2) do |i|
  to_roman(i + 1) + ". "
end

# Combine them
puts main_items[0..2].map { |item| "  #{item}" }.join("\n")
puts sublist
puts "  #{main_items[3]}"

puts "=" * 60