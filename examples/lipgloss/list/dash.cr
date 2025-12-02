# Port of lipgloss list/dash example to term2
# Original Go code: https://github.com/charmbracelet/lipgloss/blob/main/examples/list/dash/main.go
#
# This example demonstrates dash lists.

require "../list_helpers"

include LipglossListHelpers

puts "Lipgloss List/Dash Example Ported to Term2"
puts "=" * 60

# Create a dash list
items = ["Apples", "Oranges", "Bananas"]

puts "Dash List:"
puts dash_list(items, 2)

puts "=" * 60