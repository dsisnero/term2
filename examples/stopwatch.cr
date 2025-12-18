# Stopwatch Example - Ported from bubbletea/examples/stopwatch
#
# A simple stopwatch application demonstrating:
# - Time tracking with millisecond precision
# - Start/stop/reset controls
# - Help display
#
# Run with: crystal run examples/stopwatch.cr

require "../src/term2"

module StopwatchExample
  include Term2::Prelude

  # Stopwatch component that counts elapsed time
  class Stopwatch
    include Model

    property elapsed : Time::Span = Time::Span.zero
    property interval : Time::Span
    property? running : Bool = false

    getter id : Int32
    @tag : Int32 = 0

    def initialize(@interval : Time::Span = 100.milliseconds)
      @id = Random.rand(Int32)
    end

    class TickMsg < Message
      getter id : Int32
      getter tag : Int32

      def initialize(@id, @tag)
      end
    end

    def init : Cmd
      Cmds.none
    end

    def update(msg : Term2::Message) : {Stopwatch, Cmd}
      case msg
      when TickMsg
        if msg.id == @id && msg.tag == @tag && @running
          @elapsed += @interval
          return {self, tick_cmd}
        end
      end
      {self, Cmds.none}
    end

    def tick_cmd : Cmd
      id = @id
      tag = @tag
      Cmds.tick(@interval) do
        TickMsg.new(id, tag)
      end
    end

    def start : Cmd
      return Cmds.none if @running
      @running = true
      @tag += 1
      tick_cmd
    end

    def stop : Cmd
      @running = false
      Cmds.none
    end

    def toggle : Cmd
      @running ? stop : start
    end

    def reset : Cmd
      was_running = @running
      @running = false
      @elapsed = Time::Span.zero
      @tag += 1
      was_running ? Cmds.none : Cmds.none
    end

    def view : String
      format_duration(@elapsed)
    end

    private def format_duration(span : Time::Span) : String
      total_seconds = span.total_seconds
      hours = (total_seconds / 3600).to_i
      minutes = ((total_seconds % 3600) / 60).to_i
      seconds = (total_seconds % 60).to_i
      millis = span.milliseconds

      if hours > 0
        "%d:%02d:%02d.%03d" % [hours, minutes, seconds, millis]
      elsif minutes > 0
        "%d:%02d.%03d" % [minutes, seconds, millis]
      else
        "%d.%03d" % [seconds, millis]
      end
    end
  end

  # Key bindings configuration
  struct KeyMap
    getter start : Term2::Components::Key::Binding
    getter stop : Term2::Components::Key::Binding
    getter reset : Term2::Components::Key::Binding
    getter quit : Term2::Components::Key::Binding

    def initialize
      @start = Term2::Components::Key::Binding.new(["s"], "s", "start")
      @stop = Term2::Components::Key::Binding.new(["s"], "s", "stop")
      @reset = Term2::Components::Key::Binding.new(["r"], "r", "reset")
      @quit = Term2::Components::Key::Binding.new(["q", "ctrl+c"], "q", "quit")
    end
  end

  # Main application model
  class App
    include Model

    property stopwatch : Stopwatch
    property keymap : KeyMap
    property? quitting : Bool = false

    def initialize
      @stopwatch = Stopwatch.new(100.milliseconds)
      @keymap = KeyMap.new
    end

    def init : Cmd
      @stopwatch.init
    end

    def update(msg : Term2::Message) : {Model, Cmd}
      case msg
      when KeyMsg
        key_str = msg.key.to_s
        case
        when @keymap.quit.matches?(msg)
          @quitting = true
          return {self, Term2.quit}
        when @keymap.reset.matches?(msg)
          cmd = @stopwatch.reset
          return {self, cmd}
        when key_str == "s"
          cmd = @stopwatch.toggle
          return {self, cmd}
        end
      when Stopwatch::TickMsg
        @stopwatch, cmd = @stopwatch.update(msg)
        return {self, cmd}
      end
      {self, Cmds.none}
    end

    def view : String
      return "" if @quitting

      s = String.build do |io|
        io << "Elapsed: " << @stopwatch.view << "\n"
        io << "\n"
        io << help_view
      end
      s
    end

    private def help_view : String
      if @stopwatch.running?
        "s stop • r reset • q quit"
      else
        "s start • r reset • q quit"
      end
    end
  end

  def self.run
    app = App.new
    Term2.run(app)
  end
end

StopwatchExample.run
