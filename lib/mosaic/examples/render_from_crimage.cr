require "../src/mosaic"
require "crimage"

if ARGV.empty?
  STDERR.puts "usage: crystal run examples/render_from_crimage.cr -- <image_path> [width]"
  exit 1
end

path = ARGV[0]
width = (ARGV[1]? || "80").to_i

def to_canvas(img : CrImage::Image) : StumpyCore::Canvas
  b = img.bounds
  canvas = StumpyCore::Canvas.new(b.width, b.height)

  b.min.y.upto(b.max.y - 1) do |y|
    b.min.x.upto(b.max.x - 1) do |x|
      rgba8 = img.at(x, y).to_rgba8
      canvas[x - b.min.x, y - b.min.y] = StumpyCore::RGBA.new(rgba8.r, rgba8.g, rgba8.b, rgba8.a)
    end
  end

  canvas
end

img = CrImage.read(path)
canvas = to_canvas(img)

puts Mosaic.new
  .width(width)
  .dither(true)
  .render(canvas)
