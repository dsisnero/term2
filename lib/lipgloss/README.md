# lipgloss

Lipgloss is a terminal styling library with a fluent API for borders, padding,
margins, alignment, and layout helpers. This is a Crystal port of the Charm
lipgloss ecosystem.

## Installation

1.  Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     lipgloss:
       github: dsisnero/lipgloss
   ```

2.  Run `shards install`

## Usage

```crystal
require "lipgloss"
```

style = Lipgloss::Style.new
  .foreground(Lipgloss::Color::CYAN)
  .border(Lipgloss::Border.rounded)
  .padding(1, 2)

puts style.render("Hello")

## Development

Run the specs from this directory:

```bash
CRYSTAL_CACHE_DIR=$PWD/.crystal-cache crystal spec
```

If you are working inside the `term2` repo without `shards install`, include the
local `lib/` directory so dependencies resolve:

```bash
CRYSTAL_CACHE_DIR=$PWD/.crystal-cache \
CRYSTAL_PATH="$(crystal env CRYSTAL_PATH):../../lib" \
  crystal spec
```

## Contributing

1.  Fork it (<https://github.com/dsisnero/lipgloss/fork>)
2.  Create your feature branch (`git checkout -b my-new-feature`)
3.  Commit your changes (`git commit -am 'Add some feature'`)
4.  Push to the branch (`git push origin my-new-feature`)
5.  Create a new Pull Request

## Contributors

*   [Dominic Sisneros](https://github.com/dsisnero) - creator and maintainer
