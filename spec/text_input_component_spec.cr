require "./spec_helper"

describe Term2::Components::TextInput do
  it "shows placeholder when unfocused" do
    input = Term2::Components::TextInput.new
    input.placeholder = "Type..."

    input.view.should contain("Type...")
  end

  it "inserts characters and responds to key bindings" do
    input = Term2::Components::TextInput.new
    input.cursor.focus = true

    %w[h i].each do |char|
      msg = Term2::KeyMsg.new(Term2::Key.new(char))
      input.update(msg)
    end

    # Move left
    msg_left = Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Left))
    input.update(msg_left)

    # Backspace
    msg_bs = Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Backspace))
    input.update(msg_bs)

    input.value.should eq("i")
    input.cursor_pos.should eq(0)
  end

  it "handles space key input" do
    input = Term2::Components::TextInput.new
    input.cursor.focus = true

    # Type "this is as" with spaces
    ['t', 'h', 'i', 's', ' ', 'i', 's', ' ', 'a', 's'].each do |char|
      if char == " "
        msg = Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Space))
      else
        msg = Term2::KeyMsg.new(Term2::Key.new(char))
      end
      input.update(msg)
    end

    input.value.should eq("this is as")
  end
end
