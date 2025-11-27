require "../src/term2"

# Define styles
title_style = Term2::LipGloss::Style.new
  .bold(true)
  .foreground(Term2::Color::CYAN)
  .border(Term2::LipGloss::Border.rounded)
  .padding(1, 2)
  .align(Term2::LipGloss::Position::Center)
  .width(50)

# Create components
table = Term2::LipGloss::Table.new
  .headers("Name", "Role")
  .row("Alice", "Engineer")
  .row("Bob", "Designer")
  .border(Term2::LipGloss::Border.normal)

list = Term2::LipGloss::List.new
  .items("Task 1", "Task 2", "Task 3")
  .enumerator(Term2::LipGloss::List::Enumerator::Bullet)

tree = Term2::LipGloss::Tree.new("Project")
  .child("src")
  .child(Term2::LipGloss::Tree.new("lib").child("shard.yml"))

# Layout
left_col = Term2::LipGloss.join_vertical(Term2::LipGloss::Position::Left,
  title_style.render("LipGloss Demo"),
  table.render
)

right_col = Term2::LipGloss.join_vertical(Term2::LipGloss::Position::Left,
  list.render,
  tree.render
)

# Add some spacing
right_col = Term2::LipGloss::Style.new.margin(0, 0, 0, 2).render(right_col)

output = Term2::LipGloss.join_horizontal(Term2::LipGloss::Position::Top, left_col, right_col)

puts output
