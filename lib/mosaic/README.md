# mosaic

Unicode image renderer for terminal output, ported from [charmbracelet/x/mosaic](https://github.com/charmbracelet/x/tree/main/mosaic).

It converts image pixels into ANSI truecolor text using half/quarter/complex block characters.

## Installation

Add this shard:

```yaml
dependencies:
  mosaic:
    github: dsisnero/mosaic
```

Then install:

```bash
shards install
```

## Go API Parity

The Crystal API mirrors the Go package surface:

- `Mosaic.new` (Go: `mosaic.New()`)
- `Mosaic.render(canvas, width, height)` (Go: `mosaic.Render(img, width, height)`)
- Fluent options on renderer:
  - `width(Int)`
  - `height(Int)`
  - `scale(Int)`
  - `dither(Bool)`
  - `invert_colors(Bool)`
  - `ignore_block_symbols(Bool)`
  - `threshold(Int)`
  - `symbol(Mosaic::Symbol)`

`Mosaic::Symbol` values:

- `Mosaic::Symbol::Half`
- `Mosaic::Symbol::Quarter`
- `Mosaic::Symbol::All`

Fluent setters use Go-style value semantics: they return a modified copy and do not mutate the original renderer.

## Usage

### 1) Basic rendering from a `StumpyCore::Canvas`

```crystal
require "mosaic"

canvas = StumpyCore::Canvas.new(2, 2)
canvas[0, 0] = StumpyCore::RGBA.new(255, 0, 0, 255)
canvas[1, 0] = StumpyCore::RGBA.new(0, 255, 0, 255)
canvas[0, 1] = StumpyCore::RGBA.new(0, 0, 255, 255)
canvas[1, 1] = StumpyCore::RGBA.new(255, 255, 255, 255)

out = Mosaic.new
  .width(2)
  .height(1)
  .symbol(Mosaic::Symbol::Half)
  .render(canvas)

puts out
```

### 2) Use the convenience wrapper

```crystal
require "mosaic"

canvas = StumpyCore::Canvas.new(4, 4)
4.times do |y|
  4.times do |x|
    canvas[x, y] = StumpyCore::RGBA.new(255, 255, 255, 255)
  end
end

puts Mosaic.render(canvas, 4, 2)
```

### 3) Decode PNG/JPEG with `crimage` and render

Mosaic core accepts `StumpyCore::Canvas`. For PNG/JPEG/WebP/etc decoding, use an adapter function:

```crystal
require "mosaic"
require "crimage"

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

img = CrImage.read("./photo.jpg")
canvas = to_canvas(img)

puts Mosaic.new
  .width(80)
  .dither(true)
  .render(canvas)
```

## Examples

Runnable examples are in `/examples`:

- `examples/basic_canvas.cr`
- `examples/render_from_crimage.cr`

## Development

Quality gates:

```bash
crystal tool format src spec
ameba src
ameba spec
crystal spec
```

## Contributing

1. Fork the repo.
2. Create a branch.
3. Commit your changes.
4. Push and open a PR.
