require "./src/term2"

style1 = Term2::Style.new.border(Term2::Border.rounded, true)
style2 = Term2::Style.new.border(Term2::Border.rounded, true, true, true, true)
puts "Style1 created: #{style1}"
puts "Style2 created: #{style2}"