require "spec"
require "../src/teatest"

def read_bytes(r : IO) : Bytes
  IO::Memory.new.tap { |io| IO.copy(r, io) }.to_slice
end
