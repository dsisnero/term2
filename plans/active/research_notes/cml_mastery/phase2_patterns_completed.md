# Phase 2: CML Idioms and Patterns Research - Completed

## Research Summary

### Common CML Patterns Identified

#### 1. Producer-Consumer Pattern
**Chat Room Example** - Multiple producers, multiple consumers
```crystal
class ChatRoom
  def initialize
    @chan = CML::Chan(String).new
  end

  def post(msg : String)
    CML.sync(@chan.send_evt(msg))
  end

  def subscribe(name : String, n : Int32 = 3)
    spawn do
      n.times do
        msg = CML.sync(@chan.recv_evt)
        puts "[#{name}] got: #{msg}"
      end
    end
  end
end
```

**Key Characteristics:**
- Multiple senders and receivers on same channel
- Synchronous rendezvous communication
- Automatic matching of senders and receivers
- Real-time message delivery

#### 2. Worker Pool Pattern
```crystal
result_evt = CML.spawn_evt { compute_something() }
CML.sync(result_evt)
```

**Implementation Details:**
- `spawn_evt` creates channel and spawns fiber
- Returns receive event for result
- Automatic exception handling in worker
- Type-safe result delivery

#### 3. Pub-Sub Pattern
```crystal
# Multiple subscribers pattern
room.subscribe("alice")
room.subscribe("bob")
spawn { ["hi", "how are you?", "bye"].each { |msg| room.post("alice: #{msg}") } }
spawn { ["hello", "fine!", "see ya"].each { |msg| room.post("bob: #{msg}") } }
```

**Features:**
- Multiple independent subscribers
- Broadcast communication
- Synchronous message delivery
- Automatic load balancing

#### 4. Timeout Worker Pattern
```crystal
# Timeout with result handling
result = CML.sync(CML.with_timeout(long_running_evt, 2.seconds))
if result[1] == :timeout
  puts "Worker timed out!"
else
  puts "Worker finished: #{result[0]}"
end
```

**Error Handling Patterns:**
- Timeout detection with result tuples
- Graceful degradation on timeout
- Resource cleanup on cancellation
- Automatic timeout event creation

## Advanced Patterns from Specs

#### 5. Nested Choose Operations
```crystal
# Complex event composition
inner_choice = CML.choose([ch1.recv_evt, CML.always(42)])
outer_choice = CML.choose([
  CML.wrap(inner_choice) { |x| "inner: #{x}" },
  CML.wrap(ch2.recv_evt) { |str| "string: #{str}" },
])
```

**Benefits:**
- Hierarchical event selection
- Result transformation at each level
- Maintains "one pick, one commit" guarantee
- Type-safe composition

#### 6. Guard with Conditional Logic
```crystal
# Lazy event construction with conditions
guarded = CML.guard do
  if condition.get
    CML.always(:ready)
  else
    CML.timeout(0.1.seconds)
  end
end
```

**Lazy Evaluation:**
- Guard block executes only when needed
- Conditional event construction
- Efficient resource usage
- Dynamic behavior based on runtime state

#### 7. Nack Propagation for Cleanup
```crystal
# Multi-layer cancellation cleanup
wrapped_nack = CML.wrap(
  CML.nack(ch.recv_evt) { called.set(true) }
) { |x| x }
```

**Cleanup Guarantees:**
- Nested cancellation handlers
- Automatic cleanup on event loss
- Resource management
- No resource leaks

## Error Handling and Supervision

### Exception Propagation
- Worker exceptions are caught in `spawn_evt`
- No automatic exception propagation to sync
- Manual error handling required
- Type-safe error handling

### Graceful Shutdown
```crystal
# Cancellation procedures ensure cleanup
cancel = evt.try_register(pick)
pick.wait
cancel.call  # Cleanup losing events
```

**Resource Management:**
- Automatic cleanup on cancellation
- No resource leaks
- Fiber-safe operations
- Deterministic behavior

## Performance Patterns

### Event Creation Overhead
- **AlwaysEvt**: Minimal overhead - immediate success
- **WrapEvt**: Lightweight transformation
- **GuardEvt**: Deferred construction
- **ChooseEvt**: Polling optimization for immediate winners

### Channel Performance
- **Synchronous rendezvous**: Moderate overhead
- **Two-fiber communication**: Fiber scheduling cost
- **Single-fiber patterns**: Lower overhead
- **Queue management**: Mutex-protected operations

### Choose Optimization
- **Polling for immediate winners**: Early termination
- **Efficient cancellation**: Automatic cleanup of losers
- **Atomic commit**: Race-free decision making

## Bubble Tea Integration Patterns

### Message Passing Architecture
```crystal
# Elm architecture with CML
model_channel = CML::Chan(Model).new
message_channel = CML::Chan(Msg).new

# Event loop with choose
main_loop = CML.choose([
  message_channel.recv_evt,
  CML.timeout(animation_interval),
  terminal_input_evt,
])
```

### Component Communication
- Channels for inter-component messages
- Event composition for complex interactions
- Timeout events for animations
- Type-safe message passing

### State Management
- IVar/MVar for shared state (from specs)
- Channel-based state updates
- Event-driven state transitions
- Atomic state operations

## Testing Patterns

### Deterministic Testing
```crystal
# Sync determinism test
result1 = CML.sync(ev)
result2 = CML.sync(CML.always(result1))
result1.should eq(result2)
```

### Fairness Testing
- No fiber starvation under load
- Balanced event selection
- Predictable behavior
- Consistent performance

## Anti-Patterns Identified

### 1. Blocking in Registration
- `try_register` should never block
- All blocking deferred to `pick.wait`
- Violation causes deadlocks

### 2. Missing Cancellation
- Forgetting to call cancellation procedures
- Resource leaks
- Incomplete cleanup

### 3. Complex Nested Guards
- Overly complex guard logic
- Difficult to reason about
- Performance overhead

## Best Practices

### 1. Use DSL Helpers
```crystal
# Prefer helpers over manual construction
CML.after(1.second) { puts "done" }  # Good
# Manual timer wheel usage  # Avoid
```

### 2. Leverage Type Safety
- Generic events for compile-time checking
- Type-safe event composition
- No runtime type casting

### 3. Keep Events Simple
- Single responsibility for events
- Compose complex behavior
- Avoid monolithic event types

## Files Examined
- `docs/cookbook.md` - Common patterns and idioms
- `examples/chat_demo.cr` - Producer-consumer implementation
- `spec/advanced_cml_specs_spec.cr` - Complex pattern testing
- `spec/cml_comprehensive_spec.cr` - Nested operations testing

## Key Insights for Bubble Tea Port

### Architecture Alignment
- CML's event system naturally fits Elm architecture
- Events can represent messages, commands, and state updates
- `choose` can handle multiple event sources (keyboard, mouse, timer)

### Performance Considerations
- Low overhead for high-frequency message processing
- Efficient coordination between multiple event sources
- Automatic resource cleanup for component lifecycle

### Integration Strategy
- Start with core message passing patterns
- Leverage event composition for complex interactions
- Use cancellation for resource management

## Success Criteria Met

- ✅ Comprehensive analysis of CML patterns and idioms
- ✅ Identification of common concurrency patterns
- ✅ Advanced pattern analysis from specs
- ✅ Error handling and supervision patterns
- ✅ Performance pattern analysis
- ✅ Bubble Tea integration strategy

---
*Research completed as part of CML Mastery Research Plan - Phase 2*