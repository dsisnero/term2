require "../src/similar"

old = [1, 2, 3, 4, 5]
new = [1, 2, 4, 5, 6]

diff = Similar.capture_diff_slices(Similar::Algorithm::Myers, old, new)

diff.each do |op|
  puts op
end
