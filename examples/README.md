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

### 2. `input.cr` - Text Input Component
Demonstrates the TextInput component:
- Text input with cursor navigation
- Placeholder text
- Focus/blur functionality
- Key bindings for editing

**Run with:** `crystal run examples/input.cr`

### 3. `comprehensive_demo.cr` - All Components
A comprehensive demo showcasing all available Term2 components and features:

#### Components Demonstrated:
- **Counter**: Basic state management with increment/decrement
- **Timer**: Countdown timer with start/stop functionality
- **Spinner**: Animated loading spinner with custom frames
- **Progress Bar**: Visual progress indicator with percentage
- **Text Input**: Full-featured text input with navigation

#### Features Demonstrated:
- Component switching (press 1-5)
- Multiple concurrent components
- Message passing between components
- Custom themes and styling
- Terminal control sequences

#### Controls:
- `1-5`: Switch between components
- `h`: Show help
- `q` or `Ctrl+C`: Quit
- Component-specific controls shown in help

**Run with:** `crystal run examples/comprehensive_demo.cr`

### 4. `cmd_demo.cr` - Cmd Operations
Demonstrates the various Cmd operations available in Term2:

#### Cmd Operations Demonstrated:
- **Batch**: Execute multiple commands simultaneously
- **Sequence**: Execute commands in order with delays
- **After**: Schedule delayed commands
- **Every**: Execute commands periodically
- **Timeout**: Execute commands with timeout protection
- **Map**: Transform messages from commands
- **Perform**: Execute commands asynchronously

#### Controls:
- `b`: Batch commands
- `s`: Sequence commands
- `d`: Delayed command
- `p`: Periodic command
- `t`: Timeout command
- `m`: Mapped command
- `+/-`: Counter increment/decrement
- `q`: Quit

**Run with:** `crystal run examples/cmd_demo.cr`

## Key Term2 Concepts

### Application Architecture
All Term2 applications follow the Elm-inspired architecture:

```crystal
class MyApp < Application
  # Define your model
  record MyModel, count : Int32 do
    include Model
  end

  def init
    # Initialize model and optional command
    {MyModel.new(0), Cmd.none}
  end

  def update(msg : Message, model : Model)
    # Handle messages and update model
    case msg
    when KeyPress
      # Handle keyboard input
    else
      {model, Cmd.none}
    end
  end

  def view(model : Model) : String
    # Render the current state
    "Count: #{model.as(MyModel).count}"
  end
end
```

### Components
Term2 provides several built-in components:

- **CountdownTimer**: Timer with start/stop and finished notification
- **Spinner**: Animated loading indicator with custom themes
- **ProgressBar**: Visual progress indicator
- **TextInput**: Full-featured text input with navigation

### Cmd Operations
The `Cmd` struct provides various ways to perform side effects:

- `Cmd.none`: No operation
- `Cmd.message(msg)`: Dispatch a message
- `Cmd.batch(*cmds)`: Execute multiple commands
- `Cmd.sequence(*cmds)`: Execute commands in sequence
- `Cmd.after(duration, msg)`: Schedule a delayed message
- `Cmd.every(duration, &block)`: Execute periodically
- `Cmd.timeout(duration, timeout_msg, &block)`: Execute with timeout
- `Cmd.map(cmd, &block)`: Transform messages
- `Cmd.perform(&block)`: Execute asynchronously
- `Cmd.quit`: Quit the application

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