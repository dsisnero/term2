# Term2 Tutorials

This guide covers common patterns and best practices for building terminal
applications with Term2.

## Table of Contents

1. [Basic Counter Application](#basic-counter)
2. [Handling Multiple Key Types](#multiple-keys)
3. [Using Mouse Input](#mouse-input)
4. [Working with Timers](#timers)
5. [Building Multi-View Applications](#multi-view)
6. [Using Components](#components)
7. [Layout and Positioning](#layout)
8. [Error Handling](#error-handling)

---

## Basic Counter Application {#basic-counter}

Let's start with the simplest possible application - a counter.

```crystal
require "term2"
include Term2::Prelude

# 1. Define your model (application state)
class CounterModel < Model
  getter count : Int32

  def initialize(@count = 0)
  end
end

# 2. Define your application
class CounterApp < Application
  # Initialize the model
  def init
    CounterModel.new
  end

  # Handle messages and update the model
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

  # Render the view
  def view(model : Model) : String
    m = model.as(CounterModel)
    <<-VIEW
    Count: #{m.count}

    Press +/- to change, q to quit
    VIEW
  end
end

CounterApp.new.run
```

**Key Concepts:**
- Model holds all application state
- Update returns a new model (immutable updates)
- View renders the current state to a string

---

## Handling Multiple Key Types {#multiple-keys}

Term2 supports various key types beyond simple characters.

```crystal
def update(msg : Message, model : Model)
  m = model.as(MyModel)

  case msg
  when KeyPress
    key = msg.key_msg

    # Match by string representation
    case msg.key
    when "up", "k"
      move_up(m)
    when "down", "j"
      move_down(m)
    when "enter"
      select_item(m)
    when "esc"
      go_back(m)
    when "ctrl+c", "q"
      {m, Cmd.quit}
    end

    # Or match by key type
    case key.type
    when KeyType::Up
      move_up(m)
    when KeyType::F1
      show_help(m)
    when KeyType::CtrlC
      {m, Cmd.quit}
    end

    # Check for alt modifier
    if key.alt?
      # Alt was held
    end
  else
    {m, nil}
  end
end
```

**Available Key Types:**
- Arrow keys: `Up`, `Down`, `Left`, `Right`
- With modifiers: `CtrlUp`, `ShiftUp`, `CtrlShiftUp`
- Function keys: `F1` through `F20`
- Navigation: `Home`, `End`, `PgUp`, `PgDown`
- Control: `Tab`, `Enter`, `Esc`, `Backspace`
- Control combos: `CtrlA` through `CtrlZ`

---

## Using Mouse Input {#mouse-input}

Enable mouse tracking to receive mouse events.

```crystal
class MouseApp < Application
  def options : Array(ProgramOption)
    [
      WithMouseAllMotion.new,  # Track all motion (including hover)
      # Or use WithMouseCellMotion.new for just drag events
    ]
  end

  def update(msg : Message, model : Model)
    m = model.as(MyModel)

    case msg
    when MouseEvent
      case msg.action
      when MouseEvent::Action::Press
        handle_click(m, msg.x, msg.y, msg.button)
      when MouseEvent::Action::Release
        handle_release(m, msg.x, msg.y)
      when MouseEvent::Action::Move
        handle_hover(m, msg.x, msg.y)
      when MouseEvent::Action::Drag
        handle_drag(m, msg.x, msg.y)
      end

      # Check for modifiers
      if msg.ctrl?
        # Ctrl was held during mouse action
      end

      # Check specific buttons
      case msg.button
      when MouseEvent::Button::Left
        # Left click
      when MouseEvent::Button::WheelUp
        scroll_up(m)
      when MouseEvent::Button::WheelDown
        scroll_down(m)
      end
    end

    {m, nil}
  end
end
```

---

## Working with Timers {#timers}

Use `Cmd.tick` to create periodic updates.

```crystal
class ClockModel < Model
  getter time : Time
  getter running : Bool

  def initialize(@time = Time.local, @running = true)
  end
end

class ClockApp < Application
  def init
    # Return initial model with a tick command
    model = ClockModel.new
    cmd = start_tick
    {model, cmd}
  end

  private def start_tick : Cmd
    Cmd.tick(1.second) { |t| TickMsg.new(t) }
  end

  def update(msg : Message, model : Model)
    m = model.as(ClockModel)

    case msg
    when TickMsg
      if m.running
        new_model = ClockModel.new(msg.time, true)
        {new_model, start_tick}  # Schedule next tick
      else
        {m, nil}  # Stop ticking
      end
    when KeyPress
      case msg.key
      when "p"
        # Toggle pause
        {ClockModel.new(m.time, !m.running), m.running ? nil : start_tick}
      when "q"
        {m, Cmd.quit}
      else
        {m, nil}
      end
    else
      {m, nil}
    end
  end

  def view(model : Model) : String
    m = model.as(ClockModel)
    status = m.running ? "Running" : "Paused"
    "Time: #{m.time.to_s("%H:%M:%S")} [#{status}]\nPress p to pause, q to quit"
  end
end

class TickMsg < Message
  getter time : Time
  def initialize(@time); end
end

ClockApp.new.run
```

---

## Building Multi-View Applications {#multi-view}

Organize complex apps with multiple views/screens.

```crystal
enum Screen
  Main
  Settings
  Help
end

class AppModel < Model
  getter screen : Screen
  getter data : String

  def initialize(@screen = Screen::Main, @data = "")
  end
end

class MultiViewApp < Application
  def update(msg : Message, model : Model)
    m = model.as(AppModel)

    case msg
    when KeyPress
      # Global keys
      case msg.key
      when "q", "ctrl+c"
        return {m, Cmd.quit}
      when "?"
        return {AppModel.new(Screen::Help, m.data), nil}
      when "esc"
        return {AppModel.new(Screen::Main, m.data), nil}
      end

      # Screen-specific handling
      case m.screen
      when Screen::Main
        update_main(m, msg)
      when Screen::Settings
        update_settings(m, msg)
      when Screen::Help
        update_help(m, msg)
      end
    else
      {m, nil}
    end
  end

  def view(model : Model) : String
    m = model.as(AppModel)

    case m.screen
    when Screen::Main
      view_main(m)
    when Screen::Settings
      view_settings(m)
    when Screen::Help
      view_help(m)
    else
      ""
    end
  end

  # Separate methods for each screen...
  private def update_main(m, msg)
    case msg.key
    when "s"
      {AppModel.new(Screen::Settings, m.data), nil}
    else
      {m, nil}
    end
  end

  # ... etc
end
```

---

## Using Components {#components}

Term2 includes reusable components for common UI patterns.

```crystal
require "term2"
include Term2::Prelude

class MyModel < Model
  getter spinner : Components::Spinner::Model?
  getter progress : Components::ProgressBar::Model?

  def initialize(@spinner = nil, @progress = nil)
  end
end

class ComponentApp < Application
  @spinner : Components::Spinner
  @progress : Components::ProgressBar

  def initialize
    @spinner = Components::Spinner.new(
      frames: ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"],
      interval: 100.milliseconds
    )
    @progress = Components::ProgressBar.new(
      width: 30,
      complete_char: '█',
      incomplete_char: '░',
      show_percentage: true
    )
  end

  def init
    spinner_model, spinner_cmd = @spinner.init("Loading...")
    progress_model, progress_cmd = @progress.init

    model = MyModel.new(spinner_model, progress_model)
    {model, Cmd.batch(spinner_cmd, progress_cmd)}
  end

  def update(msg : Message, model : Model)
    m = model.as(MyModel)

    case msg
    when Components::Spinner::Tick
      if spinner = m.spinner
        new_spinner, cmd = @spinner.update(msg, spinner)
        {MyModel.new(new_spinner, m.progress), cmd}
      else
        {m, nil}
      end
    else
      {m, nil}
    end
  end

  def view(model : Model) : String
    m = model.as(MyModel)

    spinner_view = m.spinner ? @spinner.view(m.spinner.not_nil!) : ""
    progress_view = m.progress ? @progress.view(m.progress.not_nil!) : ""

    "#{spinner_view}\n#{progress_view}"
  end
end
```

---

## Layout and Positioning {#layout}

Use the `View` struct for layout calculations.

```crystal
def view(model : Model) : String
  m = model.as(MyModel)

  # Create a view representing the screen
  screen = Term2::View.new(0, 0, m.width, m.height)

  # Add margins
  content = screen.margin(top: 1, bottom: 1, left: 2, right: 2)

  # Split into regions
  header, body = content.split_vertical(0.1)  # 10% header
  sidebar, main = body.split_horizontal(0.25)  # 25% sidebar

  # Build the output using the calculated regions
  String.build do |io|
    # Position cursor at header
    io << "\e[#{header.y + 1};#{header.x + 1}H"
    io << "Header (#{header.width}x#{header.height})"

    # Draw sidebar
    io << "\e[#{sidebar.y + 1};#{sidebar.x + 1}H"
    io << "Sidebar"

    # Draw main content
    io << "\e[#{main.y + 1};#{main.x + 1}H"
    io << "Main Content Area"
  end
end
```

**View Methods:**
- `margin(top, right, bottom, left)` - Add margins
- `padding(all)` or `padding(h, v)` - Add padding
- `split_horizontal(ratio)` - Split left/right
- `split_vertical(ratio)` - Split top/bottom
- `center(width, height)` - Center a subview
- `contains?(x, y)` - Check if point is in view

---

## Error Handling {#error-handling}

Properly handle errors in commands.

```crystal
class ErrorMsg < Message
  getter error : Exception
  def initialize(@error); end
end

class SuccessMsg < Message
  getter result : String
  def initialize(@result); end
end

def fetch_data : Cmd
  Cmd.new {
    begin
      # Simulate async work
      sleep 0.1
      SuccessMsg.new("Data loaded!")
    rescue ex
      ErrorMsg.new(ex)
    end
  }
end

def update(msg : Message, model : Model)
  m = model.as(MyModel)

  case msg
  when SuccessMsg
    new_model = MyModel.new(data: msg.result, error: nil)
    {new_model, nil}
  when ErrorMsg
    new_model = MyModel.new(data: m.data, error: msg.error.message)
    {new_model, nil}
  else
    {m, nil}
  end
end
```

**Best Practices:**
- Always wrap command work in begin/rescue
- Create specific message types for success/error
- Don't let exceptions escape commands
- Consider using `WithoutCatchPanics` only in development

---

## Next Steps

- Check out the [examples](../examples/) directory
- Read the [Migration Guide](./migration-from-go.md) if coming from BubbleTea
- Explore the source code for advanced patterns
