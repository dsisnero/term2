require "../src/term2"

# LipGloss List/Sublist Example
# Demonstrates nested lists with different enumerators and styles

# Define styles for different list levels
main_list_style = Term2::LipGloss::Style.new
  .bold(true)
  .foreground(Term2::Color::CYAN)
  .border(Term2::LipGloss::Border.rounded)
  .padding(1, 2)
  .width(60)

sub_list_style = Term2::LipGloss::Style.new
  .foreground(Term2::Color::GREEN)
  .border(Term2::LipGloss::Border.normal)
  .padding(0, 1)
  .margin(0, 0, 0, 2)

deep_list_style = Term2::LipGloss::Style.new
  .foreground(Term2::Color::YELLOW)
  .italic(true)
  .padding(0, 1)
  .margin(0, 0, 0, 4)

# Create nested lists
deep_list = Term2::LipGloss::List.new
  .items("Deep item 1", "Deep item 2", "Deep item 3")
  .enumerator(Term2::LipGloss::List::Enumerator::Bullet)
  .item_style(deep_list_style)

sub_list = Term2::LipGloss::List.new
  .items("Sub item A", "Sub item B", deep_list, "Sub item C")
  .enumerator(Term2::LipGloss::List::Enumerator::Alphabet)
  .item_style(sub_list_style)

main_list = Term2::LipGloss::List.new
  .items("Main item 1", "Main item 2", sub_list, "Main item 3")
  .enumerator(Term2::LipGloss::List::Enumerator::Arabic)
  .item_style(main_list_style)

# Render the nested list structure
puts "Nested List Example:"
puts "=" * 60
puts main_list.render
puts "=" * 60

# Example with mixed content
puts "\nMixed Content List:"
puts "=" * 60

mixed_list = Term2::LipGloss::List.new
  .items(
    "Simple text item",
    Term2::LipGloss::List.new
      .items("Nested A", "Nested B")
      .enumerator(Term2::LipGloss::List::Enumerator::Bullet),
    "Another simple item",
    Term2::LipGloss::List.new
      .items("Deep nested X", "Deep nested Y", "Deep nested Z")
      .enumerator(Term2::LipGloss::List::Enumerator::Arabic)
  )
  .enumerator(Term2::LipGloss::List::Enumerator::Arabic)
  .item_style(Term2::LipGloss::Style.new.foreground(Term2::Color::WHITE))

puts mixed_list.render
puts "=" * 60
