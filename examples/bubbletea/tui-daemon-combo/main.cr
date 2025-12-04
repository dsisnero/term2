require "../../../src/term2"
require "option_parser"
require "log"

include Term2::Prelude

class ProcessFinishedMsg < Term2::Message
  getter duration : Time::Span
  def initialize(@duration : Time::Span); end
end

def run_pretend_process : Term2::Cmd
  Proc(Term2::Msg).new do
    pause = Random.rand(100..999).milliseconds
    sleep pause
    ProcessFinishedMsg.new(pause)
  end
end

def random_emoji : String
  emojis = "🍦🧋🍡🤠👾😭🦊🐯🦆🥨🎏🍔🍒🍥🎮📦🦁🐶🐸🍕🥐🧲🚒🥇🏆🌽"
  emojis.chars.sample.to_s
end

class TuiDaemonModel
  include Term2::Model

  HELP_STYLE = Term2::Style.new.foreground(Term2::Color.indexed(241))
  MAIN_STYLE = Term2::Style.new.margin_left(1)

  getter spinner : TC::Spinner
  getter results : Array({String, Time::Span})
  getter? quitting : Bool

  def initialize
    @spinner = TC::Spinner.new
    @spinner.style = Term2::Style.new.foreground(Term2::Color.indexed(206))
    @results = Array.new(5, {"", 0.seconds})
    @quitting = false
  end

  def init : Term2::Cmd
    Log.info { "Starting work..." }
    Term2::Cmds.batch(@spinner.tick, run_pretend_process)
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      @quitting = true
      return {self, Term2::Cmds.quit}
    when TC::Spinner::TickMsg
      @spinner, cmd = @spinner.update(msg)
      return {self, cmd}
    when ProcessFinishedMsg
      res = {random_emoji, msg.duration}
      Log.info { "#{res[0]} Job finished in #{res[1]}" }
      @results.shift
      @results << res
      return {self, run_pretend_process}
    end
    {self, nil}
  end

  def view : String
    s = "\n" + @spinner.view + " Doing some work...\n\n"
    @results.each do |res|
      if res[1] == Time::Span.zero
        s += "........................\n"
      else
        s += "#{res[0]} Job finished in #{res[1]}\n"
      end
    end
    s += HELP_STYLE.render("\nPress any key to exit\n")
    s += "\n" if @quitting
    MAIN_STYLE.render(s)
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  daemon_mode = false
  show_help = false

  OptionParser.parse do |parser|
    parser.on("-d", "--daemon", "run as a daemon") { daemon_mode = true }
    parser.on("-h", "--help", "show help") { show_help = true }
  end

  if show_help
    puts "Usage: tui-daemon-combo [-d|--daemon]"
    exit 0
  end

  options = Term2::ProgramOptions.new

  if daemon_mode || !STDOUT.tty?
    # Match Bubble Tea behavior: run without a renderer when detached.
    options.add(Term2::WithoutRenderer.new)
  else
    # Discard log output when rendering the TUI.
    Log.setup(:info, Log::IOBackend.new(IO::Memory.new))
  end

  Term2.run(TuiDaemonModel.new, options: options)
end
