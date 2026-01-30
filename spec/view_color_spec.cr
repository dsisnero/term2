require "./spec_helper"

describe "View color rendering" do
  it "applies background and foreground colors" do
    output = IO::Memory.new
    renderer = Term2::StandardRenderer.new(output)
    renderer.fps = 1000.0 # High FPS to avoid rate limiting
    renderer.start

    # Create a View with background and foreground colors
    view = Term2::View.new
    view.background_color = Term2::Color::RED
    view.foreground_color = Term2::Color::BLUE
    view.content = "Hello"

    renderer.render(view)
    output_str = output.to_s

    # Should contain background code 41 (40 + 1 for RED)
    output_str.should contain("\e[41m")
    # Should contain foreground code 34 (30 + 4 for BLUE)
    output_str.should contain("\e[34m")
    # Should contain reset before colors
    output_str.should contain("\e[0m")
    # Should contain the content
    output_str.should contain("Hello")
  end

  it "applies colors to multiple lines" do
    output = IO::Memory.new
    renderer = Term2::StandardRenderer.new(output)
    renderer.fps = 1000.0
    renderer.start

    view = Term2::View.new
    view.background_color = Term2::Color::GREEN
    view.foreground_color = Term2::Color::YELLOW
    view.content = "Line 1\nLine 2"

    renderer.render(view)
    output_str = output.to_s

    # Should have background code 42 (GREEN) and foreground 33 (YELLOW)
    # Reset and colors should appear for each line that changed
    # Since we render line-diff, both lines are new, so colors applied per line.
    # Additionally, apply_colors outputs colors once before line rendering.
    # So total occurrences: 1 (global) + 2 (lines) = 3
    output_str.scan("\e[42m").size.should eq(3)
    output_str.scan("\e[33m").size.should eq(3)
  end

  it "updates colors when they change" do
    output = IO::Memory.new
    renderer = Term2::StandardRenderer.new(output)
    renderer.fps = 1000.0
    renderer.start

    # First render with RED background
    view1 = Term2::View.new
    view1.background_color = Term2::Color::RED
    view1.content = "Hello"
    renderer.render(view1)

    # Wait a bit for rate limiting
    sleep(10.milliseconds)

    # Second render with BLUE background (different color)
    view2 = Term2::View.new
    view2.background_color = Term2::Color::BLUE
    view2.content = "Hello"
    renderer.render(view2)

    output_str = output.to_s

    # Should have both color codes
    output_str.should contain("\e[41m") # RED background
    output_str.should contain("\e[44m") # BLUE background
  end
end
