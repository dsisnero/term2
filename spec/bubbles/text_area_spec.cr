require "../spec_helper"
require "../../src/components/text_area"

# TODO: Port full coverage from bubbles/textarea/textarea_test.go (very large suite).
# Each pending block mirrors a Go test we still need to implement.
describe Term2::Components::TextArea do
  it "vertical scrolling wraps and scrolls (TestVerticalScrolling)" do
    textarea = Term2::Components::TextArea.new
    textarea.prompt = ""
    textarea.show_line_numbers = false
    textarea.set_width(20)
    textarea.height = 2
    textarea.char_limit = 100
    textarea.focus

    input = "This is a really long line that should wrap around the text area."
    input.each_char do |ch|
      textarea, _ = textarea.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
    end

    view = textarea.view
    view.should contain "This is a really"
    textarea.viewport.line_down
    view = textarea.view
    view.should contain "long line that"
  end

  it "handles word wrap overflow cascading (TestWordWrapOverflowing)" do
    textarea = Term2::Components::TextArea.new
    textarea.set_width(20)
    textarea.height = 3
    textarea.char_limit = 500
    textarea.focus

    input = "Testing Testing Testing Testing Testing Testing Testing Testing"
    input.each_char do |ch|
      textarea, _ = textarea.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
      textarea.view
    end

    textarea.cursor_line = 0
    textarea.cursor_col = 0

    "Testing".each_char do |ch|
      textarea, _ = textarea.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
      textarea.view
    end

    textarea.view
    textarea.line_info.width.should be <= 20
  end

  it "soft wrap preserves value (TestValueSoftWrap)" do
    textarea = Term2::Components::TextArea.new
    textarea.set_width(16)
    textarea.height = 10
    textarea.char_limit = 500
    textarea.focus

    input = "Testing Testing Testing Testing Testing Testing Testing Testing"
    input.each_char do |ch|
      textarea, _ = textarea.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
      textarea.view
    end

    textarea.value.should eq input
  end
  it "SetValue sets cursor and resets (TestSetValue)" do
    textarea = Term2::Components::TextArea.new
    textarea.set_value("Foo\nBar\nBaz")
    textarea.cursor_line.should eq 2
    textarea.cursor_col.should eq 3
    textarea.set_value("Test")
    textarea.value.should eq "Test"
  end
  it "insert string behavior (TestInsertString)" do
    textarea = Term2::Components::TextArea.new
    input = "foo baz"
    input.each_char do |ch|
      textarea, _ = textarea.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
    end
    textarea.cursor_col = 4
    textarea.insert_string("bar ")
    textarea.value.should eq "foo bar baz"
  end
  it "handles emoji widths (TestCanHandleEmoji)" do
    textarea = Term2::Components::TextArea.new
    input = "🧋"
    input.each_char do |ch|
      textarea, _ = textarea.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
    end
    textarea.value.should eq input
    textarea.set_value("🧋🧋🧋")
    textarea.value.should eq "🧋🧋🧋"
    textarea.cursor_col.should eq 3
  end
  it "vertical navigation keeps visual column (TestVerticalNavigationKeepsCursorHorizontalPosition)" do
    textarea = Term2::Components::TextArea.new
    textarea.set_width(20)
    textarea.set_value("你好你好\nHello")
    textarea.cursor_line = 0
    textarea.cursor_col = 2

    info = textarea.line_info
    info.char_offset.should eq 4
    info.column_offset.should eq 2

    down = Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Down))
    textarea, _ = textarea.update(down)
    info = textarea.line_info
    info.char_offset.should eq 4
    info.column_offset.should eq 4
  end
  it "vertical navigation remembers position while traversing (TestVerticalNavigationShouldRememberPositionWhileTraversing)" do
    textarea = Term2::Components::TextArea.new
    textarea.set_width(40)
    textarea.set_value("Hello\nWorld\nThis is a long line.")

    textarea.cursor_col.should eq 20
    textarea.cursor_line.should eq 2

    up = Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Up))
    textarea, _ = textarea.update(up)
    textarea.cursor_col.should eq 5
    textarea.cursor_line.should eq 1

    textarea, _ = textarea.update(up)
    textarea.cursor_col.should eq 5
    textarea.cursor_line.should eq 0

    down = Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Down))
    textarea, _ = textarea.update(down)
    textarea, _ = textarea.update(down)
    textarea.cursor_col.should eq 20
    textarea.cursor_line.should eq 2

    textarea, _ = textarea.update(up)
    left = Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Left))
    textarea, _ = textarea.update(left)
    textarea.cursor_col.should eq 4
    textarea.cursor_line.should eq 1

    textarea, _ = textarea.update(down)
    textarea.cursor_col.should eq 4
    textarea.cursor_line.should eq 2
  end
end
