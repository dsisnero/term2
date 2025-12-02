require "../spec_helper"

describe "BubbleTea parity: nil renderer" do
  it "supports all no-op operations" do
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