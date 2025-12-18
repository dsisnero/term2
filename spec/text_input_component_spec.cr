require "./spec_helper"

describe Term2::Components::TextInput do
  it "shows placeholder when unfocused" do
    input = Term2::Components::TextInput.new
    input.placeholder = "Type..."

    input.view.gsub(/\e\[[0-9;]*m/, "").should contain("Type...")
  end

  it "inserts characters and responds to key bindings" do
    input = Term2::Components::TextInput.new
    input.focus

    %w[h i].each do |char|
      msg = Term2::KeyMsg.new(Term2::Key.new(char))
      input, _ = input.update(msg)
    end

    # Move left
    msg_left = Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Left))
    input, _ = input.update(msg_left)

    # Backspace
    msg_bs = Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Backspace))
    input, _ = input.update(msg_bs)

    input.value.should eq("i")
    input.cursor_pos.should eq(0)
  end
end
