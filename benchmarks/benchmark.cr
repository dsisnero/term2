# Performance Benchmarks for Term2
#
# Run with: crystal run --release benchmarks/benchmark.cr
#
# These benchmarks measure key performance metrics:
# - Key sequence parsing throughput
# - Mouse event parsing throughput
# - Renderer performance
# - View layout calculations

require "../src/term2"
require "benchmark"

module Term2Benchmarks
  # Number of iterations for benchmarks
  ITERATIONS = 100_000

  def self.run_all
    puts "=" * 60
    puts "Term2 Performance Benchmarks"
    puts "=" * 60
    puts

    benchmark_key_sequence_parsing
    benchmark_mouse_parsing
    benchmark_view_layout
    benchmark_key_creation
    benchmark_renderer_output

    puts "=" * 60
    puts "Benchmarks complete"
    puts "=" * 60
  end

  def self.benchmark_key_sequence_parsing
    puts "Key Sequence Parsing"
    puts "-" * 40

    sequences = [
      "\e[A",        # Up arrow
      "\e[1;5A",     # Ctrl+Up
      "\e[15~",      # F5
      "\eOP",        # F1
      "\e[I",        # Focus In
      "\e[1;2;3;4m", # Unknown sequence
    ]

    Benchmark.ips do |x|
      x.report("KeySequences.find (simple)") do
        Term2::KeySequences.find("\e[A")
      end

      x.report("KeySequences.find (modifier)") do
        Term2::KeySequences.find("\e[1;5A")
      end

      x.report("KeySequences.prefix? check") do
        Term2::KeySequences.prefix?("\e[1")
      end

      x.report("KeySequences batch lookup") do
        sequences.each { |seq| Term2::KeySequences.find(seq) }
      end
    end

    puts
  end

  def self.benchmark_mouse_parsing
    puts "Mouse Event Parsing"
    puts "-" * 40

    reader = Term2::MouseReader.new
    sgr_events = [
      "\e[<0;10;20M",  # Left click
      "\e[<0;10;20m",  # Left release
      "\e[<64;10;20M", # Wheel up
      "\e[<32;10;20M", # Motion
    ]

    Benchmark.ips do |x|
      x.report("SGR mouse parse") do
        reader.check_mouse_event("\e[<0;10;20M")
      end

      x.report("SGR mouse batch") do
        sgr_events.each { |event| reader.check_mouse_event(event) }
      end
    end

    puts
  end

  def self.benchmark_view_layout
    puts "View Layout Calculations"
    puts "-" * 40

    screen = Term2::View.new(0, 0, 80, 24)

    Benchmark.ips do |x|
      x.report("View.new") do
        Term2::View.new(0, 0, 80, 24)
      end

      x.report("View.margin") do
        screen.margin(top: 1, bottom: 1, left: 2, right: 2)
      end

      x.report("View.split_horizontal") do
        screen.split_horizontal(0.5)
      end

      x.report("View.split_vertical") do
        screen.split_vertical(0.5)
      end

      x.report("View.center") do
        screen.center(40, 12)
      end

      x.report("View.contains?") do
        screen.contains?(40, 12)
      end

      x.report("Layout.grid (4x4)") do
        Term2::Layout.grid(screen, 4, 4)
      end

      x.report("Complex layout") do
        content = screen.margin(top: 1, bottom: 2, left: 2, right: 2)
        _, body = content.split_vertical(0.1)
        sidebar, main = body.split_horizontal(0.3)
        sidebar.padding(1)
        main.padding(1)
      end
    end

    puts
  end

  def self.benchmark_key_creation
    puts "Key Object Creation"
    puts "-" * 40

    Benchmark.ips do |x|
      x.report("Key.new(KeyType)") do
        Term2::Key.new(Term2::KeyType::Up)
      end

      x.report("Key.new(Char)") do
        Term2::Key.new('a')
      end

      x.report("Key.new(String)") do
        Term2::Key.new("hello")
      end

      x.report("Key#to_s") do
        Term2::Key.new(Term2::KeyType::CtrlC).to_s
      end

      x.report("Key#matches?") do
        Term2::Key.new(Term2::KeyType::CtrlC).matches?("ctrl+c")
      end
    end

    puts
  end

  def self.benchmark_renderer_output
    puts "Renderer Output"
    puts "-" * 40

    output = IO::Memory.new
    renderer = Term2::StandardRenderer.new(output)

    # Generate some test content
    simple_view = "Hello, World!"
    complex_view = String.build do |io|
      24.times do |row|
        io << "Line #{row + 1}: " << "=" * 60 << "\n"
      end
    end

    Benchmark.ips do |x|
      x.report("Simple render") do
        output.clear
        renderer.render(simple_view)
      end

      x.report("Complex render (24 lines)") do
        output.clear
        renderer.render(complex_view)
      end

      x.report("Render + flush cycle") do
        output.clear
        renderer.render(simple_view)
        renderer.flush
      end
    end

    puts
  end
end

Term2Benchmarks.run_all
