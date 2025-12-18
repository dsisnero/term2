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
class CounterModel
  include Model

  getter count : Int32

  def initialize(@count = 0)
  end

  # Initialize the model
  def init : Cmd
    Cmds.none
  end

  # Handle messages and update the model
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

  # Render the view
  def view : String
    <<-VIEW
    Count: #{@count}

    Press +/- to change, q to quit
    VIEW
  end
end

# 2. Run the application
Term2.run(CounterModel.new)
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
      {m, Term2.quit}
    end

    # Or match by key type
    case key.type
    when KeyType::Up
      move_up(m)
    when KeyType::F1
      show_help(m)
    when KeyType::CtrlC
      {m, Term2.quit}
    end

    # Check for alt modifier
    if key.alt?
      # Alt was held
    end
  else
    {m, Cmds.none}
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
require "term2"
include Term2::Prelude

class MouseModel
  include Model

  getter x : Int32 = 0
  getter y : Int32 = 0
  getter last_action : String = "none"

  def initialize(@x = 0, @y = 0, @last_action = "none")
  end

  def init : Cmd
    Cmds.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when MouseEvent
      action = case msg.action
               when MouseEvent::Action::Press then "click"
               when MouseEvent::Action::Release then "release"
               when MouseEvent::Action::Move then "move"
               when MouseEvent::Action::Drag then "drag"
               else "unknown"
               end
      {MouseModel.new(msg.x, msg.y, action), Cmds.none}
    when KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        {self, Term2.quit}
      else
        {self, Cmds.none}
      end
    else
      {self, Cmds.none}
    end
  end

  def view : String
    "Mouse: (#{@x}, #{@y}) - #{@last_action}\nPress q to quit"
  end
end

# Run with mouse tracking enabled
Term2.run(MouseModel.new, options: Term2::ProgramOptions.new(
  WithMouseAllMotion.new  # Track all motion (including hover)
))
```

---

## Working with Timers {#timers}

Use `Cmds.tick` to create periodic updates.

```crystal
class ClockModel
  include Model

  getter time : Time
  getter? running : Bool

  def initialize(@time = Time.local, @running = true)
  end

  def init : Cmd
    start_tick
  end

  private def start_tick : Cmd
    Cmds.tick(1.second) { |t| TickMsg.new(t) }
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when TickMsg
      if running?
        {ClockModel.new(msg.time, true), start_tick}
      else
        {self, Cmds.none}
      end
    when KeyMsg
      case msg.key.to_s
      when "p"
        {ClockModel.new(@time, !@running), @running ? Cmds.none : start_tick}
      when "q"
        {self, Term2.quit}
      else
        {self, Cmds.none}
      end
    else
      {self, Cmds.none}
    end
  end

  def view : String
    status = running? ? "Running" : "Paused"
    "Time: #{@time.to_s("%H:%M:%S")} [#{status}]\nPress p to pause, q to quit"
  end
end

class TickMsg < Message
  getter time : Time
  def initialize(@time); end
end

Term2.run(ClockModel.new)
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

class AppModel
  include Model

  getter screen : Screen
  getter data : String

  def initialize(@screen = Screen::Main, @data = "")
  end

  def init : Cmd
    Cmds.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when KeyMsg
      # Global keys
      case msg.key.to_s
      when "q", "ctrl+c"
        return {self, Term2.quit}
      when "?"
        return {AppModel.new(Screen::Help, @data), Cmds.none}
      when "esc"
        return {AppModel.new(Screen::Main, @data), Cmds.none}
      end

      # Screen-specific handling
      case @screen
      when Screen::Main
        update_main(msg)
      when Screen::Settings
        update_settings(msg)
      when Screen::Help
        update_help(msg)
      else
        {self, Cmds.none}
      end
    else
      {self, Cmds.none}
    end
  end

  def view : String
    case @screen
    when Screen::Main
      view_main
    when Screen::Settings
      view_settings
    when Screen::Help
      view_help
    else
      ""
    end
  end

  # Separate methods for each screen...
  private def update_main(msg)
    case msg.key.to_s
    when "s"
      {AppModel.new(Screen::Settings, @data), Cmds.none}
    else
      {self, Cmds.none}
    end
  end

  private def update_settings(msg); {self, Cmds.none}; end
  private def update_help(msg); {self, Cmds.none}; end
  private def view_main; "Main Screen"; end
  private def view_settings; "Settings Screen"; end
  private def view_help; "Help Screen"; end
end
```

---

## Using Components {#components}

Term2 includes reusable components for common UI patterns.

```crystal
require "term2"
include Term2::Prelude

# Using the Spinner component
class SpinnerModel
  include Model

  property spinner : TC::Spinner

  def initialize
    @spinner = TC::Spinner.new(TC::Spinner::DOT)
    @spinner.style = Style.new.foreground(Color::CYAN)
  end

  def init : Cmd
    @spinner.tick  # Start the spinner animation
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when KeyMsg
      if msg.key.to_s == "q"
        return {self, Term2.quit}
      end
    end

    # Forward messages to spinner
    new_spinner, cmd = @spinner.update(msg)
    @spinner = new_spinner
    {self, cmd}
  end

  def view : String
    "#{@spinner.view} Loading... (press q to quit)"
  end
end

Term2.run(SpinnerModel.new)
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
  Cmds.message {
    begin
      # Simulate async work
      sleep 0.1
      SuccessMsg.new("Data loaded!")
    rescue ex
      ErrorMsg.new(ex)
    end
  }
end

def update(msg : Message) : {Model, Cmd}
  case msg
  when SuccessMsg
    {MyModel.new(data: msg.result, error: nil), Cmds.none}
  when ErrorMsg
    {MyModel.new(data: @data, error: msg.error.message), Cmds.none}
  else
    {self, Cmds.none}
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
