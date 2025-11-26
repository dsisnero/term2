# Term2

A Crystal port of the [Bubble Tea](https://github.com/charmbracelet/bubbletea) terminal UI library, built with concurrent ML (cml) for concurrency.

## Features

- **Elm Architecture**: Model-Update-View pattern for building terminal applications
- **Concurrent ML**: Built on [cml](https://github.com/dsisnero/cml) for efficient concurrency
- **200+ Key Sequences**: Support for xterm, urxvt, linux console, VT100/VT220
- **Mouse Support**: SGR and legacy X10 mouse protocols
- **Focus Reporting**: FocusIn/FocusOut events
- **Alternate Screen**: Clean terminal restoration
- **Components**: Spinner, ProgressBar, TextInput, CountdownTimer
- **Cross-platform**: Works on Linux, macOS, and Windows

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     term2:
       github: dsisnero/term2
     cml:
       github: dsisnero/cml
   ```

2. Run `shards install`

## Quick Start

```crystal
require "term2"
include Term2::Prelude

class CounterModel < Model
  getter count : Int32
  def initialize(@count = 0); end
end

class CounterApp < Application
  def init
    CounterModel.new
  end

  def update(msg : Message, model : Model)
    m = model.as(CounterModel)
    case msg
    when KeyPress
      case msg.key
      when "q", "ctrl+c"
        {m, Cmd.quit}
      when "+", "="
        {CounterModel.new(m.count + 1), nil}
      when "-", "_"
        {CounterModel.new(m.count - 1), nil}
      else
        {m, nil}
      end
    else
      {m, nil}
    end
  end

  def view(model : Model) : String
    m = model.as(CounterModel)
    "Count: #{m.count}\n\nPress +/- to change, q to quit"
  end
end

CounterApp.new.run
```

## Program Options

Configure your application with various options:

```crystal
class MyApp < Application
  def options : Array(ProgramOption)
    [
      WithAltScreen.new,        # Use alternate screen buffer
      WithMouseAllMotion.new,   # Enable mouse tracking
      WithReportFocus.new,      # Enable focus reporting
      WithFPS.new(30.0),        # Set frame rate
    ]
  end
  # ...
end
```

Available options:
- `WithAltScreen` - Use alternate screen buffer
- `WithMouseAllMotion` - Track all mouse motion (hover)
- `WithMouseCellMotion` - Track mouse drag only
- `WithReportFocus` - Report focus in/out events
- `WithInput(io)` - Custom input source
- `WithOutput(io)` - Custom output destination
- `WithFPS(fps)` - Set frame rate
- `WithoutRenderer` - Disable rendering (headless mode)
- `WithoutCatchPanics` - Disable panic recovery
- `WithoutBracketedPaste` - Disable bracketed paste

## Handling Input

### Keyboard

```crystal
def update(msg : Message, model : Model)
  case msg
  when KeyPress
    case msg.key
    when "up", "k"    then move_up(model)
    when "down", "j"  then move_down(model)
    when "enter"      then select(model)
    when "ctrl+c"     then {model, Cmd.quit}
    else              {model, nil}
    end
  else
    {model, nil}
  end
end
```

### Mouse

```crystal
def update(msg : Message, model : Model)
  case msg
  when MouseEvent
    case msg.action
    when MouseEvent::Action::Press
      handle_click(model, msg.x, msg.y, msg.button)
    when MouseEvent::Action::Move
      handle_hover(model, msg.x, msg.y)
    end
  else
    {model, nil}
  end
end
```

### Focus

```crystal
def update(msg : Message, model : Model)
  case msg
  when FocusMsg
    # Window gained focus
    {model.with_focused(true), nil}
  when BlurMsg
    # Window lost focus
    {model.with_focused(false), nil}
  else
    {model, nil}
  end
end
```

## Commands

```crystal
# No-op
Cmd.none
nil

# Quit the application
Cmd.quit

# Batch multiple commands
Cmd.batch(cmd1, cmd2, cmd3)

# Run commands in sequence
Cmd.sequence(cmd1, cmd2, cmd3)

# Tick command for timers
Cmd.tick(1.second) { |t| TickMsg.new(t) }

# Custom command
Cmd.new { MyCustomMsg.new(result) }
```

## Components

### Spinner

```crystal
spinner = Components::Spinner.new(
  frames: ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"],
  interval: 100.milliseconds
)
model, cmd = spinner.init("Loading...")
```

### ProgressBar

```crystal
progress = Components::ProgressBar.new(
  width: 30,
  complete_char: '█',
  incomplete_char: '░',
  show_percentage: true
)
model, cmd = progress.init
```

### TextInput

```crystal
input = Components::TextInput.new(
  placeholder: "Type here...",
  max_length: 50
)
model, cmd = input.init(focused: true)
```

## Documentation

- [Migration Guide from BubbleTea (Go)](docs/migration-from-go.md)
- [Tutorials](docs/tutorials.md)
- [Examples](examples/)

## Development

### Running Tests

```bash
# Run all tests
crystal spec

# Run interactive tests (requires TTY)
TERM2_TEST_TTY=1 crystal spec --tag interactive

# Run benchmarks
crystal run --release benchmarks/benchmark.cr
```

### Project Structure

```
src/
  term2.cr         # Main module, Program, Cmd, KeyReader
  base_types.cr    # Model, Message, Key, KeyType
  key_sequences.cr # Escape sequence mappings
  mouse.cr         # Mouse event handling
  renderer.cr      # StandardRenderer, NilRenderer
  terminal.cr      # Terminal control utilities
  view.cr          # View layout system
  program_options.cr # Program configuration
```

## Contributing

1. Fork it (<https://github.com/dsisnero/term2/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

MIT License - see [LICENSE](LICENSE)
