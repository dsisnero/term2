require "../src/term2"

# Term2::Style List/Sublist Example
# Demonstrates the List component with different enumerators and styles
# Note: This List is an interactive component with pagination and selection

# Shorthand aliases
alias List = Term2::Components::List

# Define styles for the list
main_list_style = Term2::Style.new
  .bold(true)
  .foreground(Term2::Color::CYAN)

# Create lists with different enumerators
puts "List Examples with Different Enumerators:"
puts "=" * 60

# Arabic numerals
arabic_list = List.new(["First item", "Second item", "Third item"])
  .enumerator(List::Enumerators::Arabic)
puts "\nArabic Numerals:"
puts arabic_list.view

# Bullet points
bullet_list = List.new(["Apple", "Banana", "Cherry"])
  .enumerator(List::Enumerators::Bullet)
puts "\nBullet Points:"
puts bullet_list.view

# Alphabet
alpha_list = List.new(["One", "Two", "Three", "Four", "Five"])
  .enumerator(List::Enumerators::Alphabet)
puts "\nAlphabet:"
puts alpha_list.view

# Roman numerals
roman_list = List.new(["Caesar", "Augustus", "Nero"])
  .enumerator(List::Enumerators::Roman)
puts "\nRoman Numerals:"
puts roman_list.view

# Dash
dash_list = List.new(["Task A", "Task B", "Task C"])
  .enumerator(List::Enumerators::Dash)
puts "\nDash:"
puts dash_list.view

puts "=" * 60
