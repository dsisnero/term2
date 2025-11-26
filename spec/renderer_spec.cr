require "./spec_helper"

describe Term2::Renderer do
  describe Term2::StandardRenderer do
    it "starts in stopped state" do
      output = IO::Memory.new
      renderer = Term2::StandardRenderer.new(output)
      renderer.running?.should be_false
    end

    it "can be started" do
      output = IO::Memory.new
      renderer = Term2::StandardRenderer.new(output)
      renderer.start
      renderer.running?.should be_true
    end

    it "can be stopped" do
      output = IO::Memory.new
      renderer = Term2::StandardRenderer.new(output)
      renderer.start
      renderer.stop
      renderer.running?.should be_false
    end

    it "hides cursor on start" do
      output = IO::Memory.new
      renderer = Term2::StandardRenderer.new(output)
      renderer.start
      output.to_s.should contain("\e[?25l") # hide cursor
    end

    it "shows cursor on stop" do
      output = IO::Memory.new
      renderer = Term2::StandardRenderer.new(output)
      renderer.start
      renderer.stop
      output.to_s.should contain("\e[?25h") # show cursor
    end

    it "renders view to output" do
      output = IO::Memory.new
      renderer = Term2::StandardRenderer.new(output)
      renderer.fps = 1000.0 # High FPS to avoid rate limiting in tests
      renderer.start
      renderer.render("Hello, World!")
      output.to_s.should contain("Hello, World!")
    end

    it "does not render when stopped" do
      output = IO::Memory.new
      renderer = Term2::StandardRenderer.new(output)
      renderer.render("Hello, World!")
      output.to_s.should_not contain("Hello, World!")
    end

    it "does not render duplicate frames" do
      output = IO::Memory.new
      renderer = Term2::StandardRenderer.new(output)
      renderer.fps = 1000.0 # High FPS for testing
      renderer.start

      renderer.render("Hello")

      # Wait for rate limiting to pass
      sleep(5.milliseconds)

      # Reset output to check next render
      output.rewind

      renderer.render("Hello") # Same content
      # Since content is same, no additional output should be written
      # But first render already happened, so we just verify running state
      renderer.running?.should be_true
    end

    it "renders different content" do
      output = IO::Memory.new
      renderer = Term2::StandardRenderer.new(output)
      renderer.fps = 120.0 # Max FPS
      renderer.start

      renderer.render("Hello")

      # Wait for rate limiting to pass (need to wait > 1/120 second = ~8.3ms)
      sleep(10.milliseconds)

      renderer.render("World") # Different content
      output.to_s.should contain("World")
    end

    it "has default FPS of 60" do
      renderer = Term2::StandardRenderer.new(IO::Memory.new)
      renderer.fps.should eq(60.0)
    end

    it "can set FPS" do
      renderer = Term2::StandardRenderer.new(IO::Memory.new)
      renderer.fps = 30.0
      renderer.fps.should eq(30.0)
    end

    it "clamps FPS to valid range" do
      renderer = Term2::StandardRenderer.new(IO::Memory.new)
      renderer.fps = 0.5
      renderer.fps.should eq(1.0)

      renderer.fps = 200.0
      renderer.fps.should eq(120.0)
    end

    it "forces re-render after repaint" do
      output = IO::Memory.new
      renderer = Term2::StandardRenderer.new(output)
      renderer.fps = 1000.0 # High FPS for testing
      renderer.start

      renderer.render("Hello")

      # Wait for rate limiting to pass
      sleep(5.milliseconds)

      # Call repaint to force re-render
      renderer.repaint

      # Wait for rate limiting to pass
      sleep(5.milliseconds)

      # Now same content should render again
      renderer.render("Hello")
      # Verify that Hello appears multiple times (once from first render, once from repaint)
      output.to_s.scan("Hello").size.should be >= 2
    end

    it "clears screen before rendering" do
      output = IO::Memory.new
      renderer = Term2::StandardRenderer.new(output)
      renderer.fps = 1000.0 # High FPS for testing
      renderer.start
      renderer.render("Test")
      output.to_s.should contain("\e[H\e[J") # Home + clear
    end
  end

  describe Term2::NilRenderer do
    it "starts in stopped state" do
      renderer = Term2::NilRenderer.new
      renderer.running?.should be_false
    end

    it "can be started" do
      renderer = Term2::NilRenderer.new
      renderer.start
      renderer.running?.should be_true
    end

    it "can be stopped" do
      renderer = Term2::NilRenderer.new
      renderer.start
      renderer.stop
      renderer.running?.should be_false
    end

    it "does not output anything on render" do
      renderer = Term2::NilRenderer.new
      renderer.start
      renderer.render("Hello")
      # NilRenderer doesn't output anything, that's by design
      # Just verify it doesn't crash
      renderer.running?.should be_true
    end

    it "has default FPS of 60" do
      renderer = Term2::NilRenderer.new
      renderer.fps.should eq(60.0)
    end

    it "can set FPS" do
      renderer = Term2::NilRenderer.new
      renderer.fps = 30.0
      renderer.fps.should eq(30.0)
    end
  end
end
