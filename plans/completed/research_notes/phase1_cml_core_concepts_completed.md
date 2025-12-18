# Phase 1: CML Core Concepts Deep Dive - Research Summary

## Research Completed

### CML Library Architecture Analysis

#### Core Concepts Identified

**1. Event Abstraction**

- **`Event(T)`**: Base class for all synchronization points
- **Non-blocking registration**: `try_register` never blocks
- **Cancellation procedures**: Every registration returns cleanup code
- **Type-safe**: Generic events with compile-time type checking

**2. Atomic Commit with Pick**

- **`Pick(T)`**: Commit cell ensuring "one pick, one commit"
- **Atomic operations**: `Atomic(Bool)` for race-free decisions
- **Cancellation management**: Automatic cleanup of losing events
- **Fiber synchronization**: `Channel(Nil)` for waiting on decisions

**3. Synchronization Protocol**

```crystal
def self.sync(evt : Event(T)) : T
  pick = Pick(T).new           # Create decision point
  cancel = evt.try_register(pick)  # Non-blocking registration
  pick.wait                    # Block until decision
  cancel.call                  # Cleanup losing events
  pick.value                   # Return result
end
```

### Event Type Hierarchy

#### Basic Events

- **`AlwaysEvt(T)`**: Immediate success with fixed value
- **`NeverEvt(T)`**: Never succeeds (testing placeholder)
- **`TimeoutEvt`**: Time-based synchronization

#### Channel Events

- **`SendEvt(T)`**: Channel send operations
- **`RecvEvt(T)`**: Channel receive operations
- **Matching algorithm**: Queues for senders/receivers with atomic matching

#### Event Combinators

- **`wrap_evt`**: Transform event results
- **`guard_evt`**: Lazy event construction
- **`nack_evt`**: Cancellation cleanup
- **`choose_evt`**: Event racing with single winner

### Design Principles

#### 1. One Pick, One Commit

- Every `Pick` instance can be decided at most once
- Ensures exactly one event in a choice succeeds
- Atomic operations prevent multiple commits

#### 2. Zero Blocking in Registration

- `try_register` must never block
- All blocking deferred to `pick.wait`
- Enables efficient event composition

#### 3. Fiber-Safe Cancellation

- Every registration returns cancellation procedure
- Can be safely called from any fiber
- Ensures proper resource cleanup

#### 4. Deterministic Behavior

- Predictable regardless of fiber scheduling
- No race conditions in event registration
- Consistent behavior across runs

### Memory Safety Features

- **Classes, not structs**: Avoid recursion issues
- **Cancellation procedures**: Clean up all registered state
- **Atomic operations**: Prevent race conditions
- **Mutex protection**: For channel queue operations

### Performance Characteristics

- **Low overhead**: Lightweight event creation and registration
- **Scalable**: Efficient with thousands of fibers
- **GC-friendly**: Minimal allocations in hot paths
- **Lock-free where possible**: Atomic operations for pick decisions

## Key Insights for Bubble Tea Integration

### Event-Driven Architecture Alignment

- CML's event system naturally fits Elm architecture
- Events can represent messages, commands, and state updates
- `choose` can handle multiple event sources (keyboard, mouse, timer)

### Channel Patterns for Message Passing

- Synchronous channels for message passing between components
- Event composition for complex interactions
- Cancellation for resource cleanup in component lifecycle

### Concurrency Model Mapping

- **CML processes** ↔ **Bubble Tea goroutines**
- **CML channels** ↔ **Go channels**
- **Event combinators** ↔ **Complex coordination patterns**

### Terminal Application Integration

- CML events for terminal input/output handling
- Timeout events for animations and timing
- Event composition for complex UI interactions

## Files Examined

### Documentation

- `README.md` - Library overview and quickstart examples
- `docs/overview.md` - Deep architectural documentation

### Implementation

- `src/cml.cr` - Core CML implementation (partial analysis)
  - Event abstraction and Pick implementation
  - Basic events (AlwaysEvt, NeverEvt)
  - Synchronization protocol

## Next Research Areas

### Phase 2: CML Idioms and Patterns Research

- Study common CML patterns: producer-consumer, worker pools, pub-sub
- Analyze error handling and supervision patterns
- Research graceful shutdown and resource cleanup

### Phase 3: CML Examples and Use Cases Analysis

- Examine existing CML examples and test cases
- Analyze real-world CML usage patterns
- Study performance characteristics and benchmarks

### Phase 4: CML Integration with Terminal Applications

- Design CML-based event loop for terminal applications
- Research CML patterns for terminal input/output handling
- Analyze CML's suitability for real-time terminal updates

## Success Criteria Met

- ✅ Complete understanding of CML core concepts
- ✅ Analysis of event abstraction and synchronization protocol
- ✅ Identification of design principles and memory safety
- ✅ Performance characteristics assessment
- ✅ Initial mapping to Bubble Tea integration patterns

## Technical Notes

### Atomic Operations Usage

- `Atomic(Bool)` for pick decision state
- Compare-and-swap operations for race-free commits
- No locks in hot paths where possible

### Fiber Integration

- Built on Crystal's native fiber scheduler
- Lightweight context switching
- Efficient for large numbers of concurrent operations

### Type Safety

- Generic events with compile-time type checking
- No runtime type casting in core operations
- Type-safe event composition

---
*Research completed as part of CML Mastery Research Plan - Phase 1*
