# Commands in Term2

*Adapted from the Bubble Tea blog post "[Commands in Bubble Tea](https://charm.land/blog/commands-in-bubbletea/)" for Term2, the Crystal port.*

Because of its [Elm](https://elm-lang.org)-inspired roots, Term2 has a special approach to asynchronous operations: **commands**.

Commands are a fundamental part of Term2 and are present whenever I/O needs to happen. You may have already encountered built-in commands such as `Term2.quit`, `Term2::Cmds.tick`, and `Term2::Cmds.batch`.

If you're just getting started with Term2, we recommend checking out the [Term2 Tutorials](./tutorials.md) and [Migration Guide from BubbleTea (Go)](./migration-from-go.md). This guide assumes you're familiar with the Elm Architecture (Model-Update-View) pattern.

Most examples in this guide assume you have `include Term2::Prelude` in your file, which provides convenient aliases like `Cmd`, `Model`, `Message`, etc.

## Rules of thumb

There are three things to keep in mind with regard to asynchronous operations in Term2:

- **Use commands for all I/O.** By doing so your program will stay responsive, snappy, and maintainable. Even something as simple as reading a file from disk could cause a small lock up in your program, and commands are built to handle such cases beautifully.
- **Only use commands for I/O.** Sometimes it's tempting to use a command simply to send a message to another part of the program, however due to the nature of the way data flows in Term2 this is never actually necessary.
- **Never use fibers (`spawn`) directly within a Term2 program.** Term2 works best when you use commands and messages for communication. The framework handles concurrency using the CML (Communicating Mobile Processes) library.

## The basics

So how would we write our own commands?

A `Cmd` is simply an alias for `(-> Message)?` (a function that returns a message, or `nil`). In practice, it's defined as:

```crystal
alias Cmd = ((-> Msg) | (-> Msg?))?
```

This alias is defined in `src/base_types.cr`. In practice, you'll rarely need to write the type signature explicitly—just return a proc (or `nil`) from `init` or `update`.

A command could be something as simple as:

```crystal
class HelloMsg < Message
  getter text : String

  def initialize(@text); end
end

def wait_a_sec : Term2::Cmd
  -> do
    sleep 1.second
    HelloMsg.new("Hi, there!")
  end
end
```

But how would you respond to such a command? You'd match on it in your update method.

```crystal
def update(msg : Message) : {Model, Cmd}
  case msg
  when HelloMsg
    # We caught our message!
    # From here you could save the output to the model
    # to display it later in your view.
    @greeting = msg.text
    {self, nil}
  else
    {self, nil}
  end
end
```

## Differences from Bubble Tea

While Term2 aims to be a faithful port of Bubble Tea, there are some differences in how commands are implemented due to language differences:

| Concept | Bubble Tea (Go) | Term2 (Crystal) |
|---------|----------------|-----------------|
| Message type | `interface{}` (any type) | `Message` base class (inheritance) |
| Command type | `func() tea.Msg` | `Cmd` = `((-> Msg) \| (-> Msg?))?` |
| Returning commands | `tea.Batch(cmds...)` | `Term2::Cmds.batch(*cmds)` |
| Model interface | `Init() tea.Cmd` method | `def init : Cmd` method |
| Update return | `(tea.Model, tea.Cmd)` | `{Model, Cmd}` tuple |

Key points:
- In Term2, all messages must inherit from `Term2::Message` (or use `Term2::Msg` alias)
- Commands can return `nil` (no message) or a `Message` instance
- The `Cmd` type is nullable (`?`) - returning `nil` from `init` or `update` means no command
- Use `Term2::Cmds` module for command constructors instead of package-level functions

For a complete migration guide, see [Migration Guide from BubbleTea (Go)](./migration-from-go.md).

## Multiple commands

Sometimes you want to fire off more than one command at once. For that, use `Term2::Cmds.batch`.

```crystal
def chores_cmd : Term2::Cmd
  Term2::Cmds.batch(get_the_laundry, eat_dinner, pet_the_cats)
end
```

## Commands with arguments

What if you want to make a command that takes an argument? Since `Cmd` is a function that takes no arguments, it can't take an argument directly. So what do you do in that case? You make a function that returns a command.

```crystal
def get_user(id : Int32) : Term2::Cmd
  -> do
    user = API.get_user_by_id(id)
    GotUserMsg.new(user)
  end
end
```

In your `update` function it would look something like this:

```crystal
return {self, get_user(88)}
```

## Initial commands

Sometimes you'll want to fire off a command right as your Term2 program starts without waiting for user input. For that, use `Model#init`:

```crystal
def init : Term2::Cmd
  fetch_users
end
```

Or, for multiple commands:

```crystal
def init : Term2::Cmd
  Term2::Cmds.batch(
    fetch_users,
    spinner.tick,
  )
end
```

## API calls from Term2

A lot of the time you'll want to make API calls from Term2. Commands are great for this.

```crystal
def get_user(id : Int32) : Term2::Cmd
  -> do
    response = HTTP::Client.get("http://api.example.com/users?id=#{id}")
    if response.success?
      user = User.from_json(response.body)
      FetchedUserMsg.new(user)
    else
      ApiErrMsg.new("Failed to fetch user")
    end
  end
end

def update(msg : Message) : {Model, Cmd}
  case msg
  when KeyMsg
    case msg.key.to_s
    when "enter"
      # Make our API request
      {self, get_user(@user_id)}
    else
      {self, nil}
    end
  when FetchedUserMsg
    # Here's our API response
    @user = msg.user
    {self, nil}
  when ApiErrMsg
    # Oh no, an API error!
    @error = msg.message
    {self, nil}
  else
    {self, nil}
  end
end
```

## Injecting messages from outside the program

Commands work great from within a Term2 program, but what if you want to send messages to `update` from outside the program? Enter `Program#send`. It's as simple as `program.send(SomeMsg.new)`:

```crystal
program = Term2::Program(MyModel).new(model)

# Later...
program.send(SomeMsg.new)
```

For details check out the [send-msg example](https://github.com/charmbracelet/bubbletea/blob/master/examples/send-msg/main.go) in Bubble Tea (the pattern is identical in Term2) and the `Program#send` method in the source code.

## Built-in command constructors

Term2 provides a `Cmds` module with helpful command constructors (defined in `src/base_types.cr`):

- `Cmds.none` - No-op command (`nil`)
- `Cmds.message(msg)` - Immediately emit a message
- `Cmds.batch(cmds)` - Run commands concurrently
- `Cmds.sequence(cmds)` - Run commands sequentially
- `Cmds.every(duration)` / `Cmds.tick(duration)` - Send a message periodically
- `Cmds.after(duration, msg)` - Send a message after a delay
- `Cmds.perform(&block)` - Execute a block and send its result as a message
- `Cmds.quit` - Quit the program
- `Cmds.println(text)` - Print text to output
- And many terminal control commands: `enter_alt_screen`, `hide_cursor`, etc.

## Timers and periodic tasks

To create a timer that ticks every second:

```crystal
class TickMsg < Message
  getter time : Time

  def initialize(@time); end
end

def init : Cmd
  Term2::Cmds.every(1.second) { |time| TickMsg.new(time) }
end

def update(msg : Message) : {Model, Cmd}
  case msg
  when TickMsg
    @last_tick = msg.time
    # Return another tick command to keep ticking
    {self, Term2::Cmds.every(1.second) { |time| TickMsg.new(time) }}
  else
    {self, nil}
  end
end
```

## Error handling in commands

Commands can raise exceptions. By default, Term2 catches these and logs them to STDERR (when `TERM2_DEBUG` is set). You can also handle errors by returning error messages from your commands:

```crystal
def risky_operation : Term2::Cmd
  -> do
    begin
      result = perform_risky_operation
      SuccessMsg.new(result)
    rescue ex
      ErrorMsg.new(ex.message)
    end
  end
end
```

## Advanced: Command mapping and transformation

You can transform command results using `Cmds.map`:

```crystal
def fetch_data : Term2::Cmd
  raw_cmd = -> { RawDataMsg.new(fetch_raw_data) }
  Term2::Cmds.map(raw_cmd) do |msg|
    case msg
    when RawDataMsg
      ProcessedDataMsg.new(process(msg.data))
    else
      msg
    end
  end
end
```

## Still have questions?

Check out these resources:

- [Term2 Tutorials](./tutorials.md)
- [Migration Guide from BubbleTea (Go)](./migration-from-go.md)
- [Building Programs with Term2](./term2_building_programs.md)
- [Term2 API documentation](https://github.com/dsisnero/term2) (run `crystal docs` locally)

## Learn More

- [Example: real time example](https://github.com/charmbracelet/bubbletea/tree/master/examples/realtime) (Go, but patterns apply)
- [Example: spinner with tick command](../examples/bubbles_spinner.cr)
- [Example: animated progress bar](../examples/bubbletea/progress-animated/main.cr)

---

*Original Bubble Tea blog post by [Bashbunni](https://github.com/bashbunni), adapted for Term2 by the Term2 maintainers.*