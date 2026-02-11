# charmtone

Crystal port of Charm's experimental `charmtone` palette package.

`charmtone` provides:
- A typed color key enum (`Charmtone::Key`) for the CharmTone palette.
- Name lookup (`to_s`) and hex lookup (`hex`) for each key.
- RGBA output (`rgba`) compatible with 16-bit channel values.
- Palette grouping helpers (`is_primary?`, `is_secondary?`, `is_tertiary?`).
- Canonical palette enumeration via `Charmtone.keys`.

Go source of truth:
- [github.com/charmbracelet/x/exp/charmtone](https://github.com/charmbracelet/x/tree/main/exp/charmtone)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     charmtone:
       github: dsisnero/charmtone
   ```

2. Run `shards install`

## Usage

```crystal
require "charmtone"
```

```crystal
Charmtone::Key::Charple.hex        # => "#6B50FF"
Charmtone::Key::Mochi.to_s         # => "Crystal"
Charmtone::Key::Blush.is_secondary? # => true

r, g, b, a = Charmtone::Key::Zest.rgba
# 16-bit channels (0x0000..0xFFFF)

Charmtone.keys.each do |key|
  puts "#{key}: #{key.hex}"
end
```

## Development

Run specs:

```bash
CRYSTAL_CACHE_DIR=$PWD/.crystal-cache crystal spec
```

## Contributing

1. Fork it (<https://github.com/dsisnero/charmtone/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Dom](https://github.com/dsisnero) - creator and maintainer
