# Port of lipgloss list/alphabet example to term2
# Original Go code: https://github.com/charmbracelet/lipgloss/blob/main/examples/list/alphabet/main.go
#
# This example demonstrates alphabetical lists.

require "../list_helpers"

include LipglossListHelpers

puts "Lipgloss List/Alphabet Example Ported to Term2"
puts "=" * 60

# Create an alphabetical list
items = ["Alpha", "Beta", "Gamma", "Delta"]

puts "Alphabetical List (lowercase):"
puts lowercase_alphabet_list(items, 2)

puts "\nAlphabetical List (uppercase):"
puts uppercase_alphabet_list(items, 2)

puts "=" * 60