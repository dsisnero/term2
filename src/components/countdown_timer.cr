require "../term2"

module Term2
  module Components
    class CountdownTimer < Term2::Model
      getter duration : Time::Span
      getter remaining : Time::Span
      getter? running : Bool
      getter last_tick : Time?
      getter interval : Time::Span

      class Start < Term2::Message
        getter duration : Time::Span
        def initialize(@duration : Time::Span); end
      end

      class Tick < Term2::Message
        getter time : Time
        def initialize(@time : Time); end
      end

      class Finished < Term2::Message
        getter finished_at : Time
        def initialize(@finished_at : Time); end
      end

      def initialize(@duration : Time::Span, @remaining : Time::Span, @running : Bool, @last_tick : Time?, @interval : Time::Span = 100.milliseconds)
      end

      def self.new(duration : Time::Span, interval : Time::Span = 100.milliseconds)
        new(duration, duration, true, Time.utc, interval)
      end

      def init : Cmd
        schedule_tick
      end

      def update(msg : Message) : {Model, Cmd}
        case msg
        when Start
          restart(msg.duration)
        when Tick
          advance(msg.time)
        else
          {self, Cmd.none}
        end
      end

      def view : String
        remaining_seconds = (@remaining.total_milliseconds / 1000.0).clamp(0.0, @duration.total_milliseconds / 1000.0)
        status = @running ? "running" : "finished"
        "Timer: #{remaining_seconds.round(2)}s (#{status})"
      end

      private def restart(duration : Time::Span) : {Model, Cmd}
        now = Time.utc
        new_timer = CountdownTimer.new(duration, duration, true, now, @interval)
        {new_timer, new_timer.schedule_tick}
      end

      private def advance(tick_at : Time) : {Model, Cmd}
        return {self, Cmd.none} unless @running
        
        last_tick = @last_tick || tick_at
        elapsed = tick_at - last_tick
        remaining = @remaining - elapsed

        if remaining <= Time::Span.zero
          finished_timer = CountdownTimer.new(@duration, Time::Span.zero, false, tick_at, @interval)
          {finished_timer, Cmd.message(Finished.new(tick_at))}
        else
          updated_timer = CountdownTimer.new(@duration, remaining, true, tick_at, @interval)
          {updated_timer, updated_timer.schedule_tick}
        end
      end

      def schedule_tick : Cmd
        Cmd.tick(@interval) { |time| Tick.new(time) }
      end
    end
  end
end
