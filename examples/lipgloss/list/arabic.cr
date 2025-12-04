# Port of lipgloss list/arabic example to term2
# Original Go code: https://github.com/charmbracelet/lipgloss/blob/main/examples/list/arabic/main.go
#
# This example demonstrates Arabic numeral lists.

require "../list_helpers"

include LipglossListHelpers

puts "Lipgloss List/Arabic Example Ported to Term2"
puts "=" * 60

# Create an Arabic numeral list
items = ["First step", "Second step", "Third step", "Fourth step"]

puts "Arabic Numeral List:"
puts arabic_list(items, 2)

puts "=" * 60
