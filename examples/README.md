# Term2 Examples

This directory contains example applications demonstrating the functionality of the Term2 library.

## Available Examples

### 1. `simple.cr` - Basic Counter

A minimal example showing the core Term2 architecture:

- Basic Model-Update-View pattern
- KeyPress handling
- Simple state management
- Quit functionality

**Run with:** `crystal run examples/simple.cr`

### 2. `lipgloss_demo.cr` - Term2::Style API

Demonstrates advanced styling with the Term2::Style API:

- Style composition
- Borders and padding
- Color schemes
- Text alignment
- Components (Table, List, Tree)

**Run with:** `crystal run examples/lipgloss_demo.cr`

### 3. `libgloss_list_sublist.cr` - Nested List Example

Demonstrates nested lists with different enumerators and styles:

- Multi-level list nesting
- Different enumerator types (Arabic, Alphabet, Bullet)
- Custom styling per list level
- Mixed content (text and nested lists)

**Run with:** `crystal run examples/libgloss_list_sublist.cr`

### 4. `tabs_demo.cr` - Tabbed Interface

Example of a tabbed interface:

- Tab switching
- Content area management
- Focus tracking
- Keyboard navigation

**Run with:** `crystal run examples/tabs_demo.cr`

### 5. `mouse_and_focus.cr` - Mouse and Focus Events

Demonstrates mouse and focus event handling:

- Mouse click detection
- Focus reporting
- Event propagation

**Run with:** `crystal run examples/mouse_and_focus.cr`

### 6. `bubbles_spinner.cr` - Spinner Component

Shows the Spinner component with multiple styles:

- Animated loading indicator
- Multiple spinner themes
- Start/stop control

**Run with:** `crystal run examples/bubbles_spinner.cr`

### 7. `bubbles_table.cr` - Table Component

Demonstrates the Table component:

- Column definitions
- Row data
- Borders and styling
- StyleFunc for custom cell styling

**Run with:** `crystal run examples/bubbles_table.cr`

### 8. `bubbles_list.cr` - List Component

Shows the List component with enumerators:

- Bullet, numbered, alphabetic lists
- Item selection
- Custom enumerators

**Run with:** `crystal run examples/bubbles_list.cr`

### 9. `bubbles_text_input.cr` - Text Input Component

Full-featured text input with navigation:

- Cursor movement
- Text editing
- Placeholder text

**Run with:** `crystal run examples/bubbles_text_input.cr`

### 10. `stopwatch.cr` - Stopwatch Example

A stopwatch with start/stop/reset functionality:

- Time tracking with milliseconds
- Key bindings for control
- Help display

**Run with:** `crystal run examples/stopwatch.cr`

### 11. `bubblezone/list-default/main.cr` - Clickable List (Bubblezone port)

- Mouse wheel scrolling with `MouseEvent::Button::WheelUp/Down`
- Highlighted selection and zone-aware click targets
- Demonstrates translating a Bubblezone example using `Zone.mark`

**Run with:** `crystal run examples/bubblezone/list-default/main.cr`

### 12. `bubblezone/full-lipgloss/main.cr` - Full Lip Gloss Dashboard (Bubblezone port)

- Responsive tabs, list panels, dialog, and history presenter
- Uses zone buttons, list toggles, and history selections
- Shows how Bubblezone-style interaction can live in Term2

**Run with:** `crystal run examples/bubblezone/full-lipgloss/main.cr`

### 13. `libgloss/layout/main.cr` - Layout overview

- Demonstrates tabs, status panels, and responsive content areas
- Uses `Term2.join_horizontal`/`join_vertical` with styled blocks
- Navigate tabs with arrow or Tab, `q` to quit

**Run with:** `crystal run examples/libgloss/layout/main.cr`

### 14. `libgloss/list/main.cr` - Styled list navigation

- Highlights selectable rows, custom list item styles, and real-time feedback
- Move selection with arrow keys or `j/k`, `q` to exit
- Shows how `Term2::Style` can mimic Lip Gloss enumerations

**Run with:** `crystal run examples/libgloss/list/main.cr`

### 15. `libgloss/table/main.cr` - Table view

- Displays a simple table with header and rows
- Uses width constraints and separators to emulate columns
- Great base for data dashboards

**Run with:** `crystal run examples/libgloss/table/main.cr`

### 16. `libgloss/tree/main.cr` - Tree diagram

- Presents a static project tree with branches
- Styled text and indentation to mimic tree command output
- Useful for file explorers or project navigation overviews

**Run with:** `crystal run examples/libgloss/tree/main.cr`

### 17. `libgloss/ssh/main.cr` - SSH status card

- Stylized connection metadata and command preview
- Shows how to render terminal-like info using `Term2::Style`
- A simple way to prototype connection dashboards

**Run with:** `crystal run examples/libgloss/ssh/main.cr`

## Key Term2 Concepts

### Application Architecture

All Term2 applications follow the Elm-inspired architecture. Note that `Model` is a module to include, not a class to inherit from:

```crystal
require "term2"
include Term2::Prelude

# Define your model
class MyModel
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
        {MyModel.new(@count + 1), Cmds.none}
      else
        {self, Cmds.none}
      end
    else
      {self, Cmds.none}
    end
  end

  def view : String
    "Count: #{@count}"
  end
end

# Run the application
Term2.run(MyModel.new)
```

### Components

Term2 provides several built-in components:

- **CountdownTimer**: Timer with start/stop and finished notification
- **Spinner**: Animated loading indicator with custom themes
- **ProgressBar**: Visual progress indicator
- **TextInput**: Full-featured text input with navigation

### Cmds Operations

The `Cmds` module provides various ways to perform side effects:

- `Cmds.none`: No operation
- `Cmds.message(msg)`: Dispatch a message
- `Cmds.batch(*cmds)`: Execute multiple commands
- `Cmds.sequence(*cmds)`: Execute commands in sequence
- `Cmds.after(duration, msg)`: Schedule a delayed message
- `Cmds.every(duration, &block)`: Execute periodically
- `Cmds.timeout(duration, timeout_msg, &block)`: Execute with timeout
- `Cmds.map(cmd, &block)`: Transform messages
- `Cmds.perform(&block)`: Execute asynchronously
- `Term2.quit`: Quit the application

## Running Examples

1. Ensure you have Crystal installed
2. Install dependencies: `shards install`
3. Run any example: `crystal run examples/filename.cr`

## Debug Mode

Set the `TERM2_DEBUG` environment variable to see debug output:

```bash
TERM2_DEBUG=1 crystal run examples/comprehensive_demo.cr
```

This will show message handling and command execution details.