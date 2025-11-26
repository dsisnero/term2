# Migration Guide: BubbleTea (Go) to Term2 (Crystal)

This guide helps developers familiar with BubbleTea migrate their knowledge and applications to Term2.

## Overview

Term2 is a Crystal port of [BubbleTea](https://github.com/charmbracelet/bubbletea), implementing the Elm Architecture (Model-Update-View) for terminal applications. While the core concepts are the same, there are syntactic and idiomatic differences due to language differences.

## Quick Comparison

| Concept | BubbleTea (Go) | Term2 (Crystal) |
|---------|----------------|-----------------|
| Model | `type model struct` | `class MyModel < Model` |
| Message | `type myMsg struct` | `class MyMsg < Message` |
| Command | `func() tea.Msg` | `Cmd` (alias for `Proc(Message?)`) |
| Update | `func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd)` | `def update(msg, model) : {Model, Cmd?}` |
| View | `func (m model) View() string` | `def view(model) : String` |
| Init | `func (m model) Init() tea.Cmd` | `def init : Model` or `def init : {Model, Cmd?}` |

## Model Definition

### BubbleTea (Go)
```go
type model struct {
    count    int
    name     string
    quitting bool
}
```

### Term2 (Crystal)
```crystal
class AppModel < Term2::Model
  getter count : Int32
  getter name : String
  getter? quitting : Bool

  def initialize(@count = 0, @name = "", @quitting = false)
  end
end
```

**Key Differences:**
- Models must inherit from `Term2::Model`
- Use `getter` and `property` macros for accessors
- Crystal uses explicit type annotations

## Message Definition

### BubbleTea (Go)
```go
type tickMsg time.Time
type errMsg error

type statusMsg struct {
    code int
    text string
}
```

### Term2 (Crystal)
```crystal
class TickMsg < Term2::Message
  getter time : Time
  def initialize(@time); end
end

class ErrMsg < Term2::Message
  getter error : Exception
  def initialize(@error); end
end

class StatusMsg < Term2::Message
  getter code : Int32
  getter text : String
  def initialize(@code, @text); end
end
```

**Key Differences:**
- Messages must inherit from `Term2::Message`
- Crystal requires explicit class definitions

## Application Structure

### BubbleTea (Go)
```go
type model struct {
    count int
}

func (m model) Init() tea.Cmd {
    return nil
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    switch msg := msg.(type) {
    case tea.KeyMsg:
        switch msg.String() {
        case "q", "ctrl+c":
            return m, tea.Quit
        case "+":
            m.count++
        }
    }
    return m, nil
}

func (m model) View() string {
    return fmt.Sprintf("Count: %d\n", m.count)
}

func main() {
    p := tea.NewProgram(model{})
    if _, err := p.Run(); err != nil {
        log.Fatal(err)
    }
}
```

### Term2 (Crystal)
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
      when "+"
        {CounterModel.new(m.count + 1), Cmd.none}
      else
        {m, Cmd.none}
      end
    else
      {m, Cmd.none}
    end
  end

  def view(model : Model) : String
    m = model.as(CounterModel)
    "Count: #{m.count}\n"
  end
end

CounterApp.new.run
```

## Commands

### BubbleTea (Go)
```go
// No-op command
tea.Cmd(nil)

// Quit command
tea.Quit

// Batch commands
tea.Batch(cmd1, cmd2, cmd3)

// Sequence commands
tea.Sequence(cmd1, cmd2, cmd3)

// Tick command
tea.Tick(time.Second, func(t time.Time) tea.Msg {
    return tickMsg(t)
})
```

### Term2 (Crystal)
```crystal
# No-op command
Cmd.none
nil  # also works

# Quit command
Cmd.quit

# Batch commands
Cmd.batch(cmd1, cmd2, cmd3)

# Sequence commands
Cmd.sequence(cmd1, cmd2, cmd3)

# Tick command (using built-in)
Cmd.tick(1.second) { |t| TickMsg.new(t) }
```

## Key Handling

### BubbleTea (Go)
```go
func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    switch msg := msg.(type) {
    case tea.KeyMsg:
        switch msg.String() {
        case "q":
            return m, tea.Quit
        case "up":
            // handle up arrow
        case "ctrl+c":
            return m, tea.Quit
        }
        // Check specific key types
        if msg.Type == tea.KeyCtrlC {
            return m, tea.Quit
        }
    }
    return m, nil
}
```

### Term2 (Crystal)
```crystal
def update(msg : Message, model : Model)
  case msg
  when KeyPress
    case msg.key
    when "q"
      {model, Cmd.quit}
    when "up"
      # handle up arrow
      {model, nil}
    when "ctrl+c"
      {model, Cmd.quit}
    else
      {model, nil}
    end

    # Or check specific key types
    if msg.key_msg.type == KeyType::CtrlC
      {model, Cmd.quit}
    end
  else
    {model, nil}
  end
end
```

## Mouse Events

### BubbleTea (Go)
```go
case tea.MouseMsg:
    if msg.Type == tea.MouseLeft {
        // handle left click at msg.X, msg.Y
    }
    if msg.Type == tea.MouseWheelUp {
        // handle wheel up
    }
```

### Term2 (Crystal)
```crystal
case msg
when MouseEvent
  if msg.button == MouseEvent::Button::Left && msg.action == MouseEvent::Action::Press
    # handle left click at msg.x, msg.y
  end
  if msg.button == MouseEvent::Button::WheelUp
    # handle wheel up
  end
end
```

## Program Options

### BubbleTea (Go)
```go
p := tea.NewProgram(
    model{},
    tea.WithAltScreen(),
    tea.WithMouseAllMotion(),
    tea.WithoutCatchPanics(),
    tea.WithInput(customInput),
    tea.WithOutput(customOutput),
)
```

### Term2 (Crystal)
```crystal
class MyApp < Application
  def options : Array(ProgramOption)
    [
      WithAltScreen.new,
      WithMouseAllMotion.new,
      WithoutCatchPanics.new,
      WithInput.new(custom_input),
      WithOutput.new(custom_output),
    ]
  end
end
```

Or with `ProgramOptions`:
```crystal
options = ProgramOptions.new(
  WithAltScreen.new,
  WithMouseAllMotion.new,
)
program = Program.new(app, options)
```

## Window Size

### BubbleTea (Go)
```go
case tea.WindowSizeMsg:
    m.width = msg.Width
    m.height = msg.Height
```

### Term2 (Crystal)
```crystal
case msg
when WindowSizeMsg
  # msg.width and msg.height contain the new size
  new_model = MyModel.new(width: msg.width, height: msg.height)
  {new_model, nil}
end
```

## Focus Events

### BubbleTea (Go)
```go
// Enable focus reporting
tea.WithReportFocus()

// Handle focus events
case tea.FocusMsg:
    // Window gained focus
case tea.BlurMsg:
    // Window lost focus
```

### Term2 (Crystal)
```crystal
# Enable in options
def options
  [WithReportFocus.new]
end

# Handle focus events
case msg
when FocusMsg
  # Window gained focus
when BlurMsg
  # Window lost focus
end
```

## Common Patterns

### Immutable Updates
Both frameworks encourage immutable model updates:

```crystal
# Don't mutate the model directly:
# model.count += 1  # BAD

# Create a new model:
{MyModel.new(model.count + 1), nil}  # GOOD
```

### Type Casting
Crystal requires explicit type casting:

```crystal
def update(msg : Message, model : Model)
  m = model.as(MyModel)  # Cast to your specific model type
  # ...
end
```

### Error Handling
```crystal
class ErrorMsg < Message
  getter error : Exception
  def initialize(@error); end
end

# In a command:
Cmd.new {
  begin
    # ... do work
    SuccessMsg.new(result)
  rescue ex
    ErrorMsg.new(ex)
  end
}
```

## Type Aliases (Prelude)

Including `Term2::Prelude` provides convenient aliases:

```crystal
include Term2::Prelude

# Now you can use:
# - Application instead of Term2::Application
# - Model instead of Term2::Model
# - Message instead of Term2::Message
# - KeyPress instead of Term2::KeyMsg
# - Cmd instead of Term2::Cmd
# - etc.
```

## Further Resources

- [Term2 API Documentation](./api.md)
- [Example Applications](../examples/)
- [BubbleTea Documentation](https://github.com/charmbracelet/bubbletea)
