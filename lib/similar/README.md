# similar

A Crystal port of the Rust `similar` diff library.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  similar:
    github: dsisnero/similar
```

Then run:

```bash
shards install
```

## Usage

Basic text diff:

```crystal
require "similar"

diff = Similar::TextDiff.from_lines("a\nb\n", "a\nB\n")
diff.iter_all_changes.each do |change|
  puts "#{change.tag}: #{change.value}"
end
```

Unified diff:

```crystal
require "similar"

old_text = "Hello\nWorld\n"
new_text = "Hello\nCrystal\n"

diff = Similar::TextDiff.from_lines(old_text, new_text)
puts diff.unified_diff.header("old.txt", "new.txt").to_s
```

Close matches:

```crystal
require "similar"

matches = Similar.get_close_matches("appel", ["ape", "apple", "peach", "puppy"], 3, 0.6)
pp matches
```

## Development

Run formatting, linting, and specs:

```bash
crystal tool format
ameba --fix
ameba
crystal spec
```

## Contributing

1. Fork it (<https://github.com/dsisnero/similar/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [dsisnero](https://github.com/dsisnero) - creator and maintainer
