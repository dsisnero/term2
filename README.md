# Term2

A Crystal port of the [Bubble Tea](https://github.com/charmbracelet/bubbletea) terminal UI library, built with concurrent ML (cml) for concurrency.

## Features

- **Elm Architecture**: Model-Update-View pattern for building terminal applications
- **Concurrent ML**: Built on [cml](https://github.com/dsisnero/cml) for efficient concurrency
- **200+ Key Sequences**: Support for xterm, urxvt, linux console, VT100/VT220
- **Mouse Support**: SGR and legacy X10 mouse protocols
- **Focus Reporting**: FocusIn/FocusOut events
- **Alternate Screen**: Clean terminal restoration
- **Components**: TextInput, Spinner, ProgressBar, CountdownTimer
- **Zone System**: Built-in focus and click tracking with automatic tab cycling
- **Tree/List/Table**: Static rendering components for hierarchical data; List includes filtering, pagination, help, and fuzzy-ranked matching with match highlighting
- **Rich Command System**: Batch, sequence, timeout, and async commands
- **Styling API**: Full color and style support with fluent API

### List filtering (quick start)

```crystal
list = Term2::Components::List.new(["Alpha", "Bravo", "Charlie"], 30, 10)
list.title = "Items"
list.show_filter = true
list.filtering_enabled = true

# Enter filtering mode (defaults to `/` key) and type; matches are ranked and highlighted.
list.set_filter_text("br")          # Programmatic apply/filter-applied state
matches = list.matches_for_item(0)  # Indices of matched characters for highlighting
```
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

class CounterModel
  include Model

  getter count : Int32

  def initialize(@count = 0); end

  def init : Cmd
    Cmds.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        {self, Term2.quit}
      when "+", "="
        {CounterModel.new(@count + 1), Cmds.none}
      when "-", "_"
        {CounterModel.new(@count - 1), Cmds.none}
      else
        {self, Cmds.none}
      end
    else
      {self, Cmds.none}
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

- `Model`, `Cmd`, `Cmds`, `Message` - Core types
- `TC` - Alias for `Term2::Components` (e.g., `TC::TextInput`)
- `KeyMsg`, `WindowSizeMsg`, `FocusMsg`, `BlurMsg` - Common messages
- `MouseEvent` - Mouse input events

## Key Bindings Helper

Define groups of key bindings with the `key_bindings` macro on `Term2::Components::Key`:

```crystal
class TimerKeymap
  Term2::Components::Key.key_bindings(
    start: { ["s"], "s", "start" },
    stop:  { ["s"], "s", "stop" },
    reset: { ["r"], "r", "reset" },
    quit:  { ["q", "ctrl+c"], "q", "quit" },
  )
end

# Usage
km = TimerKeymap.new
km.start.matches?(Term2::KeyMsg.new(Term2::Key.new("s")))
km.bindings # => Array of all bindings
```

If you include `Term2::Prelude`, you can use the shorter `TC::Key.key_bindings`:

```crystal
include Term2::Prelude

class SplitKeys
  TC::Key.key_bindings(
    next:   { ["tab"], "tab", "next" },
    prev:   { ["shift+tab"], "shift+tab", "prev" },
    quit:   { ["q", "esc"], "q", "quit" },
  )
end
```

This macro generates getters for each binding, an initializer, and a `bindings` array.

## Program Options

Configure your application by passing options to `Term2.run`:

```crystal
Term2.run(model, options: Term2::ProgramOptions.new(
  WithAltScreen.new,        # Use alternate screen buffer
  WithMouseAllMotion.new,   # Enable mouse tracking
  WithReportFocus.new       # Enable focus reporting
))
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

## Text Styling

Term2 provides multiple APIs for styled text output without raw escape codes:

### Method 1: String Extensions (Simple Single Styles)

For quick, simple styling:

```crystal
puts "Hello".bold
puts "Error!".red
puts "Warning".yellow.bold  # Note: chaining returns nested codes
```

### Method 2: S Builder (Chained/Composed Styles)

For basic color and attribute combinations:

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

### Method 3: Fluent Style API (Recommended for Complex Styling)

For advanced styling with borders, padding, margins, alignment, and complex layouts, use the `Term2::Style` class:

```crystal
# Create a styled box with border and padding
style = Term2::Style.new
  .bold(true)
  .foreground(Term2::Color::CYAN)
  .padding(1, 2)
  .border(Term2::Border.rounded)
  .width(30)
  .align(Term2::Position::Center)

puts style.render("Styled Box")

# Complex layout with multiple styles
title_style = Term2::Style.new
  .bold(true)
  .foreground(Term2::Color::WHITE)
  .background(Term2::Color.hex("#3366CC"))
  .padding(0, 2)

content_style = Term2::Style.new
  .padding(1)
  .border(Term2::Border.normal)
  .width(40)

puts title_style.render("Title")
puts content_style.render("Content goes here")
```

### Color Shorthands

- Named symbols: `style.foreground(:light_red)`, `style.background(:dark_gray)`, `style.background(:default)` (unset).
- Hex/RGB/indexed helpers: `style.fg_hex("#ff00aa").bg_rgb(30, 30, 30)`, `style.bg_indexed(240)`, or `style.fg(:red)` / `style.bg(:light_blue)`.
- Block builder: `style = Term2::Style.build { |s| s.fg_rgb(255, 128, 0).bold(true) }`.

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

**Style API Features:**

The `Term2::Style` class provides a comprehensive fluent API:

- **Text Formatting**: `.bold()`, `.italic()`, `.underline()`, `.strikethrough()`, `.reverse()`, `.blink()`, `.faint()`
- **Colors**: `.foreground()`, `.background()` (accepts `Color`, hex strings, or `AdaptiveColor`)
- **Dimensions**: `.width()`, `.height()`, `.max_width()`, `.max_height()`
- **Alignment**: `.align()`, `.align_horizontal()`, `.align_vertical()`
- **Padding**: `.padding()` (CSS-style shorthand), `.padding_top()`, `.padding_right()`, etc.
- **Margins**: `.margin()` (CSS-style shorthand), `.margin_top()`, `.margin_right()`, etc.
- **Borders**: `.border()`, `.border_style()`, `.border_top()`, `.border_foreground()`, `.border_background()`
- **Layout**: `.inline()`, `.tab_width()`, `.transform()`
- **Rendering**: `.render()` to apply style to text, `.to_s()` for string representation

## Zone System: Focus and Click Tracking

Term2 includes a built-in Zone system that incorporates BubbleZone functionality for focus and click management. This system allows components to register interactive zones and automatically receive focus/click events without requiring a separate BubbleZone dependency.

### How Zones Work

The Zone system works by embedding invisible markers in the rendered output that are scanned after each frame to determine zone positions:

1. **Zone Registration**: Components define an ID and wrap their output with `Zone.mark(id, content)`
2. **Automatic Scanning**: After each render, Term2 scans the output to extract zone positions using invisible Unicode markers
3. **Focus Management**: Zones can be focused via Tab/Shift+Tab or mouse clicks
4. **Click Handling**: Mouse clicks automatically dispatch to the correct zone with relative coordinates
5. **Keyboard Navigation**: Tab and Shift+Tab cycle through registered zones

### Basic Zone Usage

```crystal
# Mark clickable areas
Zone.mark("button1", "Click me!")
Zone.mark("button2", "Or click me!")

  # Handle clicks in update
  def update(msg : Message) : {Model, Cmd}
    case msg
    when ZoneClickMsg
      case msg.id
      when "button1"
        # Handle button1 click at (msg.x, msg.y)
        {self, Cmds.none}
      when "button2"
        # Handle button2 click
      {self, Cmds.none}
    end
    when ZoneFocusMsg
      # The component for msg.zone_id should focus itself
      {self, Cmds.none}
    else
      {self, Cmds.none}
    end
  end

# Tab through focusable zones
Zone.focus_next  # or Zone.focus_prev
```

### Component Integration with Zones

Components can easily integrate with the Zone system by implementing `zone_id` and using `Zone.mark`:

```crystal
class Button
  include Model

  getter label : String
  getter id : String

  def initialize(@label, @id); end

  def zone_id : String?
    @id
  end

  def view : String
    style = focused? ? Style.reverse : Style.new
    Zone.mark(@id, style.apply("[#{@label}]"))
  end

  def focused? : Bool
    Zone.focused?(@id)
  end

  def update(msg : Message) : {Button, Cmd}
    case msg
    when ZoneClickMsg
      if msg.id == @id && msg.action == MouseEvent::Action::Press
        # Handle button click
        puts "Button #{@id} clicked at (#{msg.x}, #{msg.y})"
        {self, Cmds.none}
      else
        {self, Cmds.none}
      end
    when ZoneFocusMsg
      # Component should focus itself when it receives focus
      {self, Cmds.none}
    else
      {self, Cmds.none}
    end
  end
end
```

### Zone Architecture

The Zone system is fully integrated into Term2's core:

- **Zone Module**: Provides global zone management (`Term2::Zone`)
- **ZoneInfo**: Tracks zone boundaries and coordinates
- **Zone Messages**: `ZoneClickMsg`, `ZoneFocusMsg` for event handling
- **Automatic Integration**: Built into the main event loop and render pipeline

### Focus Navigation

- **Tab**: Move focus to next zone (cycles through all registered zones)
- **Shift+Tab**: Move focus to previous zone
- **Mouse Click**: Focus clicked zone automatically on press
- **Programmatic**: Use `Zone.focus(id)` and `Zone.blur(id)`
- **Auto-focus**: Components can call `focus` method to request focus
- **Tab dispatch**: `ZoneFocusMsg` is emitted on Tab/Shift+Tab; components should call their own `focus` logic when they receive it

### Advanced Zone Features

- **Z-index Support**: Zones can have different z-index values for overlapping areas
- **Relative Coordinates**: Click events include coordinates relative to zone bounds
- **Efficient Scanning**: Zone scanning skips ANSI escape sequences
- **Spatial Indexing**: Optimized zone lookup by coordinates
- **Tab Cycle**: Automatic focus cycling through all interactive elements

### Integration with Event System

The Zone system is deeply integrated into Term2's event loop:

```crystal
# In the main event loop:
if zone_click = Zone.handle_mouse(mouse_event)
  # Auto-focus clicked zone on press
  if mouse_event.action == MouseEvent::Action::Press
    Zone.focus(zone_click.id)
  end
  dispatch(zone_click)
end

# Tab key handling:
if key.type == KeyType::Tab
  if next_id = Zone.focus_next
    dispatch(ZoneFocusMsg.new(next_id))
  end
end

# Components should handle ZoneFocusMsg by focusing themselves (for Tab/Shift+Tab).
```

### Built-in Components with Zone Support

- **TextInput**: Full-featured text input with cursor navigation and automatic zone registration
- **Checkbox**: Toggleable checkbox with focus support
- **Radio**: Radio button groups with keyboard navigation
- **Custom Components**: Any component can implement `zone_id` and use `Zone.mark`

## Layout System

Term2 provides multiple layout options:

### Join Utilities

Use layout join utilities to combine styled content:

```crystal
# Join content horizontally
Term2.join_horizontal(Term2::Position::Top, left_panel, right_panel)

# Join content vertically
Term2.join_vertical(Term2::Position::Left, header, content, footer)

# Place content at specific position
Term2.place(80, 24, Term2::Position::Center, Term2::Position::Center, content)
```

## Fluent Style API

Term2 provides a complete Lipgloss-style fluent API for advanced styling and layout in `Term2::Style`:

```crystal
style = Term2::Style.new
  .bold(true)
  .foreground(Term2::Color::RED)
  .padding(1, 2)
  .border(Term2::Border.rounded)
  .width(20)
  .align(Term2::Position::Center)

puts style.render("Hello Styled Text!")
```

The Style API provides comprehensive styling capabilities including:

- **Layout utilities**: `Term2.join_horizontal`, `Term2.join_vertical`, `Term2.place`
- **Borders**: Multiple border styles (normal, rounded, thick, double, hidden, block, half-block)
- **Spacing**: Full padding and margin control with CSS-style shorthand syntax
- **Alignment**: Horizontal and vertical alignment options
- **Colors**: Named colors, 256-color palette, true color RGB, adaptive colors, hex support
- **Text formatting**: Bold, italic, underline, strikethrough, reverse, blink, faint
- **Dimensions**: Fixed and maximum width/height constraints
- **Transformations**: Custom text transformation functions

## Handling Input

```crystal
def update(msg : Message) : {Model, Cmd}
  case msg
  when KeyMsg
    case msg.key.to_s
    when "q", "ctrl+c" then {self, Term2.quit}
    when "up", "k"     then move_up
    when "down", "j"   then move_down
    else                   {self, Cmds.none}
    end
  when MouseEvent
    handle_mouse(msg.x, msg.y, msg.button, msg.action)
    {self, Cmds.none}
  when FocusMsg
    {self, Cmds.none} # window gained focus
  when BlurMsg
    {self, Cmds.none} # window lost focus
  when WindowSizeMsg
    {self, Cmds.none} # resize to msg.width x msg.height
  else
    {self, Cmds.none}
  end
end
```

## Commands

```crystal
# No-op
Cmds.none

# Quit the application
Term2.quit

# Batch multiple commands
Cmds.batch(cmd1, cmd2, cmd3)

# Run commands in sequence
Cmds.sequence(cmd1, cmd2, cmd3)

# Tick command for timers
Cmds.tick(1.second) { TickMsg.new }

# Send a message
Cmds.message(MyCustomMsg.new(result))
```

## Components

### Spinner

```crystal
class SpinnerModel
  include Model
  property spinner : TC::Spinner = TC::Spinner.new(TC::Spinner::DOT)

  def init : Cmd
    @spinner.tick
  end

  def update(msg : Message) : {Model, Cmd}
    new_spinner, cmd = @spinner.update(msg)
    @spinner = new_spinner
    case msg
    when KeyMsg
      return {self, Term2.quit} if msg.key.to_s == "q"
    end
    {self, cmd}
  end

  def view : String
    "#{@spinner.view} Loading... (press q to quit)"
  end
end
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
# Create a text input with full features
input = Components::TextInput.new(
  placeholder: "Type here...",
  width: 40,
  prompt: "> ",
  echo_mode: Components::TextInput::EchoMode::Normal,
  char_limit: 100,
  id: "search_input"  # Zone ID for focus management
)

# Use in your model
class SearchModel
  include Model

  getter input : Components::TextInput

  def initialize
    @input = Components::TextInput.new(
      placeholder: "Search...",
      width: 50
    )
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when KeyMsg
      # Handle input focus
      return {self, Zone.focus_next} if msg.key.to_s == "tab"

      # Delegate to text input
      new_input, cmd = @input.update(msg)
      @input = new_input
      {self, cmd}
    when ZoneClickMsg
      if msg.id == "search_input"
        {self, @input.focus}
      else
        {self, Cmds.none}
      end
    else
      {self, Cmds.none}
    end
  end

  def view : String
    @input.view(self)
  end
end
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

```text
src/
  term2.cr           # Main module, Program, Cmds, KeyReader
  base_types.cr      # Model, Message, Key, KeyType
  key_sequences.cr   # Escape sequence mappings
  mouse.cr           # Mouse event handling
  renderer.cr        # StandardRenderer, NilRenderer
  terminal.cr        # Terminal control utilities, Cursor escapes
  style.cr           # Lipgloss-style fluent styling API
  zone.cr            # Zone system for focus/click tracking
  program_options.cr # Program configuration
  components/        # Built-in UI components
    text_input.cr    # Full-featured text input component
    table.cr         # Table component with StyleFunc
    list.cr          # List with Enumerators
    tree.cr          # Static tree renderer
    spinner.cr       # Loading spinner
    progress.cr      # Progress bar
    viewport.cr      # Scrollable viewport
    cursor.cr        # Cursor management
    key.cr           # Key binding system
```

## Contributing

1. Fork it (<https://github.com/dsisnero/term2/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

MIT License - see [LICENSE](LICENSE)
