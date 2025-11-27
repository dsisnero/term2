# Phase 4: CML Integration with Terminal Applications - Research Notes

## Overview

This phase focuses on designing CML-based architecture for terminal applications, specifically targeting the Bubble Tea port requirements.

## Research Areas

### 1. CML-Based Event Loop Design

#### Current Terminal Event Handling Patterns

- **Blocking I/O** vs **Non-blocking I/O** approaches
- **Event polling** mechanisms in existing terminal libraries
- **Signal handling** for terminal resize and interrupt events

#### CML Event Loop Architecture

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

### 2. Terminal Input/Output Handling with CML

#### Input Processing Patterns

- **Raw mode** vs **cooked mode** terminal input
- **ANSI escape sequence** parsing
- **Key press** vs **key release** events
- **Mouse event** handling

#### Output Rendering Patterns

- **Screen buffer** management
- **Differential updates** for performance
- **ANSI escape sequence** generation
- **Cursor positioning** and movement

### 3. Real-Time Terminal Updates

#### Concurrent Rendering Architecture

```crystal
class TerminalRenderer
  def initialize
    @render_chan = CML::Chan(RenderCommand).new
    @frame_chan = CML::Chan(Frame).new
  end

  def render_loop
    spawn do
      loop do
        command = CML.sync(@render_chan.recv_evt)
        frame = render_frame(command)
        CML.sync(@frame_chan.send_evt(frame))
      end
    end
  end

  def display_loop
    spawn do
      loop do
        frame = CML.sync(@frame_chan.recv_evt)
        display_frame(frame)
      end
    end
  end
end
```

### 4. Terminal Signal Handling

#### Signal Processing with CML

- **SIGWINCH** (window resize) handling
- **SIGINT** (interrupt) graceful shutdown
- **SIGTERM** (termination) cleanup

#### Signal Integration Pattern

```crystal
class SignalHandler
  def initialize
    @signal_chan = CML::Chan(Signal).new
  end

  def handle_signals
    spawn do
      Signal::WINCH.trap do
        CML.sync(@signal_chan.send_evt(Signal::WINCH))
      end

      Signal::INT.trap do
        CML.sync(@signal_chan.send_evt(Signal::INT))
      end
    end
  end
end
```

### 5. Performance Considerations

#### Event Loop Performance

- **Event selection** overhead vs polling
- **Channel contention** in high-frequency events
- **Memory allocation** patterns for event objects

#### Rendering Performance

- **Frame rate** vs **update frequency** trade-offs
- **Screen buffer** management strategies
- **ANSI optimization** for minimal output

### 6. Error Handling and Recovery

#### Graceful Error Recovery

- **Component isolation** through channel-based communication
- **Timeout mechanisms** for unresponsive components
- **Fallback strategies** for rendering failures

#### Error Propagation

```crystal
class ErrorAwareComponent
  def initialize
    @error_chan = CML::Chan(Error).new
    @recovery_chan = CML::Chan(RecoveryCommand).new
  end

  def handle_errors
    spawn do
      loop do
        error = CML.sync(@error_chan.recv_evt)
        recovery_command = determine_recovery(error)
        CML.sync(@recovery_chan.send_evt(recovery_command))
      end
    end
  end
end
```

## Research Questions

### Architecture Questions

1. How to structure CML processes for terminal application components?
2. What channel topology best supports component communication?
3. How to handle backpressure in high-frequency event scenarios?

### Performance Questions

1. What is the optimal event loop structure for terminal applications?
2. How to minimize latency in user input processing?
3. What are the memory implications of CML-based terminal applications?

### Integration Questions

1. How to integrate CML with existing terminal I/O libraries?
2. What patterns work best for combining CML with Crystal's fiber scheduler?
3. How to handle platform-specific terminal behaviors?

## Next Steps

- Analyze existing terminal library architectures
- Design CML-based component communication patterns
- Create performance benchmarks for terminal event handling
- Develop integration patterns for common terminal operations
