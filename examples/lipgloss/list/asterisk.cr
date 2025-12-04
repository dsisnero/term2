# Port of lipgloss list/asterisk example to term2
# Original Go code: https://github.com/charmbracelet/lipgloss/blob/main/examples/list/asterisk/main.go
#
# This example demonstrates asterisk lists.

require "../list_helpers"

include LipglossListHelpers

puts "Lipgloss List/Asterisk Example Ported to Term2"
puts "=" * 60

# Create an asterisk list
items = ["First item", "Second item", "Third item"]

puts "Asterisk List:"
puts asterisk_list(items, 2)

puts "=" * 60
