# ansi

`ansi` is a Crystal library for generating and parsing ANSI terminal escape
sequences. It is a Crystal port of `x/ansi` (Go) and includes helpers for
colors, styles, cursor control, modes, mouse/keyboard protocols, images
(Kitty, iTerm2, Sixel), and sequence parsing/decoding utilities.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     ansi:
       github: dsisnero/ansi
   ```

2. Run `shards install`

## Usage

```crystal
require "ansi"
```

Examples:

```crystal
# Colors and styles
puts Ansi.sgr(Ansi::AttrBold, Ansi::AttrBlueForegroundColor) + "Hello" + Ansi::ResetStyle

# Cursor movement
print Ansi.cursor_up(2)
print Ansi.cursor_forward(10)

# Clipboard
print Ansi.set_system_clipboard("hello")

# Kitty graphics
payload = "...".to_slice
print Ansi.kitty_graphics(payload)
```

## Development

Run specs:

```bash
crystal spec
```

## Contributing

1. Fork it (<https://github.com/dsisnero/ansi/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [your-name-here](https://github.com/dsisnero) - creator and maintainer
