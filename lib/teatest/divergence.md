# Divergence: Crystal port vs Go v2 (vendor/x/exp/teatest/v2)

This document tracks intentional and accidental differences between the Crystal
port and the Go v2 reference, plus suggestions to reduce divergence.

## Current divergences

1. `Send("ignored msg")` vs `Term2::Msg` typing
- Go v2: `tea.Msg` is `interface{}` so tests can send arbitrary values like
  a plain string.
- Crystal: `Term2::Msg` is an abstract base class, so arbitrary types cannot be
  sent without wrapping.
- Current port: replaced `tm.send("ignored msg")` with `tm.type("ignored msg")`.

2. Key press message shape
- Go v2: `tea.KeyPressMsg{Code, Text}`
- Crystal: `Term2::KeyMsg` wraps `Term2::Key`
- Current port: uses `Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Enter))`
  and `type` builds `KeyMsg` from characters.

3. Golden test helper signature
- Go v2: `RequireEqualOutput(t, out)` takes `testing.TB` and uses `golden` to
  infer paths.
- Crystal: `Golden.require_equal(test_name, output, test_data_dir)` uses a
  test name string. The port now passes explicit names like `"TestApp"` and
  `"TestAppSendToOtherProgram"`.

4. `WaitFinished` timeout callback signature
- Go v2: `WithTimeoutFn(func(testing.TB))` passes the test handle.
- Crystal: callback signature is `->` (no arguments). The port mimics behavior
  by setting a boolean flag directly.

5. Renderer dependency require path
- Go v2: depends on bubbletea/v2 internal setup.
- Crystal: `lib/term2/src/cursed_renderer.cr` needed `require "ultraviolet"`
  instead of a relative path. This is now aligned with shard layout.

## Suggestions to reduce divergence

1. Allow sending non-`Term2::Msg` values in tests
- Add an overload `send(msg : _)` in `Teatest::TestModel` that wraps
  non-`Term2::Msg` values into a `Term2::Message` (e.g. `Term2::ValueMsg`).
- Alternatively add a `Term2::AnyMsg` that stores `Object` and can be ignored
  by models unless they explicitly handle it. This would allow direct parity
  with `Send("ignored msg")` from Go.

2. Provide a compatibility `KeyPressMsg`
- Add a small compatibility struct/class with `code`/`text` and a conversion
  to `Term2::KeyMsg`, so test code can mirror Go more directly.

3. Recreate `RequireEqualOutput(tb, out)`
- Add a helper that infers the spec name (e.g., from `Spec.current` if
  available) and uses `Golden.spec_test_data_dir`. This would remove the
  need to hardcode test names.

4. Align `WaitFinished` timeout callback signature
- Consider accepting `Proc(Spec::Context, Nil)` or similar to allow users to
  act on the current spec/test object. This would mirror Go’s `testing.TB`.

5. Introduce a `StringMsg` convenience
- If `Term2` is intended to feel like Bubble Tea v2, having a `StringMsg < Message`
  (and a helper `Term2.msg("...")`) would allow `Send("ignored msg")` parity
  without widening `Term2::Msg` to any type.

## Known remaining gaps

- The Crystal tests currently diverge in `Send("ignored msg")` and in golden
  helper naming. If strict parity is required, implement one of the options
  above and revert the tests to match Go v2 exactly.
