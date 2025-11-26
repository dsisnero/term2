require "../term2"

module Term2
  module Bubbles
    class Stopwatch < Model
      property? running : Bool = false
      property start_time : Time = Time.local
      property elapsed : Time::Span = Time::Span.zero
      property interval : Time::Span = 1.second

      def initialize
      end

      class StartMsg < Message
      end

      class StopMsg < Message
      end

      class ResetMsg < Message
      end

      class TickMsg < Message
      end

      def update(msg : Message) : {Stopwatch, Cmd}
        case msg
        when StartMsg
          if !@running
            @start_time = Time.local - @elapsed
            @running = true
            return {self, tick_cmd}
          end
        when StopMsg
          if @running
            @elapsed = Time.local - @start_time
            @running = false
          end
        when ResetMsg
          @elapsed = Time::Span.zero
          @start_time = Time.local
          @running = false
        when TickMsg
          if @running
            @elapsed = Time.local - @start_time
            return {self, tick_cmd}
          end
        end
        {self, Cmd.none}
      end

      def tick_cmd : Cmd
        Cmd.tick(@interval) do |_|
          TickMsg.new
        end
      end

      def start : Cmd
        Cmd.message(StartMsg.new)
      end

      def stop : Cmd
        Cmd.message(StopMsg.new)
      end

      def reset : Cmd
        Cmd.message(ResetMsg.new)
      end

      def view : String
        @elapsed.to_s
      end
    end
  end
end
