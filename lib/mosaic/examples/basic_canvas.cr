require "../src/mosaic"

canvas = StumpyCore::Canvas.new(2, 2)
canvas[0, 0] = StumpyCore::RGBA.new(255, 0, 0, 255)
canvas[1, 0] = StumpyCore::RGBA.new(0, 255, 0, 255)
canvas[0, 1] = StumpyCore::RGBA.new(0, 0, 255, 255)
canvas[1, 1] = StumpyCore::RGBA.new(255, 255, 255, 255)

output = Mosaic.new
  .width(2)
  .height(1)
  .symbol(Mosaic::Symbol::Half)
  .render(canvas)

puts output
