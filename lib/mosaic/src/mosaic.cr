require "stumpy_core"

module Mosaic
  VERSION = "0.1.0"

  # Symbol represents the symbol type to use when rendering the image.
  enum Symbol
    All
    Half
    Quarter
  end

  # Block represents different Unicode block characters.
  struct Block
    property char : Char
    property coverage : Tuple(Bool, Bool, Bool, Bool) # TL, TR, BL, BR (top-left, top-right, bottom-left, bottom-right)
    property coverage_map : String                    # Visual representation of coverage for debugging.

    def initialize(@char : Char, @coverage : Tuple(Bool, Bool, Bool, Bool), @coverage_map : String)
    end
  end

  # Half blocks (▀, ▄, space, █)
  HALF_BLOCKS = [
    Block.new('▀', {true, true, false, false}, "██\n  "),   # Upper half block.
    Block.new('▄', {false, false, true, true}, "  \n██"),   # Lower half block.
    Block.new(' ', {false, false, false, false}, "  \n  "), # Space.
    Block.new('█', {true, true, true, true}, "██\n██"),     # Full block.
  ]

  # Quarter blocks
  QUARTER_BLOCKS = [
    Block.new('▘', {true, false, false, false}, "█ \n  "), # Quadrant upper left.
    Block.new('▝', {false, true, false, false}, " █\n  "), # Quadrant upper right.
    Block.new('▖', {false, false, true, false}, "  \n█ "), # Quadrant lower left.
    Block.new('▗', {false, false, false, true}, "  \n █"), # Quadrant lower right.
    Block.new('▌', {true, false, true, false}, "█ \n█ "),  # Left half block.
    Block.new('▐', {false, true, false, true}, " █\n █"),  # Right half block.
    Block.new('▀', {true, true, false, false}, "██\n  "),  # Upper half block (already added).
    Block.new('▄', {false, false, true, true}, "  \n██"),  # Lower half block (already added).
  ]

  # Complex blocks
  COMPLEX_BLOCKS = [
    Block.new('▙', {true, false, true, true}, "█ \n██"),  # Quadrant upper left and lower half.
    Block.new('▟', {false, true, true, true}, " █\n██"),  # Quadrant upper right and lower half.
    Block.new('▛', {true, true, true, false}, "██\n█ "),  # Quadrant upper half and lower left.
    Block.new('▜', {true, true, false, true}, "██\n █"),  # Quadrant upper half and lower right.
    Block.new('▚', {true, false, false, true}, "█ \n █"), # Quadrant upper left and lower right.
    Block.new('▞', {false, true, true, false}, " █\n█ "), # Quadrant upper right and lower left.
  ]

  # Plan9 palette (256 colors) from Go's image/color/palette package
  PLAN9_PALETTE = [
    StumpyCore::RGBA.new(0_u8, 0_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 0_u8, 68_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 0_u8, 136_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 0_u8, 204_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 68_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 68_u8, 68_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 68_u8, 136_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 68_u8, 204_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 136_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 136_u8, 68_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 136_u8, 136_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 136_u8, 204_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 204_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 204_u8, 68_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 204_u8, 136_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 204_u8, 204_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 221_u8, 221_u8, 255_u8),
    StumpyCore::RGBA.new(17_u8, 17_u8, 17_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 0_u8, 85_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 0_u8, 153_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 0_u8, 221_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 85_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 85_u8, 85_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 76_u8, 153_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 73_u8, 221_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 153_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 153_u8, 76_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 153_u8, 153_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 147_u8, 221_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 221_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 221_u8, 73_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 221_u8, 147_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 238_u8, 158_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 238_u8, 238_u8, 255_u8),
    StumpyCore::RGBA.new(34_u8, 34_u8, 34_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 0_u8, 102_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 0_u8, 170_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 0_u8, 238_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 102_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 102_u8, 102_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 85_u8, 170_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 79_u8, 238_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 170_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 170_u8, 85_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 170_u8, 170_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 158_u8, 238_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 238_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 238_u8, 79_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 255_u8, 85_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 255_u8, 170_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 255_u8, 255_u8, 255_u8),
    StumpyCore::RGBA.new(51_u8, 51_u8, 51_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 0_u8, 119_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 0_u8, 187_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 0_u8, 255_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 119_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 119_u8, 119_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 93_u8, 187_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 85_u8, 255_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 187_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 187_u8, 93_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 187_u8, 187_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 170_u8, 255_u8, 255_u8),
    StumpyCore::RGBA.new(0_u8, 255_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(68_u8, 0_u8, 68_u8, 255_u8),
    StumpyCore::RGBA.new(68_u8, 0_u8, 136_u8, 255_u8),
    StumpyCore::RGBA.new(68_u8, 0_u8, 204_u8, 255_u8),
    StumpyCore::RGBA.new(68_u8, 68_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(68_u8, 68_u8, 68_u8, 255_u8),
    StumpyCore::RGBA.new(68_u8, 68_u8, 136_u8, 255_u8),
    StumpyCore::RGBA.new(68_u8, 68_u8, 204_u8, 255_u8),
    StumpyCore::RGBA.new(68_u8, 136_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(68_u8, 136_u8, 68_u8, 255_u8),
    StumpyCore::RGBA.new(68_u8, 136_u8, 136_u8, 255_u8),
    StumpyCore::RGBA.new(68_u8, 136_u8, 204_u8, 255_u8),
    StumpyCore::RGBA.new(68_u8, 204_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(68_u8, 204_u8, 68_u8, 255_u8),
    StumpyCore::RGBA.new(68_u8, 204_u8, 136_u8, 255_u8),
    StumpyCore::RGBA.new(68_u8, 204_u8, 204_u8, 255_u8),
    StumpyCore::RGBA.new(68_u8, 0_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(85_u8, 0_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(85_u8, 0_u8, 85_u8, 255_u8),
    StumpyCore::RGBA.new(76_u8, 0_u8, 153_u8, 255_u8),
    StumpyCore::RGBA.new(73_u8, 0_u8, 221_u8, 255_u8),
    StumpyCore::RGBA.new(85_u8, 85_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(85_u8, 85_u8, 85_u8, 255_u8),
    StumpyCore::RGBA.new(76_u8, 76_u8, 153_u8, 255_u8),
    StumpyCore::RGBA.new(73_u8, 73_u8, 221_u8, 255_u8),
    StumpyCore::RGBA.new(76_u8, 153_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(76_u8, 153_u8, 76_u8, 255_u8),
    StumpyCore::RGBA.new(76_u8, 153_u8, 153_u8, 255_u8),
    StumpyCore::RGBA.new(73_u8, 147_u8, 221_u8, 255_u8),
    StumpyCore::RGBA.new(73_u8, 221_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(73_u8, 221_u8, 73_u8, 255_u8),
    StumpyCore::RGBA.new(73_u8, 221_u8, 147_u8, 255_u8),
    StumpyCore::RGBA.new(73_u8, 221_u8, 221_u8, 255_u8),
    StumpyCore::RGBA.new(79_u8, 238_u8, 238_u8, 255_u8),
    StumpyCore::RGBA.new(102_u8, 0_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(102_u8, 0_u8, 102_u8, 255_u8),
    StumpyCore::RGBA.new(85_u8, 0_u8, 170_u8, 255_u8),
    StumpyCore::RGBA.new(79_u8, 0_u8, 238_u8, 255_u8),
    StumpyCore::RGBA.new(102_u8, 102_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(102_u8, 102_u8, 102_u8, 255_u8),
    StumpyCore::RGBA.new(85_u8, 85_u8, 170_u8, 255_u8),
    StumpyCore::RGBA.new(79_u8, 79_u8, 238_u8, 255_u8),
    StumpyCore::RGBA.new(85_u8, 170_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(85_u8, 170_u8, 85_u8, 255_u8),
    StumpyCore::RGBA.new(85_u8, 170_u8, 170_u8, 255_u8),
    StumpyCore::RGBA.new(79_u8, 158_u8, 238_u8, 255_u8),
    StumpyCore::RGBA.new(79_u8, 238_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(79_u8, 238_u8, 79_u8, 255_u8),
    StumpyCore::RGBA.new(79_u8, 238_u8, 158_u8, 255_u8),
    StumpyCore::RGBA.new(85_u8, 255_u8, 170_u8, 255_u8),
    StumpyCore::RGBA.new(85_u8, 255_u8, 255_u8, 255_u8),
    StumpyCore::RGBA.new(119_u8, 0_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(119_u8, 0_u8, 119_u8, 255_u8),
    StumpyCore::RGBA.new(93_u8, 0_u8, 187_u8, 255_u8),
    StumpyCore::RGBA.new(85_u8, 0_u8, 255_u8, 255_u8),
    StumpyCore::RGBA.new(119_u8, 119_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(119_u8, 119_u8, 119_u8, 255_u8),
    StumpyCore::RGBA.new(93_u8, 93_u8, 187_u8, 255_u8),
    StumpyCore::RGBA.new(85_u8, 85_u8, 255_u8, 255_u8),
    StumpyCore::RGBA.new(93_u8, 187_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(93_u8, 187_u8, 93_u8, 255_u8),
    StumpyCore::RGBA.new(93_u8, 187_u8, 187_u8, 255_u8),
    StumpyCore::RGBA.new(85_u8, 170_u8, 255_u8, 255_u8),
    StumpyCore::RGBA.new(85_u8, 255_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(85_u8, 255_u8, 85_u8, 255_u8),
    StumpyCore::RGBA.new(136_u8, 0_u8, 136_u8, 255_u8),
    StumpyCore::RGBA.new(136_u8, 0_u8, 204_u8, 255_u8),
    StumpyCore::RGBA.new(136_u8, 68_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(136_u8, 68_u8, 68_u8, 255_u8),
    StumpyCore::RGBA.new(136_u8, 68_u8, 136_u8, 255_u8),
    StumpyCore::RGBA.new(136_u8, 68_u8, 204_u8, 255_u8),
    StumpyCore::RGBA.new(136_u8, 136_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(136_u8, 136_u8, 68_u8, 255_u8),
    StumpyCore::RGBA.new(136_u8, 136_u8, 136_u8, 255_u8),
    StumpyCore::RGBA.new(136_u8, 136_u8, 204_u8, 255_u8),
    StumpyCore::RGBA.new(136_u8, 204_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(136_u8, 204_u8, 68_u8, 255_u8),
    StumpyCore::RGBA.new(136_u8, 204_u8, 136_u8, 255_u8),
    StumpyCore::RGBA.new(136_u8, 204_u8, 204_u8, 255_u8),
    StumpyCore::RGBA.new(136_u8, 0_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(136_u8, 0_u8, 68_u8, 255_u8),
    StumpyCore::RGBA.new(153_u8, 0_u8, 76_u8, 255_u8),
    StumpyCore::RGBA.new(153_u8, 0_u8, 153_u8, 255_u8),
    StumpyCore::RGBA.new(147_u8, 0_u8, 221_u8, 255_u8),
    StumpyCore::RGBA.new(153_u8, 76_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(153_u8, 76_u8, 76_u8, 255_u8),
    StumpyCore::RGBA.new(153_u8, 76_u8, 153_u8, 255_u8),
    StumpyCore::RGBA.new(147_u8, 73_u8, 221_u8, 255_u8),
    StumpyCore::RGBA.new(153_u8, 153_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(153_u8, 153_u8, 76_u8, 255_u8),
    StumpyCore::RGBA.new(153_u8, 153_u8, 153_u8, 255_u8),
    StumpyCore::RGBA.new(147_u8, 147_u8, 221_u8, 255_u8),
    StumpyCore::RGBA.new(147_u8, 221_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(147_u8, 221_u8, 73_u8, 255_u8),
    StumpyCore::RGBA.new(147_u8, 221_u8, 147_u8, 255_u8),
    StumpyCore::RGBA.new(147_u8, 221_u8, 221_u8, 255_u8),
    StumpyCore::RGBA.new(153_u8, 0_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(170_u8, 0_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(170_u8, 0_u8, 85_u8, 255_u8),
    StumpyCore::RGBA.new(170_u8, 0_u8, 170_u8, 255_u8),
    StumpyCore::RGBA.new(158_u8, 0_u8, 238_u8, 255_u8),
    StumpyCore::RGBA.new(170_u8, 85_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(170_u8, 85_u8, 85_u8, 255_u8),
    StumpyCore::RGBA.new(170_u8, 85_u8, 170_u8, 255_u8),
    StumpyCore::RGBA.new(158_u8, 79_u8, 238_u8, 255_u8),
    StumpyCore::RGBA.new(170_u8, 170_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(170_u8, 170_u8, 85_u8, 255_u8),
    StumpyCore::RGBA.new(170_u8, 170_u8, 170_u8, 255_u8),
    StumpyCore::RGBA.new(158_u8, 158_u8, 238_u8, 255_u8),
    StumpyCore::RGBA.new(158_u8, 238_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(158_u8, 238_u8, 79_u8, 255_u8),
    StumpyCore::RGBA.new(158_u8, 238_u8, 158_u8, 255_u8),
    StumpyCore::RGBA.new(158_u8, 238_u8, 238_u8, 255_u8),
    StumpyCore::RGBA.new(170_u8, 255_u8, 255_u8, 255_u8),
    StumpyCore::RGBA.new(187_u8, 0_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(187_u8, 0_u8, 93_u8, 255_u8),
    StumpyCore::RGBA.new(187_u8, 0_u8, 187_u8, 255_u8),
    StumpyCore::RGBA.new(170_u8, 0_u8, 255_u8, 255_u8),
    StumpyCore::RGBA.new(187_u8, 93_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(187_u8, 93_u8, 93_u8, 255_u8),
    StumpyCore::RGBA.new(187_u8, 93_u8, 187_u8, 255_u8),
    StumpyCore::RGBA.new(170_u8, 85_u8, 255_u8, 255_u8),
    StumpyCore::RGBA.new(187_u8, 187_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(187_u8, 187_u8, 93_u8, 255_u8),
    StumpyCore::RGBA.new(187_u8, 187_u8, 187_u8, 255_u8),
    StumpyCore::RGBA.new(170_u8, 170_u8, 255_u8, 255_u8),
    StumpyCore::RGBA.new(170_u8, 255_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(170_u8, 255_u8, 85_u8, 255_u8),
    StumpyCore::RGBA.new(170_u8, 255_u8, 170_u8, 255_u8),
    StumpyCore::RGBA.new(204_u8, 0_u8, 204_u8, 255_u8),
    StumpyCore::RGBA.new(204_u8, 68_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(204_u8, 68_u8, 68_u8, 255_u8),
    StumpyCore::RGBA.new(204_u8, 68_u8, 136_u8, 255_u8),
    StumpyCore::RGBA.new(204_u8, 68_u8, 204_u8, 255_u8),
    StumpyCore::RGBA.new(204_u8, 136_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(204_u8, 136_u8, 68_u8, 255_u8),
    StumpyCore::RGBA.new(204_u8, 136_u8, 136_u8, 255_u8),
    StumpyCore::RGBA.new(204_u8, 136_u8, 204_u8, 255_u8),
    StumpyCore::RGBA.new(204_u8, 204_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(204_u8, 204_u8, 68_u8, 255_u8),
    StumpyCore::RGBA.new(204_u8, 204_u8, 136_u8, 255_u8),
    StumpyCore::RGBA.new(204_u8, 204_u8, 204_u8, 255_u8),
    StumpyCore::RGBA.new(204_u8, 0_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(204_u8, 0_u8, 68_u8, 255_u8),
    StumpyCore::RGBA.new(204_u8, 0_u8, 136_u8, 255_u8),
    StumpyCore::RGBA.new(221_u8, 0_u8, 147_u8, 255_u8),
    StumpyCore::RGBA.new(221_u8, 0_u8, 221_u8, 255_u8),
    StumpyCore::RGBA.new(221_u8, 73_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(221_u8, 73_u8, 73_u8, 255_u8),
    StumpyCore::RGBA.new(221_u8, 73_u8, 147_u8, 255_u8),
    StumpyCore::RGBA.new(221_u8, 73_u8, 221_u8, 255_u8),
    StumpyCore::RGBA.new(221_u8, 147_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(221_u8, 147_u8, 73_u8, 255_u8),
    StumpyCore::RGBA.new(221_u8, 147_u8, 147_u8, 255_u8),
    StumpyCore::RGBA.new(221_u8, 147_u8, 221_u8, 255_u8),
    StumpyCore::RGBA.new(221_u8, 221_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(221_u8, 221_u8, 73_u8, 255_u8),
    StumpyCore::RGBA.new(221_u8, 221_u8, 147_u8, 255_u8),
    StumpyCore::RGBA.new(221_u8, 221_u8, 221_u8, 255_u8),
    StumpyCore::RGBA.new(221_u8, 0_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(221_u8, 0_u8, 73_u8, 255_u8),
    StumpyCore::RGBA.new(238_u8, 0_u8, 79_u8, 255_u8),
    StumpyCore::RGBA.new(238_u8, 0_u8, 158_u8, 255_u8),
    StumpyCore::RGBA.new(238_u8, 0_u8, 238_u8, 255_u8),
    StumpyCore::RGBA.new(238_u8, 79_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(238_u8, 79_u8, 79_u8, 255_u8),
    StumpyCore::RGBA.new(238_u8, 79_u8, 158_u8, 255_u8),
    StumpyCore::RGBA.new(238_u8, 79_u8, 238_u8, 255_u8),
    StumpyCore::RGBA.new(238_u8, 158_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(238_u8, 158_u8, 79_u8, 255_u8),
    StumpyCore::RGBA.new(238_u8, 158_u8, 158_u8, 255_u8),
    StumpyCore::RGBA.new(238_u8, 158_u8, 238_u8, 255_u8),
    StumpyCore::RGBA.new(238_u8, 238_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(238_u8, 238_u8, 79_u8, 255_u8),
    StumpyCore::RGBA.new(238_u8, 238_u8, 158_u8, 255_u8),
    StumpyCore::RGBA.new(238_u8, 238_u8, 238_u8, 255_u8),
    StumpyCore::RGBA.new(238_u8, 0_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(255_u8, 0_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(255_u8, 0_u8, 85_u8, 255_u8),
    StumpyCore::RGBA.new(255_u8, 0_u8, 170_u8, 255_u8),
    StumpyCore::RGBA.new(255_u8, 0_u8, 255_u8, 255_u8),
    StumpyCore::RGBA.new(255_u8, 85_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(255_u8, 85_u8, 85_u8, 255_u8),
    StumpyCore::RGBA.new(255_u8, 85_u8, 170_u8, 255_u8),
    StumpyCore::RGBA.new(255_u8, 85_u8, 255_u8, 255_u8),
    StumpyCore::RGBA.new(255_u8, 170_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(255_u8, 170_u8, 85_u8, 255_u8),
    StumpyCore::RGBA.new(255_u8, 170_u8, 170_u8, 255_u8),
    StumpyCore::RGBA.new(255_u8, 170_u8, 255_u8, 255_u8),
    StumpyCore::RGBA.new(255_u8, 255_u8, 0_u8, 255_u8),
    StumpyCore::RGBA.new(255_u8, 255_u8, 85_u8, 255_u8),
    StumpyCore::RGBA.new(255_u8, 255_u8, 170_u8, 255_u8),
    StumpyCore::RGBA.new(255_u8, 255_u8, 255_u8, 255_u8),
  ]

  # In many contexts, a default threshold level is often set to 0.5 (or 50%),
  # which means that values above this threshold are considered positive,
  # while those below are considered negative.
  # The value 128 represents the 0.5 of 0..255.
  MIDDLE_THRESHOLD_LEVEL = 128_u8

  # Represents 255.
  U8_MAX_VALUE = 0xff_u32

  # Shift scales 16-bit color values (0-65535) down to 8-bit (0-255).
  # If value > 255, shift right by 8 bits.
  def self.shift(value : UInt32) : UInt32
    value > U8_MAX_VALUE ? value >> 8 : value
  end

  # premultiplied_16bit returns premultiplied 16-bit components (RGBA) from a color.
  # This mimics Go's color.Color.RGBA() which returns premultiplied values.
  def self.premultiplied_16bit(color : StumpyCore::RGBA) : Tuple(UInt16, UInt16, UInt16, UInt16)
    r = color.r.to_u64
    g = color.g.to_u64
    b = color.b.to_u64
    a = color.a.to_u64

    # Scale 8-bit values to 16-bit if necessary (Go's RGBA() returns 16-bit values)
    if a <= 255
      r *= 257
      g *= 257
      b *= 257
      a *= 257
    end

    # premultiply: component = component * a / 65535
    r = (r * a) // 65535
    g = (g * a) // 65535
    b = (b * a) // 65535
    {r.to_u16, g.to_u16, b.to_u16, a.to_u16}
  end

  # premultiplied_shift returns premultiplied 8-bit components (RGBA) from a color.
  # This mimics Go's color.Color.RGBA() which returns premultiplied values.
  def self.premultiplied_shift(color : StumpyCore::RGBA) : Tuple(UInt8, UInt8, UInt8, UInt8)
    r = color.r.to_u64
    g = color.g.to_u64
    b = color.b.to_u64
    a = color.a.to_u64
    # premultiply: component = component * a / 65535
    r = (r * a) // 65535
    g = (g * a) // 65535
    b = (b * a) // 65535
    # shift to 8-bit
    r = shift(r.to_u32)
    g = shift(g.to_u32)
    b = shift(b.to_u32)
    a = shift(a.to_u32)
    {r.to_u8, g.to_u8, b.to_u8, a.to_u8}
  end

  # shift_color returns 8-bit components from a premultiplied color.
  # This mimics Go's shift function applied to RGBA() values.
  def self.shift_color(color : StumpyCore::RGBA) : Tuple(UInt8, UInt8, UInt8, UInt8)
    r = shift(color.r.to_u32)
    g = shift(color.g.to_u32)
    b = shift(color.b.to_u32)
    a = shift(color.a.to_u32)
    {r.to_u8, g.to_u8, b.to_u8, a.to_u8}
  end

  # rgba_to_luminance converts RGBA color to luminance (brightness).
  # Weighted RGB to account for human perception
  # source: https://www.w3.org/TR/AERT/#color-contrast
  # context: https://stackoverflow.com/questions/596216/formula-to-determine-perceived-brightness-of-rgb-color
  def self.rgba_to_luminance(color : StumpyCore::RGBA) : UInt8
    r, g, b, _ = shift_color(color)
    (r.to_f64 * 0.299 + g.to_f64 * 0.587 + b.to_f64 * 0.114).to_u8
  end

  # PixelBlock represents a 2x2 pixel block from the image.
  class PixelBlock
    property pixels : Array(Array(StumpyCore::RGBA))
    property avg_fg : StumpyCore::RGBA
    property avg_bg : StumpyCore::RGBA
    property best_symbol : Char
    property best_fg_color : StumpyCore::RGBA
    property best_bg_color : StumpyCore::RGBA

    def initialize
      @pixels = Array.new(2) { Array.new(2, StumpyCore::RGBA.new(0, 0, 0, 255)) }
      @avg_fg = StumpyCore::RGBA.new(0, 0, 0, 255)
      @avg_bg = StumpyCore::RGBA.new(0, 0, 0, 255)
      @best_symbol = ' '
      @best_fg_color = StumpyCore::RGBA.new(0, 0, 0, 255)
      @best_bg_color = StumpyCore::RGBA.new(0, 0, 0, 255)
    end
  end

  # Mosaic represents a Unicode image renderer.
  #
  # Example:
  #
  # ```
  # art = Mosaic::Renderer.new.width(100) # Limit to 100 cells
  #   .scale(2)                           # Scale factor
  #   .render(image)
  # ```
  class Renderer
    property output_width : Int32    # Output width.
    property output_height : Int32   # Output height (0 for auto).
    property threshold_level : UInt8 # Threshold for considering a pixel as set (0-255).
    property? dither : Bool          # Enable Dithering (false as default).
    property? use_fg_bg_only : Bool  # Use only foreground/background colors (no block symbols).
    property? invert_colors : Bool   # Invert colors.
    property scale : Int32           # Scale level
    property symbols : Symbol        # Which symbols to use: "half", "quarter", "all".

    # New creates and returns a [Renderer].
    def initialize
      @output_width = 0                         # Override width.
      @output_height = 0                        # Override height.
      @threshold_level = MIDDLE_THRESHOLD_LEVEL # Middle threshold.
      @dither = false                           # Enable dithering.
      @use_fg_bg_only = false                   # Use block symbols.
      @invert_colors = false                    # Don't invert.
      @scale = 1                                # Don't scale.
      @symbols = Symbol::Half                   # Use half blocks.
    end

    # Scale sets the scale level on [Renderer].
    def scale(scale : Int) : self
      @scale = scale.to_i32
      self
    end

    # IgnoreBlockSymbols set UseFgBgOnly on [Renderer].
    def ignore_block_symbols(fg_only : Bool) : self
      @use_fg_bg_only = fg_only
      self
    end

    # Dither sets the dither level on [Renderer].
    def dither(dither : Bool) : self
      @dither = dither
      self
    end

    # Threshold sets the threshold level on [Renderer].
    # It expects a value between 0-255, anything else will be ignored.
    def threshold(threshold : Int) : self
      if threshold >= 0 && threshold <= U8_MAX_VALUE
        @threshold_level = threshold.to_u8
      end
      self
    end

    # InvertColors whether to invert the colors of the mosaic image.
    def invert_colors(invert : Bool) : self
      @invert_colors = invert
      self
    end

    # Width sets the maximum width the image can have. Defaults to the image width.
    def width(width : Int) : self
      @output_width = width.to_i32
      self
    end

    # Height sets the maximum height the image can have. Defaults to the image height.
    def height(height : Int) : self
      @output_height = height.to_i32
      self
    end

    # Symbol sets the mosaic symbol type.
    def symbol(symbol : Symbol) : self
      @symbols = symbol
      self
    end

    # Render renders the image to a string.
    def render(canvas : StumpyCore::Canvas) : String
      # Calculate dimensions.
      src_width = canvas.width
      src_height = canvas.height

      # Determine output dimensions.
      out_width = src_width
      out_width = @output_width if @output_width > 0

      out_height = src_height
      out_height = @output_height if @output_height > 0

      if out_height <= 0
        # Calculate height based on aspect ratio and character cell proportions.
        # Terminal characters are roughly twice as tall as wide, so we divide by 2.
        divider = 2
        out_height = (out_width.to_f * src_height.to_f / src_width.to_f / divider).to_i
        out_height = 1 if out_height < 1
      end

      # Scale image according to the scale.
      scaled_canvas = apply_scaling(canvas, out_width * @scale, out_height * @scale)

      # Apply dithering if enabled.
      scaled_canvas = apply_dithering(scaled_canvas) if dither?

      # Invert colors if needed.
      scaled_canvas = invert_image(scaled_canvas) if invert_colors?

      # Generate terminal output.
      output = String::Builder.new

      # Set initial blocks based on symbols value (initial/default is half)
      blocks = HALF_BLOCKS

      # Quarter blocks.
      if @symbols == Symbol::Quarter || @symbols == Symbol::All
        blocks += QUARTER_BLOCKS
      end

      # All block elements (including complex combinations).
      if @symbols == Symbol::All
        blocks += COMPLEX_BLOCKS
      end

      # Process the image by 2x2 blocks (representing one character cell).
      height = scaled_canvas.height
      width = scaled_canvas.width

      0.step(to: height - 1, by: 2) do |y|
        0.step(to: width - 1, by: 2) do |x|
          # Create and analyze the 2x2 pixel block.
          block = create_pixel_block(scaled_canvas, x, y)

          # Determine best symbol and colors.
          find_best_representation(block, blocks)

          # Append to output.
          if (fg = block.best_fg_color) && (bg = block.best_bg_color)
            output << ansi_style(fg, bg, block.best_symbol)
          else
            # Fallback to space if colors are nil
            output << ' '
          end
        end
        output << "\n"
      end

      output.to_s
    end

    # average_colors calculates the average color from a slice of colors.
    private def average_colors(colors : Array(StumpyCore::RGBA)) : StumpyCore::RGBA
      return StumpyCore::RGBA.new(0, 0, 0, 255) if colors.empty?

      sum_r = 0_u32
      sum_g = 0_u32
      sum_b = 0_u32
      sum_a = 0_u32

      colors.each do |color|
        r, g, b, a = Mosaic.shift_color(color)
        sum_r += r.to_u32
        sum_g += g.to_u32
        sum_b += b.to_u32
        sum_a += a.to_u32
      end

      count = colors.size.to_u32
      StumpyCore::RGBA.new(
        (sum_r // count).to_u8,
        (sum_g // count).to_u8,
        (sum_b // count).to_u8,
        (sum_a // count).to_u8
      )
    end

    # ansi_style generates an ANSI truecolor escape sequence for foreground and background colors.
    private def ansi_style(fg : StumpyCore::RGBA, bg : StumpyCore::RGBA, char : Char) : String
      # Format: \x1b[38;2;R;G;B;48;2;R;G;Bm<char>\x1b[m
      String.build do |str|
        str << "\x1b[38;2;"
        str << fg.r
        str << ';'
        str << fg.g
        str << ';'
        str << fg.b
        str << ";48;2;"
        str << bg.r
        str << ';'
        str << bg.g
        str << ';'
        str << bg.b
        str << 'm'
        str << char
        str << "\x1b[m"
      end
    end

    # get_pixel_safe returns the color at (x,y) or black if out of bounds.
    private def get_pixel_safe(canvas : StumpyCore::Canvas, x : Int32, y : Int32) : StumpyCore::RGBA
      if x >= 0 && x < canvas.width && y >= 0 && y < canvas.height
        canvas[x, y]
      else
        StumpyCore::RGBA.new(0, 0, 0, 255)
      end
    end

    # apply_scaling resizes an image to the specified dimensions.
    # Uses bilinear interpolation to match Go's ApproxBiLinear scaling.
    private def apply_scaling(canvas : StumpyCore::Canvas, width : Int32, height : Int32) : StumpyCore::Canvas
      scaled = StumpyCore::Canvas.new(width, height)
      sw = canvas.width.to_f
      sh = canvas.height.to_f
      yscale = sh / height.to_f
      xscale = sw / width.to_f
      sw_minus1 = canvas.width - 1
      sh_minus1 = canvas.height - 1

      height.times do |y_index|
        sy = (y_index.to_f + 0.5) * yscale - 0.5
        sy0 = sy.floor.to_i
        y_frac0 = sy - sy0
        y_frac1 = 1.0 - y_frac0
        sy1 = sy0 + 1

        if sy < 0
          sy0 = 0
          sy1 = 0
          y_frac0 = 0.0
          y_frac1 = 1.0
        elsif sy1 > sh_minus1
          sy0 = sh_minus1
          sy1 = sh_minus1
          y_frac0 = 1.0
          y_frac1 = 0.0
        end

        width.times do |x_index|
          sx = (x_index.to_f + 0.5) * xscale - 0.5
          sx0 = sx.floor.to_i
          x_frac0 = sx - sx0
          x_frac1 = 1.0 - x_frac0
          sx1 = sx0 + 1

          if sx < 0
            sx0 = 0
            sx1 = 0
            x_frac0 = 0.0
            x_frac1 = 1.0
          elsif sx1 > sw_minus1
            sx0 = sw_minus1
            sx1 = sw_minus1
            x_frac0 = 1.0
            x_frac1 = 0.0
          end

          # Sample four pixels and convert to premultiplied 16-bit values
          c00 = canvas[sx0, sy0]
          c10 = canvas[sx1, sy0]
          c01 = canvas[sx0, sy1]
          c11 = canvas[sx1, sy1]

          pr00, pg00, pb00, pa00 = Mosaic.premultiplied_16bit(c00)
          pr10, pg10, pb10, pa10 = Mosaic.premultiplied_16bit(c10)
          pr01, pg01, pb01, pa01 = Mosaic.premultiplied_16bit(c01)
          pr11, pg11, pb11, pa11 = Mosaic.premultiplied_16bit(c11)

          # Convert to Float for interpolation
          r00 = pr00.to_f
          g00 = pg00.to_f
          b00 = pb00.to_f
          a00 = pa00.to_f

          r10 = pr10.to_f
          g10 = pg10.to_f
          b10 = pb10.to_f
          a10 = pa10.to_f

          r01 = pr01.to_f
          g01 = pg01.to_f
          b01 = pb01.to_f
          a01 = pa01.to_f

          r11 = pr11.to_f
          g11 = pg11.to_f
          b11 = pb11.to_f
          a11 = pa11.to_f

          # Horizontal interpolation
          r_h0 = x_frac1 * r00 + x_frac0 * r10
          g_h0 = x_frac1 * g00 + x_frac0 * g10
          b_h0 = x_frac1 * b00 + x_frac0 * b10
          a_h0 = x_frac1 * a00 + x_frac0 * a10

          r_h1 = x_frac1 * r01 + x_frac0 * r11
          g_h1 = x_frac1 * g01 + x_frac0 * g11
          b_h1 = x_frac1 * b01 + x_frac0 * b11
          a_h1 = x_frac1 * a01 + x_frac0 * a11

          # Vertical interpolation
          r = y_frac1 * r_h0 + y_frac0 * r_h1
          g = y_frac1 * g_h0 + y_frac0 * g_h1
          b = y_frac1 * b_h0 + y_frac0 * b_h1
          a = y_frac1 * a_h0 + y_frac0 * a_h1

          # Convert back to UInt16 with truncation (matching Go's conversion)
          r = r.clamp(0.0, 65535.0).to_u16
          g = g.clamp(0.0, 65535.0).to_u16
          b = b.clamp(0.0, 65535.0).to_u16
          a = a.clamp(0.0, 65535.0).to_u16

          scaled[x_index, y_index] = StumpyCore::RGBA.new(r, g, b, a)
        end
      end

      scaled
    end

    private def apply_dithering(canvas : StumpyCore::Canvas) : StumpyCore::Canvas
      width = canvas.width
      height = canvas.height
      dithered = StumpyCore::Canvas.new(width, height)

      # Error buffers for each channel (R, G, B, A) as Float64
      error_r = Array.new(width) { Array.new(height, 0.0) }
      error_g = Array.new(width) { Array.new(height, 0.0) }
      error_b = Array.new(width) { Array.new(height, 0.0) }
      error_a = Array.new(width) { Array.new(height, 0.0) }

      height.times do |y|
        width.times do |x|
          # Original color
          pixel = canvas[x, y]

          # Add accumulated error
          r = pixel.r.to_f64 + error_r[x][y]
          g = pixel.g.to_f64 + error_g[x][y]
          b = pixel.b.to_f64 + error_b[x][y]
          a = pixel.a.to_f64 + error_a[x][y]

          # Clamp to 0..255
          r = r.clamp(0.0, 255.0)
          g = g.clamp(0.0, 255.0)
          b = b.clamp(0.0, 255.0)
          a = a.clamp(0.0, 255.0)

          # Find nearest palette color
          best_color = PLAN9_PALETTE[0]
          best_distance = Float64::MAX

          PLAN9_PALETTE.each do |pal_color|
            dr = r - pal_color.r.to_f64
            dg = g - pal_color.g.to_f64
            db = b - pal_color.b.to_f64
            da = a - pal_color.a.to_f64
            distance = dr*dr + dg*dg + db*db + da*da
            if distance < best_distance
              best_distance = distance
              best_color = pal_color
            end
          end

          # Set dithered pixel
          dithered[x, y] = best_color

          # Quantization error
          err_r = r - best_color.r.to_f64
          err_g = g - best_color.g.to_f64
          err_b = b - best_color.b.to_f64
          err_a = a - best_color.a.to_f64

          # Distribute error to neighboring pixels (Floyd-Steinberg)
          if x + 1 < width
            error_r[x + 1][y] += err_r * 7.0 / 16.0
            error_g[x + 1][y] += err_g * 7.0 / 16.0
            error_b[x + 1][y] += err_b * 7.0 / 16.0
            error_a[x + 1][y] += err_a * 7.0 / 16.0
          end

          if y + 1 < height
            if x - 1 >= 0
              error_r[x - 1][y + 1] += err_r * 3.0 / 16.0
              error_g[x - 1][y + 1] += err_g * 3.0 / 16.0
              error_b[x - 1][y + 1] += err_b * 3.0 / 16.0
              error_a[x - 1][y + 1] += err_a * 3.0 / 16.0
            end

            error_r[x][y + 1] += err_r * 5.0 / 16.0
            error_g[x][y + 1] += err_g * 5.0 / 16.0
            error_b[x][y + 1] += err_b * 5.0 / 16.0
            error_a[x][y + 1] += err_a * 5.0 / 16.0

            if x + 1 < width
              error_r[x + 1][y + 1] += err_r * 1.0 / 16.0
              error_g[x + 1][y + 1] += err_g * 1.0 / 16.0
              error_b[x + 1][y + 1] += err_b * 1.0 / 16.0
              error_a[x + 1][y + 1] += err_a * 1.0 / 16.0
            end
          end
        end
      end

      dithered
    end

    # invert_image inverts the colors of an image.
    private def invert_image(canvas : StumpyCore::Canvas) : StumpyCore::Canvas
      inverted = StumpyCore::Canvas.new(canvas.width, canvas.height)
      canvas.width.times do |x|
        canvas.height.times do |y|
          pixel = canvas[x, y]
          # Extract high bytes (8-bit representation)
          hr = pixel.r >> 8
          hg = pixel.g >> 8
          hb = pixel.b >> 8
          ha = pixel.a >> 8
          # Invert RGB, keep alpha
          inverted_hr = 255_u16 - hr
          inverted_hg = 255_u16 - hg
          inverted_hb = 255_u16 - hb
          # Reconstruct 16-bit values (high byte repeated in low byte)
          r = (inverted_hr << 8) | inverted_hr
          g = (inverted_hg << 8) | inverted_hg
          b = (inverted_hb << 8) | inverted_hb
          a = (ha << 8) | ha
          inverted[x, y] = StumpyCore::RGBA.new(r.to_u16, g.to_u16, b.to_u16, a.to_u16)
        end
      end
      inverted
    end

    # create_pixel_block extracts a 2x2 block of pixels from the image.
    private def create_pixel_block(canvas : StumpyCore::Canvas, x : Int32, y : Int32) : PixelBlock
      block = PixelBlock.new

      # Extract the 2x2 pixel grid.
      2.times do |row|
        2.times do |col|
          block.pixels[row][col] = get_pixel_safe(canvas, x + col, y + row)
        end
      end

      block
    end

    # find_best_representation finds the best block character and colors for a 2x2 pixel block.
    private def find_best_representation(block : PixelBlock, available_blocks : Array(Block))
      # Simple case: use only foreground/background colors.
      if use_fg_bg_only?
        # Just use the upper half block with top pixels as background and bottom as foreground.
        block.best_symbol = '▀'
        block.best_bg_color = average_colors(block.pixels[0][0], block.pixels[0][1])
        block.best_fg_color = average_colors(block.pixels[1][0], block.pixels[1][1])
        return
      end

      # Determine which pixels are "set" based on threshold.
      pixel_mask = Array.new(2) { Array.new(2, false) }

      2.times do |y|
        2.times do |x|
          if pixel = block.pixels[y][x]
            # Calculate luminance.
            luma = Mosaic.rgba_to_luminance(pixel)
            pixel_mask[y][x] = luma >= @threshold_level
          else
            pixel_mask[y][x] = false
          end
        end
      end

      # Find the best matching block character.
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

      # Get the coverage pattern for the selected character.
      coverage = {false, false, false, false}
      available_blocks.each do |b|
        if b.char == best_char
          coverage = b.coverage
          break
        end
      end

      # Assign pixels to foreground or background based on the character's coverage.
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

      # Calculate average colors.
      if fg_pixels.empty?
        block.best_fg_color = StumpyCore::RGBA.new(0, 0, 0, 255)
      else
        block.best_fg_color = average_colors(fg_pixels)
      end

      if bg_pixels.empty?
        block.best_bg_color = StumpyCore::RGBA.new(0, 0, 0, 255)
      else
        block.best_bg_color = average_colors(bg_pixels)
      end

      block.best_symbol = best_char
    end

    # average_colors calculates the average color from colors (variadic or array).
    private def average_colors(*colors : StumpyCore::RGBA) : StumpyCore::RGBA
      average_colors(colors.to_a)
    end
  end
end
