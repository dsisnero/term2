# Port of lipgloss list/roman example to term2
# Original Go code: https://github.com/charmbracelet/lipgloss/blob/main/examples/list/roman/main.go
#
# This example demonstrates Roman numeral lists.

require "../list_helpers"

include LipglossListHelpers

puts "Lipgloss List/Roman Example Ported to Term2"
puts "=" * 60

# Create a Roman numeral list
items = ["Chapter I", "Chapter II", "Chapter III", "Chapter IV"]

puts "Roman Numeral List (uppercase):"
puts uppercase_roman_list(items, 2)

puts "\nRoman Numeral List (lowercase):"
puts lowercase_roman_list(items, 2)

puts "=" * 60