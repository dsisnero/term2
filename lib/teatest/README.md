# teatest

Test helpers for Term2 programs. This is a Crystal port of the Go `x/exp/teatest/v2` package from charmbracelet/ansi.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  teatest:
    path: lib/teatest
```

2. Run `shards install`

## Usage

```crystal
require "teatest"
require "term2"

class Counter
  include Term2::Model

  def initialize(@n : Int32 = 0)
  end

  def init : Term2::Cmd
    Term2::Cmds.none
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      if msg.code == Ultraviolet::KeyEnter
        return {self, nil}
      end
    end
    {self, nil}
  end

  def view : String
    "count=#{@n}\n"
  end
end

tm = Teatest.new_test_model(Counter.new)
Teatest.wait_for(tm.output, ->(b : Bytes) { String.new(b).includes?("count=") })
tm.quit
```

### Golden output

```crystal
Teatest.require_equal_output(self, tm.output.to_slice)
```

## Development

- `crystal tool format`
- `crystal spec`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [dsisnero](https://github.com/dsisnero) - creator and maintainer
