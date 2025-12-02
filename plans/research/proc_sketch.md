# Crystal Proc-Based Elm Architecture Sketch

## Analysis of Bubble Tea Framework

### Core Types in Bubble Tea

From examining the bubbletea source code, the main types are:

1. **`Msg`** - An empty interface representing any message type
2. **`Model`** - Interface with three methods:
   - `Init() Cmd` - Returns initial command
   - `Update(Msg) (Model, Cmd)` - Handles messages, returns new model and optional command
   - `View() string` - Renders UI as string
3. **`Cmd`** - Function type `func() Msg` for side effects
4. **`Program`** - Main orchestrator that runs the event loop

### Key Design Patterns

- **Elm Architecture**: Model-Update-View pattern
- **Message Passing**: All state changes happen through messages
- **Side Effects**: Commands handle async operations
- **Functional Updates**: Update returns new model instance

## Crystal Implementation Design

### Core Type Definitions

```crystal
# Base message type - all messages must inherit from this
abstract struct Msg
end

# Command type - procs that return messages or nil
alias Cmd = Proc(Msg | Nil)

# Model protocol using Crystal modules
module Model(T)
  # Initialize and return optional command
  abstract def init : Cmd | Nil

  # Update state based on message, return new model and optional command
  abstract def update(msg : Msg) : Tuple(T, Cmd | Nil)

  # Render current state as string
  abstract def view : String
end

# Main program orchestrator
class Program(M)
  @model : M
  @update_channel : Channel(Msg)
  @cmd_channel : Channel(Cmd)
  @running : Bool = false

  def initialize(@model : M)
    @update_channel = Channel(Msg).new
    @cmd_channel = Channel(Cmd).new
  end
end
```

### Type Safety Advantages

1. **Compile-Time Message Checking**

```crystal
struct TickMsg < Msg
  getter timestamp : Time
end

struct KeyMsg < Msg
  getter key : String
end

# Compiler ensures all message types are handled
case msg
when TickMsg
  # Handle tick
when KeyMsg
  # Handle key press
# Compiler warns if we forget other message types
end
```

1. **Model Type Safety**

```crystal
struct CounterModel
  include Model(CounterModel)  # Self-referential type parameter

  getter count : Int32

  def update(msg : Msg) : Tuple(CounterModel, Cmd | Nil)
    # Must return same type - enforced by compiler
    case msg
    when TickMsg
      {CounterModel.new(@count + 1), nil}
    else
      {self, nil}
    end
  end
end
```

### Proc-Based Command System

```crystal
# Commands as lightweight procs
class Program(M)
  private def run_command(cmd : Cmd) : Nil
    spawn do
      begin
        if msg = cmd.call
          @update_channel.send(msg)
        end
      rescue ex
        # Type-safe error handling
        handle_command_error(ex)
      end
    end
  end

  # Batch commands for complex workflows
  def run_commands(commands : Array(Cmd)) : Nil
    commands.each { |cmd| @cmd_channel.send(cmd) }
  end
end

# Example command definitions
tick_cmd = ->{
  sleep 1.second
  TickMsg.new
}

http_cmd = ->{
  response = HTTP::Client.get("https://api.example.com/data")
  DataLoadedMsg.new(response.body)
}
```

### Complete Example Implementation

```crystal
# Simple timer equivalent to bubbletea example
struct SimpleTimer
  include Model(SimpleTimer)

  getter seconds : Int32

  def initialize(@seconds = 5)
  end

  def init : Cmd | Nil
    -> do
      sleep 1.second
      TickMsg.new
    end
  end

  def update(msg : Msg) : Tuple(SimpleTimer, Cmd | Nil)
    case msg
    when TickMsg
      if @seconds <= 1
        {self, ->{ QuitMsg.new }}
      else
        {SimpleTimer.new(@seconds - 1), -> do
          sleep 1.second
          TickMsg.new
        end}
      end
    when KeyMsg
      case msg.key
      when "q", "ctrl+c"
        {self, ->{ QuitMsg.new }}
      else
        {self, nil}
      end
    else
      {self, nil}
    end
  end

  def view : String
    "Program will exit in #{@seconds} seconds. Press 'q' to quit early."
  end
end

# Event loop implementation
class Program(M)
  def run : Nil
    @running = true

    # Run initial command
    if init_cmd = @model.init
      run_command(init_cmd)
    end

    # Initial render
    render(@model.view)

    # Main event loop
    event_loop
  end

  private def event_loop : Nil
    while @running
      select
      when msg = @update_channel.receive
        handle_message(msg)
      when cmd = @cmd_channel.receive
        run_command(cmd)
      when timeout(16.milliseconds)  # ~60 FPS
        # Optional: handle frame updates
      end
    end
  end

  private def handle_message(msg : Msg) : Nil
    new_model, cmd = @model.update(msg)
    @model = new_model

    # Re-render
    render(@model.view)

    # Execute returned command
    if cmd
      run_command(cmd)
    end

    # Handle special messages
    case msg
    when QuitMsg
      @running = false
    end
  end

  private def render(content : String) : Nil
    # Terminal rendering logic
    print "\r\e[2K#{content}"
  end
end
```

### Advanced Features

#### 1. Message Filtering

```crystal
class Program(M)
  @filters : Array(Msg -> Msg | Nil) = [] of Msg -> Msg | Nil

  def add_filter(&filter : Msg -> Msg | Nil) : Nil
    @filters << filter
  end

  private def apply_filters(msg : Msg) : Msg | Nil
    @filters.reduce(msg) do |current_msg, filter|
      break nil unless current_msg
      filter.call(current_msg)
    end
  end
end
```

#### 2. Batch Commands

```crystal
struct BatchCmd
  getter commands : Array(Cmd)

  def call : Msg | Nil
    channels = @commands.map do |cmd|
      channel = Channel(Msg | Nil).new
      spawn { channel.send(cmd.call) }
      channel
    end

    # Wait for all commands
    results = channels.map(&.receive)
    BatchCompleteMsg.new(results.compact)
  end
end
```

#### 3. Type-Safe Subscriptions

```crystal
module Subscriptions
  abstract def subscribe : Array(Cmd)
end

struct TimerModel
  include Model(TimerModel)
  include Subscriptions

  def subscribe : Array(Cmd)
    [->{ TickMsg.new }]
  end
end
```

## Performance Advantages

1. **Zero Interface Overhead**: Structs are value types, no vtable lookups
2. **Fast Proc Calls**: Crystal's proc invocation is highly optimized
3. **Lightweight Concurrency**: Fibers are much lighter than goroutines
4. **Compile-Time Optimizations**: Crystal can inline and optimize aggressively

## Memory Efficiency

1. **Value Semantics**: Models are copied rather than referenced
2. **No GC Pressure**: Structs avoid heap allocations
3. **Efficient Channels**: Crystal's channels are optimized for the use case

## Developer Experience Improvements

1. **Better Error Messages**: Crystal's compiler provides clearer type errors
2. **IDE Support**: Full type inference and completion
3. **Macro System**: Can create DSLs for common patterns
4. **Dependency Management**: Crystal's shards are simpler than Go modules

## Comparison with Bubble Tea

| Feature | Bubble Tea (Go) | Crystal Implementation |
|---------|-----------------|------------------------|
| Type Safety | Runtime (interfaces) | Compile-time (structs) |
| Performance | Good | Better (no interface overhead) |
| Memory Usage | Moderate | Lower (value types) |
| Concurrency | Goroutines | Fibers (lighter) |
| Error Handling | Manual | Exception system |
| Code Size | Moderate | More concise |

## Conclusion

This Crystal implementation maintains the Elm Architecture principles while leveraging Crystal's type system for:

- **Compile-time safety** through struct inheritance and generic constraints
- **Performance** through value types and optimized proc calls
- **Expressiveness** through Crystal's elegant syntax and macro system
- **Lightweight design** through fiber-based concurrency

The result is a system that's both safer and more efficient than the Go original, while being equally expressive for building terminal user interfaces.