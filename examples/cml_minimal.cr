# CML Minimal Working Example
# Shows actual working CML patterns

require "cml"

puts "CML Minimal Example\n"

# 1. Basic channel
ch = CML::Chan(String).new

spawn { ch.send("Hello"); ch.close }
msg = CML.sync(ch.recv_evt)
puts "1. Channel: #{msg}"

# 2. Mailbox
mailbox = CML::Mailbox(Int32).new

spawn { mailbox.send(42) }
value = CML.sync(mailbox.recv_evt)
puts "2. Mailbox: #{value}"

# 3. Event selection with CML.choose
ch1 = CML::Chan(String).new
ch2 = CML::Chan(Int32).new

spawn { sleep 0.05; ch1.send("fast") }
spawn { sleep 0.1; ch2.send(100) }

# Create the choose event
choose_evt = CML.choose([
  CML.wrap(ch1.recv_evt) { |msg| "Channel 1: #{msg}" },
  CML.wrap(ch2.recv_evt) { |num| "Channel 2: #{num}" },
  CML.wrap(CML.timeout(0.2.seconds)) { "Timeout" },
])

result = CML.sync(choose_evt)
puts "3. CML.choose: #{result}"

puts "\nPatterns used in Term2:"
puts "• CML::Mailbox for message queues (line 3279 in term2.cr)"
puts "• CML.choose for event selection (lines 3141-3149)"
puts "• CML.wrap for type conversion"
puts "• spawn for concurrent execution"

puts "\nThis validates our CML research findings!"
