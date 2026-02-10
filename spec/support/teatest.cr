require "../../src/term2"

module Term2
  module Teatest
    # Simple waiting context for output assertions
    struct WaitingForContext
      property duration : Time::Span = 1.second
      property check_interval : Time::Span = 50.milliseconds
    end

    alias WaitForOption = Proc(WaitingForContext, Nil)

    def self.with_check_interval(duration : Time::Span) : WaitForOption
      ->(wf : WaitingForContext) { wf.check_interval = duration }
    end

    def self.with_duration(duration : Time::Span) : WaitForOption
      ->(wf : WaitingForContext) { wf.duration = duration }
    end

    # Wait for the given condition to be true for the IO contents.
    def self.wait_for(io : IO, *options : WaitForOption, &condition : String -> Bool) : Nil
      ctx = WaitingForContext.new
      options.each(&.call(ctx))

      start = Time.instant
      last = ""
      while Time.instant - start <= ctx.duration
        last = io.to_s
        return if condition.call(last)
        sleep ctx.check_interval
      end
      raise "condition not met after #{ctx.duration}, last output:\n#{last}"
    end

    # Final wait options for model/output retrieval
    struct FinalOpts
      property timeout : Time::Span = 0.seconds
      property on_timeout : Proc(Nil)?
    end

    alias FinalOpt = Proc(FinalOpts, Nil)

    def self.with_final_timeout(duration : Time::Span) : FinalOpt
      ->(opts : FinalOpts) { opts.timeout = duration }
    end

    def self.with_timeout_fn(&block : ->) : FinalOpt
      ->(opts : FinalOpts) { opts.on_timeout = block }
    end

    # Options for constructing a test model
    struct TestModelOptions
      property size : Term2::WindowSizeMsg? = nil
      property program_opts : Array(ProgramOption) = [] of ProgramOption
    end

    alias TestOption = Proc(TestModelOptions, Nil)

    def self.with_initial_term_size(width : Int32, height : Int32) : TestOption
      ->(opts : TestModelOptions) { opts.size = Term2::WindowSizeMsg.new(width, height) }
    end

    def self.with_program_options(*options : ProgramOption) : TestOption
      ->(opts : TestModelOptions) { opts.program_opts.concat(options) }
    end

    # A harness for driving Term2 programs in specs (similar to charm-x teatest).
    class TestModel(M)
      getter program : Term2::Program(M)
      getter output : IO::Memory
      getter input : IO::Memory

      @model_channel : Channel(M)
      @done : Channel(Nil)
      @model : M

      def initialize(@model : M, *options : TestOption)
        @input = IO::Memory.new
        @output = IO::Memory.new
        opts = TestModelOptions.new
        default_opts = [Term2::Teatest.with_initial_term_size(80, 24)]
        (default_opts + options.to_a).each(&.call(opts))

        program_opts = [] of ProgramOption
        program_opts << Term2::WithoutSignalHandler.new
        program_opts.concat(opts.program_opts)
        if size_msg = opts.size
          program_opts << Term2::WithWindowSize.new(size_msg.width, size_msg.height)
        end

        program_options = Term2::ProgramOptions.new
        program_opts.each { |opt| program_options.add(opt) }

        @program = Term2::Program(M).new(@model, input: @input, output: @output, options: program_options)

        @model_channel = Channel(M).new(1)
        @done = Channel(Nil).new(1)

        spawn do
          result = @program.run
          @model_channel.send(result)
          @done.send(nil)
        end

        if size_msg = opts.size
          @program.send(size_msg)
        end
      end

      # Send a message directly to the program.
      def send(msg : Term2::Msg) : Nil
        @program.send(msg)
      end

      # Type raw text into the program as KeyMsg runes.
      def type(str : String) : Nil
        str.each_char do |char|
          send(Term2::TestHelpers.uv_key(char))
        end
      end

      # Quit the program.
      def quit : Nil
        @program.quit
      end

      # Wait for the program to finish.
      def wait_finished(*opts : FinalOpt) : Nil
        options = FinalOpts.new
        opts.each(&.call(options))

        if options.timeout > Time::Span.zero
          select
          when @done.receive
          when timeout(options.timeout)
            options.on_timeout.try &.call
            @program.stop
            return
          end
        else
          @done.receive
        end
      end

      def wait_finished : Nil
        wait_finished(default_final_opts)
      end

      private def default_final_opts : FinalOpt
        ->(_opts : FinalOpts) { }
      end

      # Return final model (waits for completion).
      def final_model(*opts : FinalOpt) : M
        wait_finished(*opts)
        select
        when val = @model_channel.receive
          @model = val
        when timeout(0.seconds)
        end
        @model
      end

      def final_model : M
        wait_finished
        select
        when val = @model_channel.receive
          @model = val
        when timeout(0.seconds)
        end
        @model
      end

      # Return final output as a string (waits for completion).
      def final_output(*opts : FinalOpt) : String
        wait_finished(*opts)
        @output.to_s
      end

      # Convenience overload with no options.
      def final_output : String
        wait_finished
        @output.to_s
      end

      # Access live output reader.
      def output_reader : IO
        @output
      end
    end
  end
end
