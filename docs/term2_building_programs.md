# Tips for building Term2 programs (adapted from Bubble Tea)

Source: <https://leg100.github.io/en/posts/building-bubbletea-programs/>

This is a Term2-focused rewrite of the original Bubble Tea tips, with Crystal
examples that map to Term2 concepts.

## 0. Intro

Term2 follows the same Elm-style loop as Bubble Tea: messages flow into
`update`, which returns `{Model, Cmd}`, and then `view` renders the output.

The advice below focuses on keeping that loop responsive, debugging messages,
avoiding layout traps, and testing your TUI.

## 1. Keep the event loop fast

`update` and `view` run on every message. Slow work here makes your UI lag.
Push expensive work into a `Cmd` or a background fiber.

If it helps, here is the mental model of the loop:

```text
receive msg -> update(msg) -> run cmd -> view -> next msg
```

That means any expensive work in `update` or `view` blocks input handling,
cursor blinking, and rendering.

Bad (blocks the loop):

```crystal
def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
  case msg
  when Term2::KeyMsg
    sleep 1.second
  end
  {self, Term2::Cmds.none}
end
```

Good (offload with a command):

```crystal
class SlowMsg < Term2::Message
  getter payload : String

  def initialize(@payload : String)
  end
end

def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
  case msg
  when Term2::KeyMsg
    cmd = -> do
      sleep 1.second
      SlowMsg.new("done").as(Term2::Msg?)
    end
    return {self, cmd}
  when SlowMsg
    # handle result
  end
  {self, Term2::Cmds.none}
end
```

Counterexample: doing I/O directly in `view` (bad):

```crystal
def view : String
  File.read("large.txt") # blocks every render
end
```

Better: read once and cache, invalidate only when needed:

```crystal
def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
  case msg
  when ReloadMsg
    @cached_view = nil
  end
  {self, Term2::Cmds.none}
end

def view : String
  @cached_view ||= File.read("large.txt")
end
```

If you already have a long-running process, use `spawn` and dispatch back into
the program:

```crystal
def start_worker(program : Term2::Program(MyModel))
  spawn do
    loop do
      sleep 1.second
      program.dispatch(WorkerTick.new)
    end
  end
end
```

Also keep `view` lean. Heavy string building or formatting should be cached
when possible:

```crystal
def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
  case msg
  when DataLoadedMsg
    @rows = msg.rows
    @cached_view = nil # invalidate cache
  end
  {self, Term2::Cmds.none}
end

def view : String
  @cached_view ||= render_expensive_view
end
```

One more hint: the first message you usually receive is a `Term2::WindowSizeMsg`.
Make sure your model can render safely before that arrives, then resize once it does.

## 2. Dump messages to a file

Debugging is easier when you can see every message flowing through your model.

You can use `Log` and redirect to a file with `TERM2_LOG_FILE`:

```bash
TERM2_DEBUG=1 TERM2_LOG_FILE=$PWD/temp/term2_debug.log crystal run examples/my_app.cr
```

Then in your model:

```crystal
def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
  Log.debug { "msg=#{msg.class.name}" }
  # ...
end
```

If you want explicit dumps, open a file and write to it yourself:

```crystal
@dump = File.open("messages.log", "w")

def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
  @dump.puts(msg.inspect)
  {self, Term2::Cmds.none}
end
```

Counterexample: dumping to stdout in `view` (bad):

```crystal
def view : String
  puts "rendering" # pollutes UI output
  ""
end
```

Use `Log` or a file instead so you do not corrupt the renderer.

## 3. Live reload code changes

Term2 apps are still just CLI programs, so you can use file watchers to rebuild
and restart them. One simple approach is two shells:

Shell 1 (run app in a loop):

```bash
while true; do
  crystal run examples/my_app.cr
done
```

Shell 2 (rebuild and restart on file changes):

```bash
while true; do
  crystal build examples/my_app.cr -o /tmp/my_app && pkill -f /tmp/my_app
  rg --files src examples | entr -d true
done
```

Counterexample: using a watcher that steals stdin (bad):

```text
watch -n 1 crystal run examples/my_app.cr
```

The program will not behave correctly because stdin is no longer a TTY.

## 4. Use receiver methods on your model judiciously

Term2 models can be classes or structs. With a class model, mutating state in
helper methods is fine, but do not forget the `update` contract still returns
`{Model, Cmd}`. Prefer clear, direct mutations and avoid spreading behavior so
far that it becomes hard to follow.

If you use a struct model, remember that you are copying values and must return
the updated copy.

Counterexample: mutating a struct model in a helper without returning it (bad):

```crystal
struct CounterModel
  include Term2::Model
  @count = 0

  def bump
    @count += 1
  end
end

def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
  case msg
  when Term2::KeyMsg
    bump
  end
  {self, Term2::Cmds.none}
end
```

With structs, return the updated copy instead.

## 5. Messages are not necessarily received in the order they are sent

If you issue multiple `Cmd`s, Term2 batches them and processes results as they
arrive. That means:

- Do not assume ordering across commands.
- Include enough context in each message to reconcile state safely.

If you must enforce order, use `Term2::Cmds.sequence`.

Example: two commands that finish out of order:

```crystal
class ResultMsg < Term2::Message
  getter label : String
  def initialize(@label : String); end
end

def slow_cmd(label : String, delay : Time::Span) : Term2::Cmd
  -> do
    sleep delay
    ResultMsg.new(label).as(Term2::Msg?)
  end
end

def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
  case msg
  when Term2::KeyMsg
    cmd = Term2::Cmds.batch(
      slow_cmd("first", 500.milliseconds),
      slow_cmd("second", 100.milliseconds)
    )
    return {self, cmd}
  when ResultMsg
    @log << msg.label
  end
  {self, Term2::Cmds.none}
end
```

You might see `second` before `first`. If order matters, use sequence:

```crystal
cmd = Term2::Cmds.sequence(
  slow_cmd("first", 500.milliseconds),
  slow_cmd("second", 100.milliseconds)
)
```

### Race conditions: never mutate the model in a background fiber

The model is owned by the event loop. Do not change it in a `spawn`:

Bad:

```crystal
spawn { @count += 1 } # not safe
```

Good:

```crystal
class IncrementMsg < Term2::Message; end

spawn { program.dispatch(IncrementMsg.new) }

def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
  case msg
  when IncrementMsg
    @count += 1
  end
  {self, Term2::Cmds.none}
end
```

If you are issuing multiple concurrent commands, include a request id so you
can ignore stale responses:

```crystal
class FetchDoneMsg < Term2::Message
  getter request_id : Int32
  getter payload : String
  def initialize(@request_id : Int32, @payload : String); end
end

def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
  case msg
  when Term2::KeyMsg
    @request_id += 1
    id = @request_id
    cmd = -> do
      data = expensive_fetch
      FetchDoneMsg.new(id, data).as(Term2::Msg?)
    end
    return {self, cmd}
  when FetchDoneMsg
    return {self, Term2::Cmds.none} if msg.request_id != @request_id
    @data = msg.payload
  end
  {self, Term2::Cmds.none}
end
```

Counterexample: relying on order for state (bad):

```crystal
@user = ""
@profile = ""

cmd = Term2::Cmds.batch(fetch_user_cmd, fetch_profile_cmd)

# If profile depends on user, the profile might arrive first.
```

Make each message carry what it needs, or use `sequence`.

## 6. Build a tree of models

Complex UIs are easier to manage as a tree of smaller models. Each child model
can manage its own state, update, and view. Your root model can call:

```crystal
@list, list_cmd = @list.update(msg)
@viewport, vp_cmd = @viewport.update(msg)
cmd = Term2::Cmds.batch(list_cmd, vp_cmd)
```

This makes it easier to test and to reason about behavior.

Counterexample: one huge model with deeply nested conditionals (bad):

```crystal
def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
  case msg
  when Term2::KeyMsg
    if @mode == :menu
      # ...
    elsif @mode == :details
      # ...
    elsif @mode == :help
      # ...
    end
  end
  {self, Term2::Cmds.none}
end
```

Split by mode into smaller models or components.

## 7. Layout arithmetic is error-prone

Manual width and height math is a common source of bugs. Prefer measuring
rendered strings and using layout helpers:

```crystal
header = header_style.render("Title")
footer = footer_style.render("Help")
body_height = height - Term2.height(header) - Term2.height(footer)
body_style = Term2::Style.new.height(body_height)

Term2.join_vertical(
  Term2::Position::Top,
  header,
  body_style.render(content),
  footer
)
```

Use `Term2::Style.width`, `Term2::Style.height`, `Term2.width`, and `Term2.height`
to keep layout changes localized.

Counterexample: fixed math that drifts over time (bad):

```crystal
content = Term2::Style.new.height(@height - 5).render(body)
footer = footer_style.render("help")
Term2.join_vertical(Term2::Position::Top, header, content, footer)
```

If header/footer sizes change, the content height becomes wrong. Always measure
the actual rendered strings.

## 8. Recovering your terminal

If your program crashes before cleanup, your terminal can end up in raw mode
with no cursor. A simple reset is usually enough:

```bash
reset
```

Term2 handles many cases, but if you disable panic recovery or crash inside a
background command, you can still hit this.

Counterexample: panic inside a command (bad):

```crystal
cmd = -> do
  raise "boom"
  nil.as(Term2::Msg?)
end
```

Prefer to rescue inside the command and emit an error message.

## 9. Use Term2 teatest for end-to-end tests

This repo ships a helper for end-to-end tests under `spec/support/teatest.cr`.
Use it to run a program, send key messages, and assert output.

Start by reading the helper file and the existing specs under `spec/examples/`
to mirror patterns already in the codebase.

Counterexample: asserting by eye only (bad). Use teatest and golden output when
the UI should be stable.

## 10. Record demos and screenshots

Tools like VHS are still a great fit for TUIs. Keep your scripts (tapes)
alongside your example so that you can re-record when the UI changes.

Counterexample: manually recording gifs every time (bad). Keep the tape in
version control so demos are reproducible.

## 11. And more

Read the Term2 examples under `examples/` and the specs under `spec/examples/`
for real-world patterns. They are the fastest way to learn what works well
with this library.
