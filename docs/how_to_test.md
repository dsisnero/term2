# Writing Term2 Tests with Teatest

> Ported from [Writing Bubble Tea Tests](https://carlosbecker.com/posts/teatest/) by Carlos Alexandro Becker, adapted for Term2 and lib/teatest.

Learn how to use `lib/teatest` to write tests for your Term2 apps.

You can assert the entire output of your program, parts of it, and/or its internal `Term2::Model` state.

In this guide we'll add tests to an example app using the current `teatest` API.

## The app

Our example app is a simple countdown timer that shows how much time is left. It's similar to the `timer` example in the Bubble Tea examples, but simplified for demonstration.

Without further ado, let's create the app.

First, create a new Crystal project or add to an existing one. We'll assume you have a `shard.yml` with `term2` and `teatest` dependencies:

```yaml
dependencies:
  term2:
    github: dsisnero/term2
  teatest:
    github: dsisnero/term2
    path: lib/teatest
```

This example will count down from a specified duration until the user presses `q` to exit.

With a few modifications we can get what we want:

- Add a `duration : Time::Span` field to the model to track how long we should count down.
- Add a `start : Time` field to mark when we started the countdown.
- The model needs to take the `duration` as an argument, set it into the model, and set `start` to `Time.now`.
- Add a `time_left` method that calculates how much time remains.
- In the `update` method, check if `time_left > 0`, and quit otherwise.
- In the `view` method, display how much time is left.
- Finally, parse command-line arguments to a `Time::Span` and pass it to the model.

Here's the complete implementation:

```crystal
require "term2"

class TickMsg < Term2::Message
end

class CountdownModel
  include Term2::Model
  getter duration : Time::Span
  getter start : Time

  def initialize(@duration : Time::Span)
    @start = Time.utc
  end

  def init : Term2::Cmd
    # Schedule the first tick after 1 second
    Term2::Cmds.tick(1.second) { TickMsg.new }
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      if msg.key.text == "q"
        {self, Term2.quit}
      else
        {self, nil}
      end
    when TickMsg
      if time_left <= Time::Span.zero
        {self, Term2.quit}
      else
        # Schedule another tick
        {self, Term2::Cmds.tick(1.second) { TickMsg.new }}
      end
    else
      {self, nil}
    end
  end

  def view : Term2::View
    remaining = time_left
    if remaining > Time::Span.zero
      Term2.new_view("⣻  sleeping #{remaining.total_seconds.to_i}s... press q to quit")
    else
      Term2.new_view("Time's up!")
    end
  end

  def time_left : Time::Span
    elapsed = Time.utc - @start
    remaining = @duration - elapsed
    remaining > Time::Span.zero ? remaining : Time::Span.zero
  end
end

if PROGRAM_NAME == __FILE__
  if ARGV.empty?
    puts "Usage: #{PROGRAM_NAME} <duration>"
    puts "Example: #{PROGRAM_NAME} 5s"
    exit 1
  end

  duration = Time::Span.parse(ARGV[0])
  model = CountdownModel.new(duration)
  program = Term2::Program(CountdownModel).new(model)
  program.run
end
```

## Setting up teatest

Before writing tests, ensure you have `teatest` installed as a development dependency:

```yaml
development_dependencies:
  teatest:
    github: dsisnero/term2
    path: lib/teatest
```

Then, in your test file, require the necessary modules:

```crystal
require "spec"
require "teatest"
```

## The full output test

Let's create a `countdown_spec.cr` and start with a simple test that asserts the entire final output of the app.

Here's what it looks like:

```crystal
require "spec"
require "teatest"
require "./countdown"

describe CountdownModel do
  it "full output matches golden file" do
    model = CountdownModel.new(1.second)
    tm = Teatest.new_test_model(
      model,
      [Teatest.with_initial_term_size(80, 24)]
    )

    output = tm.final_output([Teatest.with_final_timeout(2.seconds)])
    output_bytes = read_bytes(output)

    Teatest.require_equal_output("CountdownFullOutput", output_bytes)
  end
end

private def read_bytes(io : IO) : Bytes
  buffer = IO::Memory.new
  buffer.write(io.gets_to_end.to_slice)
  buffer.to_slice
end
```

1. We created a `model` that will count down for 1 second.
2. We passed it to `Teatest.new_test_model`, ensuring a fixed terminal size.
3. We ask for the `final_output`, which waits for the `Term2::Program` to finish before returning.
4. We check if the output we got is equal to the output in the *golden file*.

If you just run `crystal spec`, you'll see that it errors. That's because we don't have a golden file yet. To fix that, run:

```bash
GOLDEN_UPDATE=1 crystal spec
```

The `GOLDEN_UPDATE` environment variable comes from the `golden` library that `teatest` uses. It will update the golden file (or create it if it doesn't exist).

You can also `cat` the golden file to see what it looks like:

```bash
cat spec/testdata/CountdownFullOutput.golden
```

Which should show something like:

```
⣻  sleeping 1s... press q to quit
```

In subsequent tests, you'll want to run `crystal spec` without `GOLDEN_UPDATE`, unless you changed the output portion of your program.

## The final model test

Term2 returns the final model after it finishes running, so we can also assert against that final model:

```crystal
it "final model has correct state" do
  tm = Teatest.new_test_model(
    CountdownModel.new(1.second),
    [Teatest.with_initial_term_size(80, 24)]
  )

  fm = tm.final_model([Teatest.with_final_timeout(2.seconds)])
  fm.should be_a(CountdownModel)
  fm.duration.should eq 1.second
  fm.start.should be <= Time.now - 1.second
end
```

The setup is basically the same as the previous test, but instead of asking for the `final_output`, we ask for the `final_model`.

We then assert the model's `duration` and `start` time.

## Intermediate output and sending messages

Another useful test case is to ensure things happen during the test. We also need to interact with the program while it's running.

Let's write a quick test exploring these options:

```crystal
it "shows intermediate output and responds to key presses" do
  tm = Teatest.new_test_model(
    CountdownModel.new(10.seconds),
    [Teatest.with_initial_term_size(80, 24)]
  )

  Teatest.wait_for(
    tm.output,
    ->(buffer : Bytes) { buffer.includes?("sleeping 8s".to_slice) },
    [
      Teatest.with_duration(3.seconds),
      Teatest.with_check_interval(100.milliseconds),
    ]
  )

  tm.type("q")

  tm.wait_finished([Teatest.with_final_timeout(1.second)])
end
```

We set up our `teatest` in the same fashion as the previous test, then we assert that the app, at some point, is showing `sleeping 8s`, meaning 2 seconds have elapsed. We give that condition 3 seconds of time to be met, or else we fail.

Finally, we send a `q` key press using `tm.type`, which should cause the app to quit.

To ensure it quits in time, we `wait_finished` with a timeout of 1 second. This way we can be sure we finished because we sent a `q` key press, not because the program ran its 10 seconds out.

## The CI is failing. What now?

Once you push your commits, CI will test them and might fail.

The reason for this is because your local golden file was generated with whatever color profile the terminal `crystal spec` was run in reported, while CI is probably reporting something different.

Luckily, we can force everything to use the same color profile. In your test setup, you can set the color profile:

```crystal
before_each do
  Lipgloss::StyleRenderer.default = Lipgloss::StyleRenderer.new.tap do |r|
    r.color_profile = Lipgloss::ColorProfile::ANSI256
  end
end
```

Alternatively, you can set the `TERM2_COLOR_PROFILE` environment variable:

```bash
TERM2_COLOR_PROFILE=ansi256 crystal spec
```

Another thing that might cause tests to fail is line endings. The golden files look like text, but their line endings shouldn't be messed with—and git might just do that.

To remedy the situation, add this to your `.gitattributes` file:

```
*.golden -text
```

This will keep Git from handling them as text files.

## Using golden files effectively

The `golden` library provides more advanced features for managing golden files:

- **Directory organization**: Golden files are stored in `spec/testdata/` by default.
- **Update mode**: Set `GOLDEN_UPDATE=1` to update golden files.
- **Custom directories**: Use `Golden.dir = "custom/path"` to change the location.
- **Binary comparisons**: Golden files can contain binary data, not just text.

## Final words

The `teatest` library is a powerful tool for testing Term2 applications. It allows you to test output, model state, and simulate user interactions.

We encourage you to try it out in your projects and report back what you find.

For more examples, check out the `spec/` directory in the Term2 repository, particularly the `teatest` specs and example specs.

## Further reading

- [Term2 Building Programs Guide](./term2_building_programs.md)
- [Golden Library Documentation](https://github.com/dsisnero/term2/tree/main/lib/golden)
- [Original Bubble Tea teatest Blog Post](https://charm.sh/blog/teatest/)

---

*This guide was adapted from the original [Writing Bubble Tea Tests](https://carlosbecker.com/posts/teatest/) by Carlos Alexandro Becker, ported to Term2 and Crystal.*