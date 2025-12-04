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

class SingleColumnKeyMap
  include Term2::Components::Help::KeyMap

  def initialize
    @bindings = [
      Term2::Components::Key::Binding.new(["a"], "a", "alpha"),
      Term2::Components::Key::Binding.new(["b"], "b", "beta"),
      Term2::Components::Key::Binding.new(["g"], "g", "gamma"),
    ]
  end

  def short_help : Array(Term2::Components::Key::Binding)
    [] of Term2::Components::Key::Binding
  end

  def full_help : Array(Array(Term2::Components::Key::Binding))
    [@bindings]
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

    lines.size.should be >= 2
    lines[0].should contain "↑"
    lines[1].should contain "↓"
    lines.join.should contain "q"
  end

  it "renders all lines when only one column is available" do
    help = Term2::Components::Help.new
    help.show_all = true
    km = SingleColumnKeyMap.new

    view = help.view_full(km)
    view.split("\n").size.should eq 3
    view.should contain "alpha"
    view.should contain "beta"
    view.should contain "gamma"
  end

  it "builds bindings from named tuples" do
    entries = [
      {keys: ["a"], help: "a", description: "alpha"},
      {keys: ["b"], help: "b", description: "beta"},
    ]
    bindings = Term2::Components::Help::KeyMap.bindings(entries)
    bindings.size.should eq 2
    bindings.first.help_desc.should eq "alpha"
    bindings.first.matches?(Term2::KeyMsg.new(Term2::Key.new("a"))).should be_true
  end

  it "builds bindings from tuples" do
    entries = [
      {["c"], "c", "charlie"},
      {["d"], "d", "delta"},
    ]
    bindings = Term2::Components::Help::KeyMap.bindings(entries)
    bindings.last.help_key.should eq "d"
    bindings.last.help_desc.should eq "delta"
  end
end
