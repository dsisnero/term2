require "../../../src/term2"

include Term2::Prelude

TIMEOUT = (ENV["TERM2_TIMER_TIMEOUT"]? ? ENV["TERM2_TIMER_TIMEOUT"].try &.to_i : 5).seconds

class TimerKeymap
  getter start : TC::Key::Binding
  getter stop : TC::Key::Binding
  getter reset : TC::Key::Binding
  getter quit : TC::Key::Binding

  def initialize
    @start = TC::Key::Binding.new(TC::Key.with_keys("s"), TC::Key.with_help("s", "start"))
    @stop = TC::Key::Binding.new(TC::Key.with_keys("s"), TC::Key.with_help("s", "stop"))
    @reset = TC::Key::Binding.new(TC::Key.with_keys("r"), TC::Key.with_help("r", "reset"))
    @quit = TC::Key::Binding.new(TC::Key.with_keys("q", "ctrl+c"), TC::Key.with_help("q", "quit"))
  end
end

class TimerModel
  include Term2::Model
  include TC::Help::KeyMap

  getter timer : TC::Timer
  getter keymap : TimerKeymap
  getter help : TC::Help
  getter? quitting : Bool

  def initialize(timeout : Time::Span = TIMEOUT)
    @timer = TC::Timer.new(timeout)
    @timer.interval = 1.millisecond
    @keymap = TimerKeymap.new
    @help = TC::Help.new
    @quitting = false
    @keymap.start.disabled = true
  end

  def init : Term2::Cmd
    @timer.init
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when TC::Timer::TickMsg
      @timer, cmd = @timer.update(msg)
      return {self, cmd}
    when TC::Timer::StartStopMsg
      @timer, cmd = @timer.update(msg)
      @keymap.stop.enabled = @timer.running?
      @keymap.start.enabled = !@timer.running?
      return {self, cmd}
    when TC::Timer::TimeoutMsg
      @quitting = true
      return {self, Term2::Cmds.quit}
    when Term2::KeyMsg
      case
      when @keymap.quit.matches?(msg)
        @quitting = true
        return {self, Term2::Cmds.quit}
      when @keymap.reset.matches?(msg)
        @timer.timeout = TIMEOUT
      when @keymap.start.matches?(msg) || @keymap.stop.matches?(msg)
        return {self, @timer.toggle}
      end
    end
    {self, nil}
  end

  def help_view : String
    "\n" + @help.view_short(self)
  end

  def short_help : Array(TC::Key::Binding)
    [@keymap.start, @keymap.stop, @keymap.reset, @keymap.quit]
  end

  def full_help : Array(Array(TC::Key::Binding))
    [
      [@keymap.start, @keymap.stop, @keymap.reset, @keymap.quit],
    ]
  end

  def view : String
    s = @timer.view
    if @timer.timed_out?
      s = "All done!"
    end
    s += "\n"
    unless @quitting
      s = "Exiting in " + s
      s += help_view
    end
    s
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(TimerModel.new)
end
