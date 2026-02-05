require "../spec_helper"

describe "Bubbletea parity: nil_renderer_test.go" do
  it "nil renderer can be instantiated and used" do
    renderer = Term2::NilRenderer.new

    renderer.start
    renderer.stop
    renderer.kill
    renderer.write("a")
    renderer.repaint
    renderer.enter_alt_screen
    renderer.alt_screen?.should be_false
    renderer.exit_alt_screen
    renderer.clear_screen
    renderer.show_cursor
    renderer.hide_cursor
    renderer.enable_mouse_cell_motion
    renderer.disable_mouse_cell_motion
    renderer.enable_mouse_all_motion
    renderer.disable_mouse_all_motion
  end
end
