require "./src/mosaic"
require "stumpy_png"

class DebugRenderer < Mosaic::Renderer
  @@block_count = 0

  private def find_best_representation(block : Mosaic::PixelBlock, available_blocks : Array(Mosaic::Block))
    @@block_count += 1
    if @@block_count <= 30
      puts "=== Block #{@@block_count} ==="
      puts "Pixels:"
      pixel_mask = Array.new(2) { Array.new(2, false) }
      2.times do |y|
        2.times do |x|
          pixel = block.pixels[y][x]
          luma = Mosaic.rgba_to_luminance(pixel)
          pixel_mask[y][x] = luma >= @threshold_level
          puts "  (#{x},#{y}): rgba(#{pixel.r},#{pixel.g},#{pixel.b},#{pixel.a}) luma=#{luma} set=#{pixel_mask[y][x]}"
        end
      end

      best_char = ' '
      best_score = Float64::MAX
      available_blocks.each do |block_char|
        score = 0.0
        4.times do |i|
          y = i // 2
          x = i % 2
          if block_char.coverage[y*2 + x] != pixel_mask[y][x]
            score += 1.0
          end
        end
        if score < best_score
          best_score = score
          best_char = block_char.char
        end
      end

      coverage = {false, false, false, false}
      available_blocks.each do |b|
        if b.char == best_char
          coverage = b.coverage
          break
        end
      end

      fg_pixels = [] of StumpyCore::RGBA
      bg_pixels = [] of StumpyCore::RGBA
      4.times do |i|
        y = i // 2
        x = i % 2
        if pixel = block.pixels[y][x]
          if coverage[y*2 + x]
            fg_pixels << pixel
          else
            bg_pixels << pixel
          end
        end
      end

      puts "pixel_mask: #{pixel_mask}"
      puts "best_char: #{best_char} score #{best_score}"
      puts "coverage: #{coverage}"
      puts "fg_pixels: #{fg_pixels.size} bg_pixels: #{bg_pixels.size}"

      # Call original to compute colors
      super

      puts "best_fg_color: rgba(#{block.best_fg_color.r},#{block.best_fg_color.g},#{block.best_fg_color.b},#{block.best_fg_color.a})"
      puts "best_bg_color: rgba(#{block.best_bg_color.r},#{block.best_bg_color.g},#{block.best_bg_color.b},#{block.best_bg_color.a})"
      puts "best_symbol: #{block.best_symbol}"
      puts
    else
      super
    end
  end
end

canvas = StumpyPNG.read("temp/charm-wish.png")
renderer = DebugRenderer.new.width(80).height(40)
_result = renderer.render(canvas)
