require "./spec_helper"

describe Term2::CursedRenderer do
  it "starts in stopped state" do
    output = IO::Memory.new
    renderer = Term2::CursedRenderer.new(output)
    renderer.running?.should be_false
  end

  it "can be started" do
    output = IO::Memory.new
    renderer = Term2::CursedRenderer.new(output)
    renderer.start
    renderer.running?.should be_true
  end

  it "can be stopped" do
    output = IO::Memory.new
    renderer = Term2::CursedRenderer.new(output)
    renderer.start
    renderer.stop
    renderer.running?.should be_false
  end

  it "renders view to output" do
    output = IO::Memory.new
    renderer = Term2::CursedRenderer.new(output)
    renderer.fps = 1000.0 # High FPS to avoid rate limiting in tests
    renderer.start
    renderer.render("Hello, World!")
    output.to_s.should contain("Hello, World!")
  end

  it "renders View struct" do
    output = IO::Memory.new
    renderer = Term2::CursedRenderer.new(output)
    renderer.fps = 1000.0
    renderer.start
    view = Term2::View.new(content: "Test content", alt_screen: false)
    renderer.render_view(view)
    output.to_s.should contain("Test content")
  end

  it "handles color profile" do
    output = IO::Memory.new
    renderer = Term2::CursedRenderer.new(output)
    renderer.color_profile = Lipgloss::ColorProfile::ANSI
    renderer.color_profile.should eq(Lipgloss::ColorProfile::ANSI)
  end
end