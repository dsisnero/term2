require "../term2"

module Term2
  module Components
    class Timer < Model
      property timeout : Time::Span
      property interval : Time::Span = 1.second
      property? running : Bool = false
      property? timed_out : Bool = false

      getter id : Int32
      @tag : Int32 = 0

      def initialize(@timeout : Time::Span, @interval : Time::Span = 1.second)
        @id = Random.rand(Int32)
        @running = true
      end

      class TickMsg < Message
        getter id : Int32
        getter tag : Int32
        getter? timeout : Bool

        def initialize(@id, @tag, @timeout)
        end
      end

      class TimeoutMsg < Message
        getter id : Int32

        def initialize(@id)
        end
      end

      class StartStopMsg < Message
        getter id : Int32
        getter? running : Bool

        def initialize(@id, @running)
        end
      end

      def init : {Timer, Cmd}
        {self, tick_cmd}
      end

      def update(msg : Message) : {Timer, Cmd}
        case msg
        when StartStopMsg
          if msg.id == @id
            @running = msg.running?
            @tag += 1 if @running # Invalidate old ticks
            return {self, @running ? tick_cmd : Cmd.none}
          end
        when TickMsg
          if msg.id == @id && msg.tag == @tag && @running
            @timeout -= @interval
            if @timeout <= Time::Span.zero
              @timed_out = true
              @running = false
              return {self, Cmd.message(TimeoutMsg.new(@id))}
            end
            return {self, tick_cmd}
          end
        end
        {self, Cmd.none}
      end

      def tick_cmd : Cmd
        id = @id
        tag = @tag
        Cmd.tick(@interval) do
          TickMsg.new(id, tag, false)
        end
      end

      def start : Cmd
        Cmd.message(StartStopMsg.new(@id, true))
      end

      def stop : Cmd
        Cmd.message(StartStopMsg.new(@id, false))
      end

      def toggle : Cmd
        Cmd.message(StartStopMsg.new(@id, !@running))
      end

      def view : String
        @timeout.to_s
      end
    end
  end
end
