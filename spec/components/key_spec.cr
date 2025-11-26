require "../spec_helper"
require "../../src/components/key"

describe Term2::Components::Key::Binding do
  it "matches keys" do
    binding = Term2::Components::Key::Binding.new(
      keys: ["q", "esc"],
      help_key: "q/esc",
      help_desc: "quit"
    )

    q_msg = Term2::KeyMsg.new(Term2::Key.new("q"))
    esc_msg = Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Esc))
    other_msg = Term2::KeyMsg.new(Term2::Key.new("a"))

    binding.matches?(q_msg).should be_true
    binding.matches?(esc_msg).should be_true
    binding.matches?(other_msg).should be_false
  end

  it "respects disabled state" do
    binding = Term2::Components::Key::Binding.new(
      keys: ["q"],
      help_key: "q",
      help_desc: "quit"
    )
    binding.disabled = true

    q_msg = Term2::KeyMsg.new(Term2::Key.new("q"))
    binding.matches?(q_msg).should be_false
  end
end
