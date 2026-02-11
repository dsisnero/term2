ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "teatest"
require "../../../examples/bubbletea/doom-fire/main"

describe "Example: doom-fire" do
  it "matches Go golden output for a deterministic frame" do
    prev_renderer = Lipgloss::StyleRenderer.default
    ansi_renderer = Lipgloss::StyleRenderer.new
    ansi_renderer.color_profile = Lipgloss::ColorProfile::ANSI256
    Lipgloss::StyleRenderer.default = ansi_renderer

    begin
    model = DoomFireExample::Model.new
      model.update(Term2::WindowSizeMsg.new(20, 8))
      2.times { model.update(DoomFireExample::TickMsg.new) }

      view = model.view
      view.alt_screen.should be_true

      output = view.content
      output = output.gsub(/\r\n?/, "\n")
      output = output.gsub(/Elapsed: \d+s/, "Elapsed: 0s")
      output = output.gsub("\e[0m", "\e[m")

      Teatest.require_equal_output("DoomFire/default", output.to_slice)
    ensure
      Lipgloss::StyleRenderer.default = prev_renderer
    end
  end

  it "does not regress to initializing view on zero window size events" do
    model = DoomFireExample::Model.new
    before = model.view.content
    before.includes?("Initializing...").should be_false

    model.update(Term2::WindowSizeMsg.new(0, 0))
    after = model.view.content
    after.includes?("Initializing...").should be_false
  end

  it "renders in a running program without parser crashes", tags: "interactive" do
    tm = Term2::Teatest::TestModel(DoomFireExample::Model).new(
      DoomFireExample::Model.new,
      Term2::Teatest.with_initial_term_size(40, 16)
    )

    Term2::Teatest.wait_for(tm.output_reader, Term2::Teatest.with_duration(2.seconds)) do |txt|
      txt.includes?("Press q or ctrl+c to quit.")
    end

    tm.quit
  end
end
