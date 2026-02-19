require "cellwrap"
require "uniwidth"
require "textseg"

require "./view"
require "./color_profile"
require "./renderer"
require "./geometry"
require "./canvas"
require "./layer"
require "./style"
require "./join"
require "./range"
require "./style_table"
require "./wrap"
require "./writer"
require "./query"
require "./lipgloss/tree"
require "./lipgloss/list"

module Lipgloss
  VERSION = "2.0.0-exp"

  struct RGBAColor
    getter r : UInt8
    getter g : UInt8
    getter b : UInt8
    getter a : UInt8

    def initialize(@r : UInt8, @g : UInt8, @b : UInt8, @a : UInt8 = 255_u8)
    end
  end

  # Gets the first UTF-8 rune from a string.
  def self.get_first_rune_as_string(str : String) : String
    return "" if str.empty?
    str[0].to_s
  end

  def self.parse_hex?(hex : String) : RGBAColor?
    return nil if hex.empty? || hex[0] != '#'

    parse_nibble = ->(byte : UInt8) : Int32? do
      case byte
      when '0'.ord.to_u8..'9'.ord.to_u8
        byte.to_i - '0'.ord
      when 'a'.ord.to_u8..'f'.ord.to_u8
        byte.to_i - 'a'.ord + 10
      when 'A'.ord.to_u8..'F'.ord.to_u8
        byte.to_i - 'A'.ord + 10
      else
        nil
      end
    end

    bytes = hex.to_slice
    case bytes.size
    when 7
      r_hi = parse_nibble.call(bytes[1]); return nil unless r_hi
      r_lo = parse_nibble.call(bytes[2]); return nil unless r_lo
      g_hi = parse_nibble.call(bytes[3]); return nil unless g_hi
      g_lo = parse_nibble.call(bytes[4]); return nil unless g_lo
      b_hi = parse_nibble.call(bytes[5]); return nil unless b_hi
      b_lo = parse_nibble.call(bytes[6]); return nil unless b_lo
      r = ((r_hi << 4) + r_lo).to_u8
      g = ((g_hi << 4) + g_lo).to_u8
      b = ((b_hi << 4) + b_lo).to_u8
      RGBAColor.new(r, g, b)
    when 4
      r = parse_nibble.call(bytes[1]); return nil unless r
      g = parse_nibble.call(bytes[2]); return nil unless g
      b = parse_nibble.call(bytes[3]); return nil unless b
      RGBAColor.new((r * 17).to_u8, (g * 17).to_u8, (b * 17).to_u8)
    else
      nil
    end
  end

  def self.color(spec : String) : Color | NoColor
    if spec.starts_with?('#')
      parsed = parse_hex?(spec)
      return NoColor.new unless parsed
      return Color.rgb(parsed.r, parsed.g, parsed.b)
    end

    parsed = spec.to_i?
    return NoColor.new unless parsed

    numeric = parsed.abs
    if numeric < 16
      Color.new(Color::Type::Named, numeric)
    elsif numeric < 256
      Color.indexed(numeric)
    else
      r = (numeric >> 16) & 0xFF
      g = (numeric >> 8) & 0xFF
      b = numeric & 0xFF
      Color.rgb(r, g, b)
    end
  end

  def self.alpha(color : Color | RGBAColor | Nil, alpha : Float64) : RGBAColor?
    return nil if color.nil?
    r, g, b, _a = to_rgba(color)
    alpha_u8 = (clamp(alpha, 0.0, 1.0) * 255.0).to_i.clamp(0, 255).to_u8
    RGBAColor.new(r.to_u8, g.to_u8, b.to_u8, alpha_u8)
  end

  def self.complementary(color : Color | RGBAColor | Nil) : RGBAColor?
    return nil if color.nil?
    r, g, b, a = to_rgba(color)
    a = 255 if a == 0

    hue, saturation, value = rgb_to_hsv(r, g, b)
    hue += 180.0
    hue -= 360.0 if hue >= 360.0
    nr, ng, nb = hsv_to_rgb(hue, saturation, value)
    RGBAColor.new(nr.to_u8, ng.to_u8, nb.to_u8, a.to_u8)
  end

  def self.darken(color : Color | RGBAColor | Nil, percent : Float64) : RGBAColor?
    return nil if color.nil?
    r, g, b, a = to_rgba(color)
    mult = 1.0 - clamp(percent, 0.0, 1.0)
    RGBAColor.new(
      (r * mult).to_i.clamp(0, 255).to_u8,
      (g * mult).to_i.clamp(0, 255).to_u8,
      (b * mult).to_i.clamp(0, 255).to_u8,
      a.clamp(0, 255).to_u8
    )
  end

  def self.lighten(color : Color | RGBAColor | Nil, percent : Float64) : RGBAColor?
    return nil if color.nil?
    r, g, b, a = to_rgba(color)
    add = 255.0 * clamp(percent, 0.0, 1.0)
    RGBAColor.new(
      [255.0, r + add].min.to_i.to_u8,
      [255.0, g + add].min.to_i.to_u8,
      [255.0, b + add].min.to_i.to_u8,
      a.clamp(0, 255).to_u8
    )
  end

  private def self.to_rgba(color : Color | RGBAColor) : {Int32, Int32, Int32, Int32}
    case color
    when Color
      r, g, b = color.to_rgb
      {r, g, b, 255}
    else
      {color.r.to_i, color.g.to_i, color.b.to_i, color.a.to_i}
    end
  end

  private def self.clamp(value : Float64, low : Float64, high : Float64) : Float64
    [high, [low, value].max].min
  end

  private def self.rgb_to_hsv(r : Int32, g : Int32, b : Int32) : {Float64, Float64, Float64}
    rf = r / 255.0
    gf = g / 255.0
    bf = b / 255.0

    c_max = [rf, gf, bf].max
    c_min = [rf, gf, bf].min
    delta = c_max - c_min

    hue =
      if delta == 0.0
        0.0
      elsif c_max == rf
        60.0 * (((gf - bf) / delta) % 6.0)
      elsif c_max == gf
        60.0 * (((bf - rf) / delta) + 2.0)
      else
        60.0 * (((rf - gf) / delta) + 4.0)
      end
    hue += 360.0 if hue < 0.0

    saturation = c_max == 0.0 ? 0.0 : delta / c_max
    {hue, saturation, c_max}
  end

  private def self.hsv_to_rgb(hue : Float64, saturation : Float64, value : Float64) : {Int32, Int32, Int32}
    c = value * saturation
    x = c * (1.0 - (((hue / 60.0) % 2.0) - 1.0).abs)
    m = value - c

    rp, gp, bp =
      case hue
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
      else
        {c, 0.0, x}
      end

    {
      ((rp + m) * 255.0).round.to_i.clamp(0, 255),
      ((gp + m) * 255.0).round.to_i.clamp(0, 255),
      ((bp + m) * 255.0).round.to_i.clamp(0, 255),
    }
  end

  private struct LabColor
    getter l : Float64
    getter a : Float64
    getter b : Float64

    def initialize(@l : Float64, @a : Float64, @b : Float64)
    end
  end

  def self.blend1d(steps : Int32, *stops : Color | RGBAColor | Nil) : Array(RGBAColor)?
    safe_steps = [steps, 0].max
    compact_stops = normalize_stops(stops.to_a)
    blend1d_from_colors(safe_steps, compact_stops)
  end

  def self.blend1d(steps : Int32) : Array(RGBAColor)?
    safe_steps = [steps, 0].max
    return [] of RGBAColor if safe_steps == 0
    nil
  end

  def self.blend2d(width : Int32, height : Int32, angle : Float64, *stops : Color | RGBAColor | Nil) : Array(RGBAColor)?
    safe_width = [width, 1].max
    safe_height = [height, 1].max

    compact_stops = normalize_stops(stops.to_a)
    return nil if compact_stops.empty?

    if compact_stops.size == 1
      single = compact_stops[0]
      return Array.new(safe_width * safe_height, single)
    end

    normalized_angle = angle % 360.0
    normalized_angle += 360.0 if normalized_angle < 0.0

    diagonal_gradient = blend1d_from_colors([safe_width, safe_height].max, compact_stops)
    return nil unless diagonal_gradient

    result = Array(RGBAColor).new(safe_width * safe_height)
    center_x = (safe_width - 1) / 2.0
    center_y = (safe_height - 1) / 2.0
    angle_radians = normalized_angle * Math::PI / 180.0
    cos_angle = Math.cos(angle_radians)
    sin_angle = Math.sin(angle_radians)
    diagonal_length = Math.sqrt((safe_width * safe_width + safe_height * safe_height).to_f)
    gradient_len = (diagonal_gradient.size - 1).to_f

    (0...safe_height).each do |row_index|
      dy = row_index.to_f - center_y
      (0...safe_width).each do |column_index|
        dx = column_index.to_f - center_x
        rotated_x = dx * cos_angle - dy * sin_angle
        gradient_pos = clamp((rotated_x + diagonal_length / 2.0) / diagonal_length, 0.0, 1.0)
        gradient_index = (gradient_pos * gradient_len).to_i
        gradient_index = [gradient_index, diagonal_gradient.size - 1].min
        result << diagonal_gradient[gradient_index]
      end
    end

    result
  end

  def self.blend2d(width : Int32, height : Int32, angle : Float64) : Array(RGBAColor)?
    nil
  end

  private def self.ensure_not_transparent(color : Color | RGBAColor) : RGBAColor
    rgba = to_rgba_color(color)
    return RGBAColor.new(rgba.r, rgba.g, rgba.b, 255_u8) if rgba.a == 0_u8
    rgba
  end

  private def self.normalize_stops(stops : Array(Color | RGBAColor | Nil)) : Array(RGBAColor)
    normalized = [] of RGBAColor
    stops.each do |stop_value|
      next if stop_value.nil?
      case stop_value
      when Color
        normalized << ensure_not_transparent(stop_value)
      when RGBAColor
        normalized << stop_value
      end
    end
    normalized
  end

  private def self.blend1d_from_colors(steps : Int32, stops : Array(RGBAColor)) : Array(RGBAColor)?
    return [] of RGBAColor if steps == 0
    return nil if stops.empty?

    if steps <= stops.size
      return stops.first(steps)
    end

    if stops.size == 1
      single = stops[0]
      return Array.new(steps, single)
    end

    lab_stops = stops.map { |stop| rgb_to_lab(*to_rgb_triplet(stop)) }
    segments = lab_stops.size - 1
    default_size = steps // segments
    remaining_steps = steps % segments
    blended = Array(RGBAColor).new(steps)

    (0...segments).each do |segment_index|
      from = lab_stops[segment_index]
      to = lab_stops[segment_index + 1]
      segment_size = default_size + (segment_index < remaining_steps ? 1 : 0)
      divisor = (segment_size - 1).to_f

      (0...segment_size).each do |step_index|
        blend_factor = segment_size > 1 ? step_index.to_f / divisor : 0.0
        l = from.l + (to.l - from.l) * blend_factor
        a = from.a + (to.a - from.a) * blend_factor
        b = from.b + (to.b - from.b) * blend_factor
        blended << lab_to_rgb(l, a, b)
      end
    end

    blended.first(steps)
  end

  private def self.to_rgb_triplet(color : RGBAColor) : {Float64, Float64, Float64}
    {color.r.to_f / 255.0, color.g.to_f / 255.0, color.b.to_f / 255.0}
  end

  private def self.to_rgba_color(color : Color | RGBAColor) : RGBAColor
    case color
    when Color
      r, g, b = color.to_rgb
      RGBAColor.new(r.to_u8, g.to_u8, b.to_u8, 255_u8)
    else
      color
    end
  end

  private def self.rgb_to_lab(r : Float64, g : Float64, b : Float64) : LabColor
    r_lin = srgb_to_linear(r)
    g_lin = srgb_to_linear(g)
    b_lin = srgb_to_linear(b)

    x = r_lin * 0.4124564 + g_lin * 0.3575761 + b_lin * 0.1804375
    y = r_lin * 0.2126729 + g_lin * 0.7151522 + b_lin * 0.0721750
    z = r_lin * 0.0193339 + g_lin * 0.1191920 + b_lin * 0.9503041

    fx = xyz_pivot(x / 0.95047)
    fy = xyz_pivot(y / 1.00000)
    fz = xyz_pivot(z / 1.08883)

    l = (116.0 * fy) - 16.0
    a = 500.0 * (fx - fy)
    b_value = 200.0 * (fy - fz)
    LabColor.new(l, a, b_value)
  end

  private def self.lab_to_rgb(l : Float64, a : Float64, b : Float64) : RGBAColor
    fy = (l + 16.0) / 116.0
    fx = (a / 500.0) + fy
    fz = fy - (b / 200.0)

    x = 0.95047 * xyz_inverse_pivot(fx)
    y = 1.00000 * xyz_inverse_pivot(fy)
    z = 1.08883 * xyz_inverse_pivot(fz)

    r_lin = (3.2404542 * x) + (-1.5371385 * y) + (-0.4985314 * z)
    g_lin = (-0.9692660 * x) + (1.8760108 * y) + (0.0415560 * z)
    b_lin = (0.0556434 * x) + (-0.2040259 * y) + (1.0572252 * z)

    r = linear_to_srgb(r_lin)
    g = linear_to_srgb(g_lin)
    b_value = linear_to_srgb(b_lin)

    RGBAColor.new(
      float_channel_to_u8(r),
      float_channel_to_u8(g),
      float_channel_to_u8(b_value),
      255_u8
    )
  end

  private def self.srgb_to_linear(value : Float64) : Float64
    if value <= 0.04045
      value / 12.92
    else
      ((value + 0.055) / 1.055) ** 2.4
    end
  end

  private def self.linear_to_srgb(value : Float64) : Float64
    clamped = clamp(value, 0.0, 1.0)
    if clamped <= 0.0031308
      12.92 * clamped
    else
      (1.055 * (clamped ** (1.0 / 2.4))) - 0.055
    end
  end

  private def self.xyz_pivot(value : Float64) : Float64
    epsilon = 216.0 / 24389.0
    kappa = 24389.0 / 27.0
    if value > epsilon
      value ** (1.0 / 3.0)
    else
      ((kappa * value) + 16.0) / 116.0
    end
  end

  private def self.xyz_inverse_pivot(value : Float64) : Float64
    epsilon = 216.0 / 24389.0
    kappa = 24389.0 / 27.0
    cube = value ** 3
    if cube > epsilon
      cube
    else
      ((116.0 * value) - 16.0) / kappa
    end
  end

  private def self.float_channel_to_u8(value : Float64) : UInt8
    clamped = clamp(value, 0.0, 1.0)
    (((clamped * 65535.0) + 0.5).to_i >> 8).clamp(0, 255).to_u8
  end
end
