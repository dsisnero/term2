require "../spec_helper"
require "../../src/components/help"

# Mock KeyMap
class MockKeyMap
  include Term2::Components::Help::KeyMap

  def initialize
    @up = Term2::Components::Key::Binding.new(["up"], "↑", "up")
    @down = Term2::Components::Key::Binding.new(["down"], "↓", "down")
    @quit = Term2::Components::Key::Binding.new(["q"], "q", "quit")
  end

  def short_help : Array(Term2::Components::Key::Binding)
    [@up, @down, @quit]
  end

  def full_help : Array(Array(Term2::Components::Key::Binding))
    [[@up, @down], [@quit]]
  end
end

describe Term2::Components::Help do
  it "renders short help" do
    help = Term2::Components::Help.new
    km = MockKeyMap.new

    # "↑ up • ↓ down • q quit" (with styles)
    view = help.view(km)
    view.should contain "↑"
    view.should contain "up"
    view.should contain "•"
    view.should contain "q"
    view.should contain "quit"
  end

  it "renders full help" do
    help = Term2::Components::Help.new
    help.show_all = true
    km = MockKeyMap.new

    view = help.view(km)
    lines = view.split("\n")

    lines.size.should be >= 3
    lines[0].should contain "↑"
    lines[1].should contain "↓"
    # lines[2] is spacer
    lines[3].should contain "q"
  end
end
