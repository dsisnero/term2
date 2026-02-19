{% if @top_level.constants.any? { |c| c.stringify == "Term2" } %}
{% else %}
  require "term2"
{% end %}
require "golden"

module Teatest
  VERSION = "0.1.0"

  # Program defines the subset of the Term2::Program API we need for testing.
  module Program
    abstract def send(msg : Term2::Msg)
  end

  # TestModelOptions defines all options available to the test function.
  class TestModelOptions
    property size : Term2::WindowSizeMsg
    property program_opts : Array(Term2::ProgramOption)

    def initialize
      @size = Term2::WindowSizeMsg.new(0, 0)
      @program_opts = [] of Term2::ProgramOption
    end
  end

  # TestOption is a functional option.
  alias TestOption = Proc(TestModelOptions, Nil)

  # WithInitialTermSize sets the initial terminal size.
  def self.with_initial_term_size(x : Int32, y : Int32) : TestOption
    ->(opts : TestModelOptions) {
      opts.size = Term2::WindowSizeMsg.new(x, y)
    }
  end

  # WithProgramOptions adds Term2::ProgramOption values to the test model during initialization.
  def self.with_program_options(*options : Term2::ProgramOption) : TestOption
    ->(opts : TestModelOptions) {
      opts.program_opts.concat(options)
    }
  end

  # WaitingForContext is the context for a WaitFor.
  class WaitingForContext
    property duration : Time::Span
    property check_interval : Time::Span

    def initialize
      @duration = 1.second
      @check_interval = 50.milliseconds
    end
  end

  # WaitForOption changes how a WaitFor will behave.
  alias WaitForOption = Proc(WaitingForContext, Nil)

  # WithCheckInterval sets how much time a WaitFor should sleep between every check.
  def self.with_check_interval(d : Time::Span) : WaitForOption
    ->(wf : WaitingForContext) { wf.check_interval = d }
  end

  # WithDuration sets how much time a WaitFor will wait for the condition.
  def self.with_duration(d : Time::Span) : WaitForOption
    ->(wf : WaitingForContext) { wf.duration = d }
  end

  # WaitFor keeps reading from r until the condition matches.
  # Default duration is 1s, default check interval is 50ms.
  def self.wait_for(r : IO, condition : Bytes -> Bool, options : Array(WaitForOption) = [] of WaitForOption) : Nil
    if err = do_wait_for(r, condition, options)
      raise err
    end
  end

  private def self.do_wait_for(r : IO, condition : Bytes -> Bool, options : Array(WaitForOption)) : Exception?
    wf = WaitingForContext.new
    options.each { |opt| opt.call(wf) }

    if r.is_a?(SafeReadWriter)
      start = Time.monotonic
      last = Bytes.empty
      while (Time.monotonic - start) <= wf.duration
        last = r.snapshot
        if condition.call(last)
          return nil
        end
        sleep wf.check_interval
      end
      return Exception.new("WaitFor: condition not met after #{format_duration(wf.duration)}. Last output:\n#{String.new(last)}")
    end

    buffer = IO::Memory.new
    start = Time.monotonic
    while (Time.monotonic - start) <= wf.duration
      begin
        chunk = r.gets_to_end
        buffer << chunk if chunk
      rescue ex
        return Exception.new("WaitFor: #{ex.message}", cause: ex)
      end

      if condition.call(buffer.to_slice)
        return nil
      end
      sleep wf.check_interval
    end
    Exception.new("WaitFor: condition not met after #{format_duration(wf.duration)}. Last output:\n#{buffer.to_s}")
  end

  private def self.format_duration(duration : Time::Span) : String
    if duration < 1.second
      "#{duration.total_milliseconds.to_i}ms"
    elsif duration < 1.minute
      "#{duration.total_seconds.to_i}s"
    elsif duration < 1.hour
      "#{duration.total_minutes.to_i}m"
    else
      "#{duration.total_hours.to_i}h"
    end
  end

  # FinalOpts represents the options for FinalModel and FinalOutput.
  class FinalOpts
    property timeout : Time::Span
    property on_timeout : Proc(Nil)?

    def initialize
      @timeout = 0.seconds
      @on_timeout = nil
    end
  end

  # FinalOpt changes FinalOpts.
  alias FinalOpt = Proc(FinalOpts, Nil)

  # WithTimeoutFn allows to define what happens when WaitFinished times out.
  def self.with_timeout_fn(fn : Proc(Nil)) : FinalOpt
    ->(opts : FinalOpts) { opts.on_timeout = fn }
  end

  # WithFinalTimeout allows to set a timeout for how long FinalModel and FinalOutput should wait.
  def self.with_final_timeout(d : Time::Span) : FinalOpt
    ->(opts : FinalOpts) { opts.timeout = d }
  end

  class TestModel(M)
    include Program
    getter program : Term2::Program(M)
    @in : IO::Memory
    @out : SafeReadWriter
    @model_ch : Channel(M)
    @model : M?
    @done_ch : Channel(Bool)
    @done : Bool
    @done_mutex : Mutex

    def initialize(@program : Term2::Program(M), @in : IO::Memory, @out : SafeReadWriter)
      @model_ch = Channel(M).new(1)
      @done_ch = Channel(Bool).new(1)
      @done = false
      @done_mutex = Mutex.new
      @model = nil
    end

    # WaitFinished waits for the app to finish.
    def wait_finished(opts : Array(FinalOpt) = [] of FinalOpt) : Nil
      wait_done(opts)
    end

    # FinalModel returns the resulting model from program.run.
    def final_model(opts : Array(FinalOpt) = [] of FinalOpt) : M
      wait_done(opts)
      if model = @model_ch.receive?
        @model = model
      end
      @model.not_nil!
    end

    # FinalOutput returns the program's final output io.Reader.
    def final_output(opts : Array(FinalOpt) = [] of FinalOpt) : IO
      wait_done(opts)
      output
    end

    # Output returns the program's current output io.Reader.
    def output : IO
      @out
    end

    # Send sends messages to the underlying program.
    def send(msg : Term2::Msg) : Nil
      @program.send(msg)
    end

    # Quit quits the program and releases the terminal.
    def quit : Nil
      @program.quit
    end

    # Type types the given text into the given program.
    def type(s : String) : Nil
      s.each_char do |c|
        @program.send(Term2::KeyMsg.new(Term2::Key.new(c)))
      end
    end

    protected def send_done(model : M) : Nil
      @model_ch.send(model)
      @done_ch.send(true)
    end

    private def wait_done(opts : Array(FinalOpt)) : Nil
      should_wait = false
      @done_mutex.synchronize do
        unless @done
          @done = true
          should_wait = true
        end
      end
      return unless should_wait

      fopts = FinalOpts.new
      opts.each { |opt| opt.call(fopts) }
      if fopts.timeout > 0.seconds
        select
        when timeout(fopts.timeout)
          if on_timeout = fopts.on_timeout
            on_timeout.call
          else
            raise "timeout after #{fopts.timeout}"
          end
        when @done_ch.receive
        end
      else
        @done_ch.receive
      end
    end
  end

  # NewTestModel makes a new TestModel which can be used for tests.
  def self.new_test_model(m : M, options : Array(TestOption) = [] of TestOption) : TestModel(M) forall M
    input = IO::Memory.new
    output = SafeReadWriter.new(IO::Memory.new)

    # We always have an initial size.
    options = [with_initial_term_size(80, 24)] + options

    opts = TestModelOptions.new
    options.each { |opt| opt.call(opts) }

    program_opts = opts.program_opts + [
      Term2::WithInput.new(input),
      Term2::WithOutput.new(output),
      Term2::WithoutSignalHandler.new,
    ]

    program_options = Term2::ProgramOptions.new
    program_opts.each { |opt| program_options.add(opt) }
    program = Term2::Program(M).new(m, input, output, program_options)
    tm = TestModel(M).new(program, input, output)

    Signal::INT.trap do
      tm.program.kill
    end

    spawn do
      model = program.run
      tm.send_done(model)
    end

    if opts.size.width != 0
      program.send(opts.size)
    end

    tm
  end

  # RequireEqualOutput asserts the given output matches golden files.
  def self.require_equal_output(test_name : String, output : Bytes) : Nil
    test_data_dir = Golden.spec_test_data_dir || "spec/testdata"
    Golden.require_equal(test_name, output, test_data_dir)
  end

  class SafeReadWriter < IO
    @rw : IO::Memory
    @lock : Mutex
    @read_pos : Int32 = 0

    def initialize(@rw : IO::Memory)
      @lock = Mutex.new
    end

    def read(slice : Bytes) : Int32
      @lock.synchronize do
        data = @rw.to_slice
        remaining = data.size - @read_pos
        return 0 if remaining <= 0
        n = Math.min(slice.size, remaining)
        slice.copy_from(data[@read_pos, n])
        @read_pos += n
        n
      end
    end

    def snapshot : Bytes
      @lock.synchronize { @rw.to_slice.dup }
    end

    def write(slice : Bytes) : Nil
      @lock.synchronize { @rw.write(slice) }
    end

    def flush : Nil
      @lock.synchronize { @rw.flush }
    end

    def close : Nil
      @lock.synchronize { @rw.close }
    end

    def closed? : Bool
      @rw.closed?
    end
  end
end
