require "../spec_helper"
require "../../src/components/text_area"

# TODO: Port full coverage from bubbles/textarea/textarea_test.go (very large suite).
# Each pending block mirrors a Go test we still need to implement.
describe Term2::Components::TextArea do
  it "vertical scrolling wraps and scrolls (TestVerticalScrolling)" do
    textarea = Term2::Components::TextArea.new
    textarea.prompt = ""
    textarea.show_line_numbers = false
    textarea.width = 20
    textarea.height = 2
    textarea.char_limit = 100
    textarea.focus

    input = "This is a really long line that should wrap around the text area."
    input.each_char do |ch|
      textarea, _ = textarea.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
    end

    view = textarea.view.content
    view.should contain "This is a really"
    textarea.viewport.line_down
    view = textarea.view.content
    view.should contain "long line that"
  end

  it "handles word wrap overflow cascading (TestWordWrapOverflowing)" do
    textarea = Term2::Components::TextArea.new
    textarea.width = 20
    textarea.height = 3
    textarea.char_limit = 500
    textarea.focus

    input = "Testing Testing Testing Testing Testing Testing Testing Testing"
    input.each_char do |ch|
      textarea, _ = textarea.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
      textarea.view.content
    end

    textarea.cursor_line = 0
    textarea.cursor_col = 0

    "Testing".each_char do |ch|
      textarea, _ = textarea.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
      textarea.view.content
    end

    textarea.view
    textarea.line_info.width.should be <= 20
  end

  it "soft wrap preserves value (TestValueSoftWrap)" do
    textarea = Term2::Components::TextArea.new
    textarea.width = 16
    textarea.height = 10
    textarea.char_limit = 500
    textarea.focus

    input = "Testing Testing Testing Testing Testing Testing Testing Testing"
    input.each_char do |ch|
      textarea, _ = textarea.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
      textarea.view.content
    end

    textarea.value.should eq input
  end
  it "SetValue sets cursor and resets (TestSetValue)" do
    textarea = Term2::Components::TextArea.new
    textarea.value = "Foo\nBar\nBaz"
    textarea.cursor_line.should eq 2
    textarea.cursor_col.should eq 3
    textarea.value = "Test"
    textarea.value.should eq "Test"
  end
  it "insert string behavior (TestInsertString)" do
    textarea = Term2::Components::TextArea.new
    textarea.focus
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
    textarea.focus
    input = "🧋"
    input.each_char do |ch|
      textarea, _ = textarea.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
    end
    textarea.value.should eq input
    textarea.value = "🧋🧋🧋"
    textarea.value.should eq "🧋🧋🧋"
    textarea.cursor_col.should eq 3
  end
  it "vertical navigation keeps visual column (TestVerticalNavigationKeepsCursorHorizontalPosition)" do
    textarea = Term2::Components::TextArea.new
    textarea.width = 20
    textarea.value = "你好你好\nHello"
    textarea.cursor_line = 0
    textarea.cursor_col = 2
    textarea.focus

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
    textarea.width = 40
    textarea.value = "Hello\nWorld\nThis is a long line."
    textarea.focus

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

  it "page up/down moves cursor with snap behavior" do
    textarea = Term2::Components::TextArea.new
    textarea.width = 40
    textarea.height = 3 # Viewport shows 3 lines at a time
    textarea.value = "Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8\nLine 9\nLine 10"
    textarea.focus

    # Start at line 5 (0-indexed 4)
    textarea.cursor_line = 4
    textarea.cursor_col = 0

    # Set viewport to show lines 0-2 initially
    textarea.viewport.y_offset = 0

    # Page up should snap to first visible line (line 0) since cursor is at line 4
    # Actually cursor_line_number = 4, viewport.y_offset = 0, offset = -4 < 0
    # So should snap to first visible line (line 0)
    page_up = Term2::KeyMsg.new(Term2::Key.new("pgup"))
    textarea, _ = textarea.update(page_up)
    textarea.cursor_line.should eq 0

    # Move cursor down to line 2
    textarea.cursor_line = 2
    textarea.cursor_col = 0

    # Page down should snap to last visible line (line 2) since cursor is at line 2
    # and viewport shows lines 0-2 (last visible is line 2)
    page_down = Term2::KeyMsg.new(Term2::Key.new("pgdown"))
    textarea, _ = textarea.update(page_down)
    # Should move to line 5 (2 + 3 height)
    textarea.cursor_line.should eq 5
  end
end
