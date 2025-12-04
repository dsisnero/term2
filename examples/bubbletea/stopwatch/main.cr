require "../../../src/term2"

include Term2::Prelude

class StopwatchKeymap
  TC::Key.key_bindings(
    start: {["s"], "s", "start"},
    stop:  {["s"], "s", "stop"},
    reset: {["r"], "r", "reset"},
    quit:  {["ctrl+c", "q"], "q", "quit"},
  )
end

class StopwatchModel
  include Term2::Model
  include TC::Help::KeyMap

  getter stopwatch : TC::Stopwatch
  getter keymap : StopwatchKeymap
  getter help : TC::Help
  getter? quitting : Bool

  def initialize
    @stopwatch = TC::Stopwatch.new
    @stopwatch.interval = 1.millisecond
    @keymap = StopwatchKeymap.new
    @help = TC::Help.new
    @quitting = false
    @keymap.start.disabled = true
  end

  def init : Term2::Cmd
    @stopwatch.init
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case
      when @keymap.quit.matches?(msg)
        @quitting = true
        return {self, Term2::Cmds.quit}
      when @keymap.reset.matches?(msg)
        return {self, @stopwatch.reset}
      when @keymap.start.matches?(msg) || @keymap.stop.matches?(msg)
        @keymap.stop.enabled = !@stopwatch.running?
        @keymap.start.enabled = @stopwatch.running?
        cmd = @stopwatch.running? ? @stopwatch.stop : @stopwatch.start
        return {self, cmd}
      end
    end

    @stopwatch, cmd = @stopwatch.update(msg)
    {self, cmd}
  end

  def short_help : Array(TC::Key::Binding)
    [@keymap.start, @keymap.stop, @keymap.reset, @keymap.quit]
  end

  def full_help : Array(Array(TC::Key::Binding))
    [short_help]
  end

  def help_view : String
    "\n" + @help.view_short(self)
  end

  def view : String
    s = @stopwatch.view + "\n"
    unless @quitting
      s = "Elapsed: " + s
      s += help_view
    end
    s
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(StopwatchModel.new)
end
