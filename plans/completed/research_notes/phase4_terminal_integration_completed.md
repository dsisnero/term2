# Phase 4: CML Integration with Terminal Applications - Research Summary

## Research Completed

### 1. CML-Based Event Loop Design for Terminal Applications

#### Key Architecture Patterns Identified

**Multi-Channel Event Loop Pattern:**

```crystal
class TerminalEventLoop
  def initialize
    @keyboard_chan = CML::Chan(KeyEvent).new
    @mouse_chan = CML::Chan(MouseEvent).new
    @resize_chan = CML::Chan(ResizeEvent).new
    @timer_chan = CML::Chan(TimerEvent).new
    @shutdown_chan = CML::Chan(Nil).new
  end

  def run
    spawn { handle_keyboard_input }
    spawn { handle_mouse_input }
    spawn { handle_resize_events }
    spawn { handle_timer_events }

    main_event_loop
  end

  private def main_event_loop
    loop do
      choice = CML.choose([
        @keyboard_chan.recv_evt,
        @mouse_chan.recv_evt,
        @resize_chan.recv_evt,
        @timer_chan.recv_evt,
        @shutdown_chan.recv_evt,
      ])

      event = CML.sync(choice)
      break if event.nil? # shutdown signal

      handle_event(event)
    end
  end
end
```

**Benefits of CML Event Loop:**

- **Non-blocking event selection**: `choose` handles multiple event sources efficiently
- **Type-safe event handling**: Each channel has specific event type
- **Graceful shutdown**: Dedicated shutdown channel for clean termination
- **Scalable architecture**: Easy to add new event sources

### 2. Terminal Input/Output Handling with CML

#### Input Processing Architecture

**CML IO Event Integration:**

```crystal
class TerminalInputHandler
  def initialize(@input_io : IO)
    @key_events = CML::Chan(KeyEvent).new
  end

  def start
    spawn do
      loop do
        # Use CML's read_evt for non-blocking IO
        bytes = CML.sync(CML.read_evt(@input_io, 1))
        break if bytes.empty?

        event = parse_key_event(bytes)
        CML.sync(@key_events.send_evt(event))
      end
    end
  end

  def key_event_evt : CML::Event(KeyEvent)
    @key_events.recv_evt
  end
end
```

**ANSI Sequence Parsing with CML:**

- **Buffered reading**: CML's `read_evt` with appropriate buffer sizes
- **Sequence detection**: State machine for escape sequence parsing
- **Event transformation**: Raw bytes → structured events

#### Output Rendering Patterns

**Channel-Based Output Buffering:**

```crystal
class TerminalRenderer
  def initialize(@output_io : IO)
    @render_commands = CML::Chan(RenderCommand).new
  end

  def start
    spawn do
      loop do
        command = CML.sync(@render_commands.recv_evt)
        render_to_terminal(command)
      end
    end
  end

  def render(command : RenderCommand)
    CML.sync(@render_commands.send_evt(command))
  end
end
```

### 3. Real-Time Terminal Updates with CML

#### Concurrent Rendering Architecture

**Frame-Based Rendering Pattern:**

```crystal
class ConcurrentTerminalRenderer
  def initialize
    @frame_chan = CML::Chan(Frame).new
    @render_complete_chan = CML::Chan(Nil).new
  end

  def render_loop
    spawn do
      loop do
        frame = CML.sync(@frame_chan.recv_evt)

        # Concurrent frame processing
        processed_frame = process_frame_concurrently(frame)

        # Signal completion
        CML.sync(@render_complete_chan.send_evt(nil))
      end
    end
  end

  def process_frame_concurrently(frame : Frame) : Frame
    # Use CML processes for parallel frame processing
    result_evts = frame.components.map do |component|
      CML.spawn_evt { process_component(component) }
    end

    # Wait for all components
    results = result_evts.map { |evt| CML.sync(evt) }

    Frame.new(results)
  end
end
```

### 4. Terminal Signal Handling with CML

#### Signal Integration Pattern

**CML-Based Signal Processing:**

```crystal
class TerminalSignalHandler
  def initialize
    @signal_chan = CML::Chan(Signal).new
  end

  def setup
    spawn do
      # Handle window resize
      Signal::WINCH.trap do
        CML.sync(@signal_chan.send_evt(Signal::WINCH))
      end

      # Handle interrupt
      Signal::INT.trap do
        CML.sync(@signal_chan.send_evt(Signal::INT))
      end
    end
  end

  def signal_evt : CML::Event(Signal)
    @signal_chan.recv_evt
  end
end
```

### 5. Performance Considerations for Terminal Applications

#### Event Loop Performance Optimization

**Key Findings:**

1. **Channel contention**: Minimal in terminal apps (low event frequency)
2. **Event creation overhead**: Acceptable for interactive applications
3. **Fiber scheduling**: Efficient for I/O-bound terminal operations

**Performance Patterns:**

- **Batch rendering**: Group multiple screen updates
- **Differential updates**: Only render changed screen regions
- **Event coalescing**: Merge rapid successive events

#### Memory Management

**Optimization Strategies:**

- **Object pooling**: Reuse event objects to reduce GC pressure
- **Buffer reuse**: Reuse byte buffers for input/output
- **Lazy allocation**: Defer object creation until needed

### 6. Error Handling and Recovery in CML Terminal Apps

#### Graceful Error Recovery Pattern

**Component Isolation with Channels:**

```crystal
class ErrorAwareTerminalComponent
  def initialize
    @error_chan = CML::Chan(ComponentError).new
    @recovery_chan = CML::Chan(RecoveryCommand).new
  end

  def run_with_recovery
    spawn do
      loop do
        choice = CML.choose([
          @error_chan.recv_evt,
          CML.timeout(1.second)  # Health check timeout
        ])

        case CML.sync(choice)
        when ComponentError
          handle_error_and_recover
        when :timeout
          # Component healthy, continue
        end
      end
    end
  end
end
```

### 7. CML Patterns for Bubble Tea Port Integration

#### Elm Architecture with CML

**Message Passing Pattern:**

```crystal
class ElmArchitectureWithCML
  def initialize
    @msg_chan = CML::Chan(Msg).new
    @model_chan = CML::Chan(Model).new
    @cmd_chan = CML::Chan(Cmd).new
  end

  def event_loop
    spawn do
      model = initial_model

      loop do
        choice = CML.choose([
          @msg_chan.recv_evt,
          CML.timeout(animation_interval),
          terminal_input_evt,
        ])

        event = CML.sync(choice)

        # Update model based on event
        new_model, cmd = update(model, event)
        model = new_model

        # Send model update
        CML.sync(@model_chan.send_evt(model))

        # Execute command if any
        execute_command(cmd) if cmd
      end
    end
  end
end
```

#### Component Communication Pattern

**Parent-Child Component Communication:**

```crystal
class ParentComponent
  def initialize
    @child_msg_chan = CML::Chan(Msg).new
    @parent_msg_chan = CML::Chan(Msg).new
  end

  def create_child
    ChildComponent.new(@child_msg_chan, @parent_msg_chan)
  end

  def handle_child_messages
    spawn do
      loop do
        msg = CML.sync(@parent_msg_chan.recv_evt)
        handle_message_from_child(msg)
      end
    end
  end
end
```

### 8. Integration with Existing Terminal Libraries

#### CML Wrapper for Terminal I/O

**Pattern for Wrapping Blocking I/O:**

```crystal
module TerminalIOWrapper
  def self.nonblocking_read(io : IO, timeout : Time::Span) : CML::Event(Bytes)
    CML.choose([
      CML.read_evt(io, 1024),
      CML.timeout(timeout).wrap { Bytes.empty }
    ])
  end

  def self.nonblocking_write(io : IO, data : Bytes) : CML::Event(Int32)
    CML.write_evt(io, data)
  end
end
```

### 9. Testing Strategies for CML Terminal Applications

#### Deterministic Testing Pattern

**Mock Terminal Input/Output:**

```crystal
class MockTerminal
  def initialize
    @input_chan = CML::Chan(String).new
    @output_chan = CML::Chan(String).new
  end

  def simulate_input(input : String)
    CML.sync(@input_chan.send_evt(input))
  end

  def capture_output : CML::Event(String)
    @output_chan.recv_evt
  end
end
```

### 10. Best Practices for CML Terminal Applications

#### Architecture Guidelines

1. **Separation of concerns**: Separate input, processing, and rendering
2. **Channel topology**: Star topology for component communication
3. **Error boundaries**: Isolate components for independent recovery
4. **Resource management**: Use cancellation for cleanup

#### Performance Guidelines

1. **Event frequency**: Limit high-frequency events with throttling
2. **Memory usage**: Monitor object allocations in hot paths
3. **Channel depth**: Use appropriate channel buffering
4. **Fiber count**: Limit concurrent fibers to reasonable numbers

## Key Insights for Bubble Tea Port

### Architecture Alignment

1. **Natural fit**: CML's event system aligns perfectly with Elm architecture
2. **Message passing**: Channels provide type-safe message passing between components
3. **Concurrent updates**: CML enables concurrent component rendering
4. **Error isolation**: Channel-based communication isolates component failures

### Performance Characteristics

1. **Low latency**: CML provides responsive event handling for interactive apps
2. **Efficient I/O**: CML's IO events integrate well with terminal I/O
3. **Scalable**: Architecture scales with application complexity
4. **Predictable**: Deterministic behavior aids debugging

### Integration Strategy

1. **Incremental adoption**: Start with core event loop, expand to components
2. **Pattern mapping**: Map Go channel patterns to CML equivalents
3. **Performance testing**: Benchmark critical paths early
4. **Error handling**: Design robust error recovery from start

## Success Criteria Met

- ✅ Comprehensive analysis of CML terminal integration patterns
- ✅ Design of CML-based event loop for terminal applications
- ✅ IO integration patterns with CML events
- ✅ Signal handling architecture with CML
- ✅ Performance optimization strategies
- ✅ Error handling and recovery patterns
- ✅ Bubble Tea integration strategy
- ✅ Testing strategies for concurrent terminal apps

## Files Examined

- `lib/cml/src/cml/io.cr` - CML IO event implementation
- `lib/cml/src/cml/io_helpers.cr` - Channel-based IO adapters
- `lib/cml/examples/chat_demo.cr` - Producer-consumer patterns
- `phase4_terminal_integration.md` - Research plan and architecture sketches

## Next Steps

### Implementation Priorities

1. **Core event loop**: Implement basic CML-based terminal event loop
2. **Input handling**: Add keyboard and mouse input with CML
3. **Output rendering**: Implement channel-based rendering
4. **Signal integration**: Add signal handling with CML channels
5. **Error recovery**: Implement graceful error recovery

### Research Validation

1. **Performance benchmarking**: Measure event loop performance
2. **Memory profiling**: Analyze memory usage patterns
3. **Integration testing**: Test with existing terminal components
4. **Real-world validation**: Apply patterns to sample applications

---

*Research completed as part of CML Mastery Research Plan - Phase 4*
