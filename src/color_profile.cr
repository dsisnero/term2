require "./base_types"
require "lipgloss"

module Term2
  # ColorProfile provides color profile management and color space conversions.
  #
  # This module enhances the existing color system with dark/light mode detection
  # and color space conversion utilities.
  module ColorProfile
    extend self

    # Detect background color from COLORFGBG environment variable.
    # Returns a Lipgloss::Color if detection succeeds, nil otherwise.
    def detect_background_color_from_env : Lipgloss::Color?
      colorfg = ENV["COLORFGBG"]?
      return unless colorfg

      # Format is "foreground;background" or "foreground;background;something"
      parts = colorfg.split(';')
      return if parts.size < 2

      bg_str = parts[1].strip
      bg_index = bg_str.to_i? rescue nil
      return unless bg_index

      # COLORFGBG uses ANSI color indices (0-15 for standard colors)
      # Some terminals may use 0-255 for indexed colors.
      # We'll treat as indexed color (0-255) and let conversion handle it.
      Lipgloss::Color.indexed(bg_index)
    end

    # Detect if terminal background is dark based on COLORFGBG.
    # Returns true if background is dark, false if light, nil if unknown.
    def dark_background_from_env? : Bool?
      bg_color = detect_background_color_from_env
      return unless bg_color

      # Use existing luminance detection from Environ
      Environ.has_dark_background?(bg_color)
    end

    # Update global dark/light mode setting based on detected background.
    # Should be called during program initialization.
    def update_dark_mode_from_env : Nil
      bg_color = detect_background_color_from_env
      return unless bg_color

      Environ.update_dark_mode_from_background(bg_color)
    end

    # Color space conversion utilities
    # RGB to HSL conversion
    # Returns (h, s, l) where h in degrees 0-360, s and l in 0-1
    def rgb_to_hsl(r : Int32, g : Int32, b : Int32) : Tuple(Float64, Float64, Float64)
      r_norm = r / 255.0
      g_norm = g / 255.0
      b_norm = b / 255.0

      max = Math.max(r_norm, Math.max(g_norm, b_norm))
      min = Math.min(r_norm, Math.min(g_norm, b_norm))
      delta = max - min

      lightness = (max + min) / 2.0

      if delta == 0.0
        hue = 0.0
        saturation = 0.0
      else
        saturation = delta / (1.0 - (2.0 * lightness - 1.0).abs)

        case max
        when r_norm
          hue = (g_norm - b_norm) / delta
          hue += 6.0 if hue < 0.0
        when g_norm
          hue = (b_norm - r_norm) / delta + 2.0
        when b_norm
          hue = (r_norm - g_norm) / delta + 4.0
        else
          hue = 0.0
        end
        hue *= 60.0
      end

      {hue, saturation, lightness}
    end

    # HSL to RGB conversion
    # h in degrees 0-360, s and l in 0-1
    def hsl_to_rgb(h : Float64, s : Float64, l : Float64) : Tuple(Int32, Int32, Int32)
      c = (1.0 - (2.0 * l - 1.0).abs) * s
      x = c * (1.0 - ((h / 60.0) % 2.0 - 1.0).abs)
      m = l - c / 2.0

      r1, g1, b1 = case h
                   when 0.0...60.0
                     {c, x, 0.0}
                   when 60.0...120.0
                     {x, c, 0.0}
                   when 120.0...180.0
                     {0.0, c, x}
                   when 180.0...240.0
                     {0.0, x, c}
                   when 240.0...300.0
                     {x, 0.0, c}
                   else # 300.0...360.0
                     {c, 0.0, x}
                   end

      r = ((r1 + m) * 255).round.to_i.clamp(0, 255)
      g = ((g1 + m) * 255).round.to_i.clamp(0, 255)
      b = ((b1 + m) * 255).round.to_i.clamp(0, 255)

      {r, g, b}
    end

    # RGB to HSV conversion
    # Returns (h, s, v) where h in degrees 0-360, s and v in 0-1
    def rgb_to_hsv(r : Int32, g : Int32, b : Int32) : Tuple(Float64, Float64, Float64)
      r_norm = r / 255.0
      g_norm = g / 255.0
      b_norm = b / 255.0

      max = Math.max(r_norm, Math.max(g_norm, b_norm))
      min = Math.min(r_norm, Math.min(g_norm, b_norm))
      delta = max - min

      value = max
      saturation = max == 0.0 ? 0.0 : delta / max

      hue = if delta == 0.0
              0.0
            else
              case max
              when r_norm
                ((g_norm - b_norm) / delta) % 6.0
              when g_norm
                (b_norm - r_norm) / delta + 2.0
              when b_norm
                (r_norm - g_norm) / delta + 4.0
              else
                0.0
              end * 60.0
            end

      hue = hue % 360.0
      {hue, saturation, value}
    end

    # HSV to RGB conversion
    # h in degrees 0-360, s and v in 0-1
    def hsv_to_rgb(h : Float64, s : Float64, v : Float64) : Tuple(Int32, Int32, Int32)
      c = v * s
      x = c * (1.0 - ((h / 60.0) % 2.0 - 1.0).abs)
      m = v - c

      r1, g1, b1 = case h
                   when 0.0...60.0
                     {c, x, 0.0}
                   when 60.0...120.0
                     {x, c, 0.0}
                   when 120.0...180.0
                     {0.0, c, x}
                   when 180.0...240.0
                     {0.0, x, c}
                   when 240.0...300.0
                     {x, 0.0, c}
                   else # 300.0...360.0
                     {c, 0.0, x}
                   end

      r = ((r1 + m) * 255).round.to_i.clamp(0, 255)
      g = ((g1 + m) * 255).round.to_i.clamp(0, 255)
      b = ((b1 + m) * 255).round.to_i.clamp(0, 255)

      {r, g, b}
    end

    # RGB to CMYK conversion
    # Returns (c, m, y, k) where each component in 0-1 range
    def rgb_to_cmyk(r : Int32, g : Int32, b : Int32) : Tuple(Float64, Float64, Float64, Float64)
      r_norm = r / 255.0
      g_norm = g / 255.0
      b_norm = b / 255.0

      k = 1.0 - Math.max(r_norm, Math.max(g_norm, b_norm))
      return {0.0, 0.0, 0.0, 1.0} if k == 1.0

      c = (1.0 - r_norm - k) / (1.0 - k)
      m = (1.0 - g_norm - k) / (1.0 - k)
      y = (1.0 - b_norm - k) / (1.0 - k)

      {c, m, y, k}
    end

    # CMYK to RGB conversion
    # c, m, y, k in 0-1 range
    def cmyk_to_rgb(c : Float64, m : Float64, y : Float64, k : Float64) : Tuple(Int32, Int32, Int32)
      r = 255 * (1.0 - c) * (1.0 - k)
      g = 255 * (1.0 - m) * (1.0 - k)
      b = 255 * (1.0 - y) * (1.0 - k)

      {r.round.to_i.clamp(0, 255), g.round.to_i.clamp(0, 255), b.round.to_i.clamp(0, 255)}
    end
  end
end
