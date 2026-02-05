# Run with: crystal run examples/close_matches.cr
require "../src/similar"

matches = Similar.get_close_matches("appel", ["ape", "apple", "peach", "puppy"], 3, 0.6)
puts matches.join(", ")
