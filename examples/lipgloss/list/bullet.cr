# Port of lipgloss list/bullet example to term2
# Original Go code: https://github.com/charmbracelet/lipgloss/blob/main/examples/list/bullet/main.go
#
# This example demonstrates bullet point lists.

require "../list_helpers"

include LipglossListHelpers

puts "Lipgloss List/Bullet Example Ported to Term2"
puts "=" * 60

# Create a bullet list
items = ["Buy milk", "Walk the dog", "Finish homework"]

puts "Bullet List:"
puts bullet_list(items, 2)

puts "=" * 60