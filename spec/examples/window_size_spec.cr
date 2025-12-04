ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/window-size/main"

describe "Example: window-size" do
  it "prints window size on keypress" do
    tm = Term2::Teatest::TestModel(WindowSizeModel).new(
      WindowSizeModel.new,
      Term2::Teatest.with_initial_term_size(80, 24),
    )

    # Bubble Tea tests pre-seed a WindowSizeMsg; mirror that ordering here.
    tm.send(Term2::WindowSizeMsg.new(80, 24))
    tm.send(Term2::KeyMsg.new(Term2::Key.new("x")))
    tm.send(Term2::KeyMsg.new(Term2::Key.new("q")))
    output = tm.final_output(
      Term2::Teatest.with_final_timeout(1.second),
      Term2::Teatest.with_timeout_fn { tm.quit },
    )
    output.should contain("80x24")
  end
end
