require "./src/mosaic"
require "stumpy_png"

canvas = StumpyPNG.read("temp/charm-wish.png")

# Create a debug renderer
class DebugRenderer < Mosaic::Renderer
  @@count = 0

  private def ansi_style(fg : StumpyCore::RGBA, bg : StumpyCore::RGBA, char : Char) : String
    # Print first few colored blocks
    if @@count < 20 && (fg.r > 0 || fg.g > 0 || fg.b > 0 || bg.r > 0 || bg.g > 0 || bg.b > 0)
      puts "Block #{@@count}: fg=(#{fg.r},#{fg.g},#{fg.b}) bg=(#{bg.r},#{bg.g},#{bg.b}) char=#{char}"
      puts "  fg as u8: (#{fg.r.to_u8},#{fg.g.to_u8},#{fg.b.to_u8})"
      puts "  fg >> 8: (#{fg.r >> 8},#{fg.g >> 8},#{fg.b >> 8})"
    end
    @@count += 1
    super
  end
end

renderer = DebugRenderer.new.width(80).height(40)
_result = renderer.render(canvas)
