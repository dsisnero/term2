require "../src/similar"

old_text = "Hello\nWorld\n"
new_text = "Hello\nCrystal\n"

diff = Similar::TextDiff.from_lines(old_text, new_text)
puts diff.unified_diff.header("old.txt", "new.txt").to_s
