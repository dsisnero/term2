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

  def init : Cmd
    Cmd.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        {self, Term2.quit}
      when "+", "="
        {CounterModel.new(@count + 1), Cmd.none}
      when "-", "_"
        {CounterModel.new(@count - 1), Cmd.none}
      else
        {self, Cmd.none}
      end
    else
      {self, Cmd.none}
    end
  end

  def view : String
    "Count: #{@count}\n\nPress +/- to change, q to quit"
  end
end

Term2.run(CounterModel.new)
```

## Prelude & Aliases

Including `Term2::Prelude` provides convenient aliases for common types:

- `Model`, `Cmd`, `Message` - Core types
- `TC` - Alias for `Term2::Components` (e.g., `TC::TextInput`)
- `KeyMsg`, `WindowSizeMsg`, `QuitMsg` - Common messages
- `S` - Alias for `Term2::S` (Style builder)

## Program Options

Configure your application by passing options to `Term2.run`:

```crystal
Term2.run(model, [
  WithAltScreen.new,        # Use alternate screen buffer
  WithMouseAllMotion.new,   # Enable mouse tracking
  WithReportFocus.new,      # Enable focus reporting
] of Term2::ProgramOption)
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

## Text Styling DSL

Term2 provides a fluent API for styled text output without raw escape codes:

### Method 1: String Extensions (Simple Single Styles)

```crystal
puts "Hello".bold
puts "Error!".red
puts "Warning".yellow.bold  # Note: chaining returns nested codes
```

### Method 2: S Builder (Chained/Composed Styles)

```crystal
# Method chaining with .apply()
puts S.bold.cyan.apply("Styled text")
puts S.red.on_white.underline.apply("Alert!")

# Pipe operator shorthand
puts S.green.bold | "Success!"
puts S.bright_magenta.italic | "Fancy"

# 256-color palette
puts S.fg(208).bold | "Orange"

# True color RGB
puts S.fg(100, 149, 237).bold | "Cornflower Blue"
puts S.bg(30, 30, 30).white | "Dark background"
```

### Available Styles

**Text Attributes:**

- `.bold`, `.faint`/`.dim`, `.italic`, `.underline`
- `.blink`, `.reverse`, `.hidden`, `.strike`

**Foreground Colors:**

- Standard: `.black`, `.red`, `.green`, `.yellow`, `.blue`, `.magenta`, `.cyan`,
  `.white`, `.gray`
- Bright: `.bright_red`, `.bright_green`, `.bright_yellow`, `.bright_blue`,
  `.bright_magenta`, `.bright_cyan`, `.bright_white`
- 256-color: `.fg(0-255)`
- RGB: `.fg(r, g, b)`

**Background Colors:**

- Standard: `.on_black`, `.on_red`, `.on_green`, `.on_yellow`, `.on_blue`,
  `.on_magenta`, `.on_cyan`, `.on_white`
- 256-color: `.bg(0-255)`
- RGB: `.bg(r, g, b)`

## Handling Input

### Keyboard

```crystal
def update(msg : Message) : {Model, Cmd}
  case msg
  when KeyMsg
    case msg.key.to_s
    when "q"
      {self, Term2.quit}
    when "up", "k"
      # ...
    end
  end
end
```

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
