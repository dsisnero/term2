require "./spec_helper"

private def color_hex(color : Lipgloss::Color) : String
  r, g, b = color.to_rgb
  "##{r.to_s(16).rjust(2, '0')}#{g.to_s(16).rjust(2, '0')}#{b.to_s(16).rjust(2, '0')}"
end

describe "View color rendering" do
  it "applies background and foreground colors" do
    output = IO::Memory.new
    renderer = Term2::StandardRenderer.new(output)
    renderer.fps = 1000.0 # High FPS to avoid rate limiting
    renderer.start

    # Create a View with background and foreground colors
    view = Term2::View.new
    view.background_color = Lipgloss::Color::RED
    view.foreground_color = Lipgloss::Color::BLUE
    view.content = "Hello"

    renderer.render(view)
    output_str = output.to_s

    # Should contain OSC background/foreground color sequences
    output_str.should contain("\e]11;#{color_hex(Lipgloss::Color::RED)}\a")
    output_str.should contain("\e]10;#{color_hex(Lipgloss::Color::BLUE)}\a")
    # Should contain the content
    output_str.should contain("Hello")
  end

  it "applies colors to multiple lines" do
    output = IO::Memory.new
    renderer = Term2::StandardRenderer.new(output)
    renderer.fps = 1000.0
    renderer.start

    view = Term2::View.new
    view.background_color = Lipgloss::Color::GREEN
    view.foreground_color = Lipgloss::Color::YELLOW
    view.content = "Line 1\nLine 2"

    renderer.render(view)
    output_str = output.to_s

    output_str.should contain("\e]11;#{color_hex(Lipgloss::Color::GREEN)}\a")
    output_str.should contain("\e]10;#{color_hex(Lipgloss::Color::YELLOW)}\a")
  end

  it "updates colors when they change" do
    output = IO::Memory.new
    renderer = Term2::StandardRenderer.new(output)
    renderer.fps = 1000.0
    renderer.start

    # First render with RED background
    view1 = Term2::View.new
    view1.background_color = Lipgloss::Color::RED
    view1.content = "Hello"
    renderer.render(view1)

    # Wait a bit for rate limiting
    sleep(10.milliseconds)

    # Second render with BLUE background (different color)
    view2 = Term2::View.new
    view2.background_color = Lipgloss::Color::BLUE
    view2.content = "Hello"
    renderer.render(view2)

    output_str = output.to_s

    output_str.should contain("\e]11;#{color_hex(Lipgloss::Color::RED)}\a")
    output_str.should contain("\e]11;#{color_hex(Lipgloss::Color::BLUE)}\a")
  end
end
