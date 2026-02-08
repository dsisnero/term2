# Porting vendor/x/mosaic to Crystal - Detailed Plan

## Overview

Mosaic is a Unicode image renderer for terminal programs. It breaks down images into 2x2 pixel blocks and renders them using Unicode block characters (half blocks, quarter blocks, etc.) with ANSI color escape sequences.

The Go implementation (`vendor/x/mosaic`) provides:

*   Configurable output width/height
*   Symbol types (half, quarter, all blocks)
*   Dithering (Floyd-Steinberg)
*   Color inversion
*   Threshold-based pixel masking
*   ANSI truecolor (24-bit) foreground/background colors

## Dependencies Analysis

### Go Dependencies

1.  `image`, `color`, `draw`, `palette` (standard library)
2.  `golang.org/x/image/draw` (scaling)
3.  `github.com/charmbracelet/x/ansi` (ANSI styling)

### Crystal Equivalents

1.  **Image Processing**:
    *   Crystal standard library lacks image processing
    *   Options:
        *   `stumpy_core` (pure Crystal, supports PNG/JPEG/...)
        *   `cr-image` (wrapper around stb_image)
        *   `celestine` (SVG only)
        *   `magickwand-crystal` (ImageMagick bindings - heavy)
    * **Recommendation**: `stumpy_core` - pure Crystal, actively maintained, provides pixel access and basic image operations.

2.  **ANSI Styling**:
    *   Crystal's `colorize` provides basic colors but not truecolor RGB
    *   Need to generate ANSI escape sequences: `\x1b[38;2;R;G;B;48;2;R;G;Bm`
    *   Can implement simple helper module

3.  **Unicode Block Characters**:
    *   Crystal supports Unicode natively

## API Design

### Module Structure

```crystal
module Mosaic
  enum Symbol
    All
    Half
    Quarter
  end

  class Renderer
    property output_width : Int32
    property output_height : Int32
    property threshold_level : UInt8
    property dither : Bool
    property use_fg_bg_only : Bool
    property invert_colors : Bool
    property scale : Int32
    property symbols : Symbol

    def initialize
      # Default values matching Go implementation
    end

    # Fluent setters
    def width(width : Int) : self
    def height(height : Int) : self
    def scale(scale : Int) : self
    def ignore_block_symbols(fg_only : Bool) : self
    def dither(dither : Bool) : self
    def threshold(threshold : Int) : self
    def invert_colors(invert : Bool) : self
    def symbol(symbol : Symbol) : self

    # Main render method
    def render(image : StumpyPNG::Image | StumpyCore::Canvas) : String
  end
end
```

### Data Structures

```crystal
struct Block
  property char : Char
  property coverage : Tuple(Bool, Bool, Bool, Bool)  # [TL, TR, BL, BR]
  property coverage_map : String
end

struct PixelBlock
  property pixels : Array(Array(StumpyCore::RGBA))
  property avg_fg : StumpyCore::RGBA
  property avg_bg : StumpyCore::RGBA
  property best_symbol : Char
  property best_fg_color : StumpyCore::RGBA
  property best_bg_color : StumpyCore::RGBA
end
```

## Implementation Steps

### Phase 1: Setup Dependencies

1.  Add `stumpy_core` to `shard.yml`
2.  Create ANSI helper module (`src/mosaic/ansi.cr`)
3.  Define constants for Unicode block characters

### Phase 2: Core Structures

1.  Implement `Mosaic::Renderer` with properties
2.  Implement fluent setters (return `self`)
3.  Define block constants (`HALF_BLOCKS`, `QUARTER_BLOCKS`, `COMPLEX_BLOCKS`)

### Phase 3: Helper Functions

1.  `rgba_to_luminance(color : StumpyCore::RGBA) : UInt8`
2.  `shift(value : UInt32) : UInt32` (scale 16-bit to 8-bit)
3.  `average_colors(colors : Array(StumpyCore::RGBA)) : StumpyCore::RGBA`
4.  `get_pixel_safe(image, x, y)`

### Phase 4: Image Processing

1.  **Scaling**: Implement bilinear scaling using `stumpy_core` canvas manipulation
    *   Option: Use nearest-neighbor for simplicity initially
    *   Need to match Go's `xdraw.ApproxBiLinear.Scale`
2.  **Dithering**: Implement Floyd-Steinberg dithering with a fixed palette
    *   Use `palette::Plan9` equivalent (256 colors)
    *   Can implement custom palette or use terminal colors
3.  **Color Inversion**: Simple pixel-wise inversion

### Phase 5: Block Processing

1.  `create_pixel_block(image, x, y) : PixelBlock`
2.  `find_best_representation(block : PixelBlock, available_blocks : Array(Block))`
    *   Calculate pixel mask based on threshold
    *   Score each block character
    *   Determine foreground/background colors

### Phase 6: ANSI Output Generation

1.  Implement `ANSI.style(fg : StumpyCore::RGBA, bg : StumpyCore::RGBA) : String`
2.  Combine with best symbol character
3.  Build output string row by row

### Phase 7: Integration

1.  Main `render` method orchestrating all steps
2.  Handle edge cases (odd dimensions, out of bounds)
3.  Optimize performance (avoid unnecessary allocations)

### Phase 8: Testing

1.  Port Go test cases to Crystal specs
2.  Use fixture image from vendor/x/fixtures
3.  Test each configuration option
4.  Compare output with Go implementation (allow small floating-point differences)

### Phase 9: Documentation & Examples

1.  Write module documentation
2.  Create example program (load image, render)
3.  Update README.md with Crystal usage

## Potential Challenges

1.  **Image Library Differences**:
    *   `stumpy_core` uses RGBA with 0-255 values (matches Go)
    *   Coordinate system differences
    *   Need to handle different image formats

2.  **Performance**:
    *   Crystal should be comparable to Go
    *   Optimize hot loops (2x2 block processing)

3.  **Color Space**:
    *   Ensure luminance calculation matches Go's weighted formula
    *   ANSI truecolor compatibility across terminals

4.  **Dithering Implementation**:
    *   Floyd-Steinberg requires error diffusion
    *   Palette selection (terminal colors vs. full RGB)

## Success Criteria

1.  All Go test cases pass (with tolerance for floating-point differences)
2.  Example program produces visually similar output to Go version
3.  API is idiomatic Crystal while maintaining parity with Go API
4.  Performance is acceptable for typical image sizes (80x40 cells)

## Timeline Estimate

*   Phase 1-3: 1 day
*   Phase 4-6: 2 days
*   Phase 7-8: 1 day
*   Phase 9: 0.5 day

Total: 4-5 days of focused development

## Next Steps

1.  Finalize dependency choice (stumpy_core)
2.  Create initial skeleton implementation
3.  Implement basic rendering without scaling/dithering
4.  Iteratively add features and test against Go output
