require "../spec_helper"
require "../../src/components/key"

describe Term2::Components::Key::Binding do
  it "toggles enabled state and unbinds like bubbles" do
    binding = Term2::Components::Key::Binding.new(
      Term2::Components::Key.with_keys("k", "up"),
      Term2::Components::Key.with_help("↑/k", "move up")
    )

    binding.enabled?.should be_true

    binding.set_enabled(false)
    binding.enabled?.should be_false

    binding.set_enabled(true)
    binding.unbind
    binding.enabled?.should be_false
  end
end
