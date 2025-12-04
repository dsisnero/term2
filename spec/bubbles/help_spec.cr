require "../spec_helper"
require "../../src/components/help"
require "../../src/components/key"

class BubblesHelpKeyMap
  include Term2::Components::Help::KeyMap

  def initialize
    @binding = Term2::Components::Key::Binding.new(
      Term2::Components::Key.with_keys("x")
    )
  end

  def short_help : Array(Term2::Components::Key::Binding)
    [] of Term2::Components::Key::Binding
  end

  def full_help : Array(Array(Term2::Components::Key::Binding))
    [
      [
        Term2::Components::Key::Binding.new(
          Term2::Components::Key.with_keys("x"),
          Term2::Components::Key.with_help("enter", "continue")
        ),
      ],
      [
        Term2::Components::Key::Binding.new(
          Term2::Components::Key.with_keys("x"),
          Term2::Components::Key.with_help("esc", "back")
        ),
        Term2::Components::Key::Binding.new(
          Term2::Components::Key.with_keys("x"),
          Term2::Components::Key.with_help("?", "help")
        ),
      ],
      [
        Term2::Components::Key::Binding.new(
          Term2::Components::Key.with_keys("x"),
          Term2::Components::Key.with_help("H", "home")
        ),
        Term2::Components::Key::Binding.new(
          Term2::Components::Key.with_keys("x"),
          Term2::Components::Key.with_help("ctrl+c", "quit")
        ),
        Term2::Components::Key::Binding.new(
          Term2::Components::Key.with_keys("x"),
          Term2::Components::Key.with_help("ctrl+l", "log")
        ),
      ],
    ]
  end
end

describe Term2::Components::Help do
  it "renders full help with width-aware ellipsis like bubbles" do
    help = Term2::Components::Help.new
    help.full_separator = " | "
    help.key_style = Term2::Style.new
    help.desc_style = Term2::Style.new
    help.separator_style = Term2::Style.new
    help.ellipsis_style = Term2::Style.new
    km = BubblesHelpKeyMap.new

    expected = {
      20 => "enter continue …",
      30 => "enter continue | esc back …\n                 ?   help",
      40 => "enter continue | esc back | H      home\n                 ?   help   ctrl+c quit\n                            ctrl+l log",
    }

    expected.each do |width, output|
      help.width = width
      help.view_full(km).should eq output
    end
  end
end
