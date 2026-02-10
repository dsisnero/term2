# Term2 v2‑exp Notes

This document summarizes the v2‑exp API surface in Term2 and highlights the
areas that differ from Bubble Tea v1 or older Term2 APIs.

## Messages

- `Term2::Msg` is a union of Ultraviolet input events and any type that
  includes `Term2::MsgLike`.
- Prefer `Term2::MsgLike` for custom messages; it works with structs or classes.
- `Term2::Message` remains for legacy class-based messages.

Example:

```crystal
struct RefreshMsg
  include Term2::MsgLike
  getter at : Time

  def initialize(@at : Time)
  end
end
```

## View API

- `view` may return a `String` or a `Term2::View`.
- Use `View.new(content: ...)` when you need structured rendering features.

Example:

```crystal
def view : String | Term2::View
  Term2::View.new(content: "hello")
end
```

## Input Events

- Input is sourced from `Ultraviolet::TerminalReader` and surfaced as
  `Ultraviolet` event types (`UV::Key`, `UV::MouseClickEvent`, etc.).
- Use `Term2::KeyMsg` (alias of `UV::Key`) for key handling in `update`.

## Renderer

- `WithCursedRenderer` enables the Ultraviolet-based renderer, matching
  Bubble Tea v2 behavior.

## Commands

- `Cmd` is `Proc(Term2::Msg?)?`.
- `Cmds` provides helpers like `Cmds.batch`, `Cmds.sequence`, and `Cmds.tick`.

