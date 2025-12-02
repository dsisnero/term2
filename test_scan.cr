require "./src/term2"

Term2::Zone.clear
content = "a" + Term2::Zone.mark("test", "b") + "c"
puts "Original content: #{content.inspect}"
result = Term2::Zone.scan(content)
puts "Scan result: #{result.inspect}"
puts "Should be: \"abc\""