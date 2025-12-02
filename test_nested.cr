require "./src/zone"

Term2::Zone.clear
content = Term2::Zone.mark("outer", Term2::Zone.mark("inner", "b"))
puts "Content: #{content.inspect}"
result = Term2::Zone.scan(content)
puts "Result: #{result.inspect}"
puts "Outer zone: #{Term2::Zone.get("outer")}"
puts "Inner zone: #{Term2::Zone.get("inner")}"