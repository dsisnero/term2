require "../spec_helper"
require "../../src/components/text_area"

private def new_text_area : Term2::Components::TextArea
  textarea = Term2::Components::TextArea.new
  textarea.prompt = "> "
  textarea.placeholder = "Hello, World!"
  textarea.focus
  textarea
end

private def key_press(ch : Char) : Term2::KeyMsg
  Term2::KeyMsg.new(Term2::Key.new(ch))
end

private def send_string(textarea : Term2::Components::TextArea, str : String) : Term2::Components::TextArea
  str.each_char do |ch|
    textarea, _ = textarea.update(key_press(ch))
  end
  textarea
end

private def strip_string(str : String) : String
  plain = str.gsub(/\e\[[0-9;]*[A-Za-z]?/, "")
  plain = plain.gsub(/\e/, "")
  plain
    .split("\n")
    .map { |l| l.lstrip.rstrip }
    .reject(&.empty?)
    .join("\n")
end

struct ViewCase
  getter name : String
  getter setup : Proc(Term2::Components::TextArea, Term2::Components::TextArea)?
  getter want_view : String
  getter cursor_row : Int32?
  getter cursor_col : Int32?

  def initialize(@name, @setup, @want_view, @cursor_row = nil, @cursor_col = nil)
  end
end

describe Term2::Components::TextArea do
  describe "view parity" do
    tests = [] of ViewCase

    tests << ViewCase.new(
      "placeholder",
      nil,
      <<-VIEW
        >   1 Hello, World!
        >
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "single line",
      ->(m : Term2::Components::TextArea) {
        m.set_value("the first line")
        m
      },
      <<-VIEW
        >   1 the first line
        >
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "multiple lines",
      ->(m : Term2::Components::TextArea) {
        m.set_value("the first line\nthe second line\nthe third line")
        m
      },
      <<-VIEW
        >   1 the first line
        >   2 the second line
        >   3 the third line
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "single line without line numbers",
      ->(m : Term2::Components::TextArea) {
        m.set_value("the first line")
        m.show_line_numbers = false
        m
      },
      <<-VIEW
        > the first line
        >
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "multipline lines without line numbers",
      ->(m : Term2::Components::TextArea) {
        m.set_value("the first line\nthe second line\nthe third line")
        m.show_line_numbers = false
        m
      },
      <<-VIEW
        > the first line
        > the second line
        > the third line
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "single line and custom end of buffer character",
      ->(m : Term2::Components::TextArea) {
        m.set_value("the first line")
        m.end_of_buffer_char = '*'
        m
      },
      <<-VIEW
        >   1 the first line
        > *
        > *
        > *
        > *
        > *
VIEW
    )

    tests << ViewCase.new(
      "multiple lines and custom end of buffer character",
      ->(m : Term2::Components::TextArea) {
        m.set_value("the first line\nthe second line\nthe third line")
        m.end_of_buffer_char = '*'
        m
      },
      <<-VIEW
        >   1 the first line
        >   2 the second line
        >   3 the third line
        > *
        > *
        > *
VIEW
    )

    tests << ViewCase.new(
      "single line without line numbers and custom end of buffer character",
      ->(m : Term2::Components::TextArea) {
        m.set_value("the first line")
        m.show_line_numbers = false
        m.end_of_buffer_char = '*'
        m
      },
      <<-VIEW
        > the first line
        > *
        > *
        > *
        > *
        > *
VIEW
    )

    tests << ViewCase.new(
      "multiple lines without line numbers and custom end of buffer character",
      ->(m : Term2::Components::TextArea) {
        m.set_value("the first line\nthe second line\nthe third line")
        m.show_line_numbers = false
        m.end_of_buffer_char = '*'
        m
      },
      <<-VIEW
        > the first line
        > the second line
        > the third line
        > *
        > *
        > *
VIEW
    )

    tests << ViewCase.new(
      "single line and custom prompt",
      ->(m : Term2::Components::TextArea) {
        m.set_value("the first line")
        m.prompt = "* "
        m
      },
      <<-VIEW
        *   1 the first line
        *
        *
        *
        *
        *
VIEW
    )

    tests << ViewCase.new(
      "multiple lines and custom prompt",
      ->(m : Term2::Components::TextArea) {
        m.set_value("the first line\nthe second line\nthe third line")
        m.prompt = "* "
        m
      },
      <<-VIEW
        *   1 the first line
        *   2 the second line
        *   3 the third line
        *
        *
        *
VIEW
    )

    tests << ViewCase.new(
      "type single line",
      ->(m : Term2::Components::TextArea) {
        send_string(m, "foo")
      },
      <<-VIEW
        >   1 foo
        >
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "type multiple lines",
      ->(m : Term2::Components::TextArea) {
        send_string(m, "foo\nbar\nbaz")
      },
      <<-VIEW
        >   1 foo
        >   2 bar
        >   3 baz
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "softwrap",
      ->(m : Term2::Components::TextArea) {
        m.show_line_numbers = false
        m.prompt = ""
        m.set_width(5)
        send_string(m, "foo bar baz")
      },
      <<-VIEW
        foo
        bar
        baz



VIEW
    )

    tests << ViewCase.new(
      "single line character limit",
      ->(m : Term2::Components::TextArea) {
        m.char_limit = 7
        send_string(m, "foo bar baz")
      },
      <<-VIEW
        >   1 foo bar
        >
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "multiple lines character limit",
      ->(m : Term2::Components::TextArea) {
        m.char_limit = 19
        send_string(m, "foo bar baz\nfoo bar baz")
      },
      <<-VIEW
        >   1 foo bar baz
        >   2 foo bar
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "set width",
      ->(m : Term2::Components::TextArea) {
        m.set_width(10)
        send_string(m, "12")
      },
      <<-VIEW
        >   1 12
        >
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "set width max length text minus one",
      ->(m : Term2::Components::TextArea) {
        m.set_width(10)
        send_string(m, "123")
      },
      <<-VIEW
        >   1 123
        >
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "set width max length text",
      ->(m : Term2::Components::TextArea) {
        m.set_width(10)
        send_string(m, "1234")
      },
      <<-VIEW
        >   1 1234
        >
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "set width max length text plus one",
      ->(m : Term2::Components::TextArea) {
        m.set_width(10)
        send_string(m, "12345")
      },
      <<-VIEW
        >   1 1234
        >     5
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "set width set max width minus one",
      ->(m : Term2::Components::TextArea) {
        m.max_width = 10
        m.set_width(11)
        send_string(m, "123")
      },
      <<-VIEW
        >   1 123
        >
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "set width set max width",
      ->(m : Term2::Components::TextArea) {
        m.max_width = 10
        m.set_width(11)
        send_string(m, "1234")
      },
      <<-VIEW
        >   1 1234
        >
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "set width set max width plus one",
      ->(m : Term2::Components::TextArea) {
        m.max_width = 10
        m.set_width(11)
        send_string(m, "12345")
      },
      <<-VIEW
        >   1 1234
        >     5
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "set width min width minus one",
      ->(m : Term2::Components::TextArea) {
        m.set_width(6)
        send_string(m, "123")
      },
      <<-VIEW
        >   1 1
        >     2
        >     3
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "set width min width",
      ->(m : Term2::Components::TextArea) {
        m.set_width(7)
        send_string(m, "123")
      },
      <<-VIEW
        >   1 1
        >     2
        >     3
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "set width min width no line numbers",
      ->(m : Term2::Components::TextArea) {
        m.show_line_numbers = false
        m.set_width(0)
        send_string(m, "123")
      },
      <<-VIEW
        > 1
        > 2
        > 3
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "set width min width no line numbers no prompt",
      ->(m : Term2::Components::TextArea) {
        m.show_line_numbers = false
        m.prompt = ""
        m.set_width(0)
        send_string(m, "123")
      },
      <<-VIEW
        1
        2
        3



VIEW
    )

    tests << ViewCase.new(
      "set width min width plus one",
      ->(m : Term2::Components::TextArea) {
        m.set_width(8)
        send_string(m, "123")
      },
      <<-VIEW
        >   1 12
        >     3
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "set width without line numbers max length text minus one",
      ->(m : Term2::Components::TextArea) {
        m.show_line_numbers = false
        m.set_width(6)
        send_string(m, "123")
      },
      <<-VIEW
        > 123
        >
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "set width without line numbers max length text",
      ->(m : Term2::Components::TextArea) {
        m.show_line_numbers = false
        m.set_width(6)
        send_string(m, "1234")
      },
      <<-VIEW
        > 1234
        >
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "set width without line numbers max length text plus one",
      ->(m : Term2::Components::TextArea) {
        m.show_line_numbers = false
        m.set_width(6)
        send_string(m, "12345")
      },
      <<-VIEW
        > 1234
        > 5
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "placeholder min width",
      ->(m : Term2::Components::TextArea) {
        m.set_width(0)
        m
      },
      <<-VIEW
        >   1 H
        >     e
        >     l
        >     l
        >     o
        >     ,
VIEW
    )

    tests << ViewCase.new(
      "placeholder single line",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "placeholder the first line"
        m.show_line_numbers = false
        m
      },
      <<-VIEW
        > placeholder the first line
        >
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "placeholder multiple lines",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "placeholder the first line\nplaceholder the second line\nplaceholder the third line"
        m.show_line_numbers = false
        m
      },
      <<-VIEW
        > placeholder the first line
        > placeholder the second line
        > placeholder the third line
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "placeholder single line with line numbers",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "placeholder the first line"
        m.show_line_numbers = true
        m
      },
      <<-VIEW
        >   1 placeholder the first line
        >
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "placeholder multiple lines with line numbers",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "placeholder the first line\nplaceholder the second line\nplaceholder the third line"
        m.show_line_numbers = true
        m
      },
      <<-VIEW
        >   1 placeholder the first line
        >     placeholder the second line
        >     placeholder the third line
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "placeholder single line with end of buffer character",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "placeholder the first line"
        m.show_line_numbers = false
        m.end_of_buffer_char = '*'
        m
      },
      <<-VIEW
        > placeholder the first line
        > *
        > *
        > *
        > *
        > *
VIEW
    )

    tests << ViewCase.new(
      "placeholder multiple lines with with end of buffer character",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "placeholder the first line\nplaceholder the second line\nplaceholder the third line"
        m.show_line_numbers = false
        m.end_of_buffer_char = '*'
        m
      },
      <<-VIEW
        > placeholder the first line
        > placeholder the second line
        > placeholder the third line
        > *
        > *
        > *
VIEW
    )

    tests << ViewCase.new(
      "placeholder single line with line numbers and end of buffer character",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "placeholder the first line"
        m.show_line_numbers = true
        m.end_of_buffer_char = '*'
        m
      },
      <<-VIEW
        >   1 placeholder the first line
        > *
        > *
        > *
        > *
        > *
VIEW
    )

    tests << ViewCase.new(
      "placeholder multiple lines with line numbers and end of buffer character",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "placeholder the first line\nplaceholder the second line\nplaceholder the third line"
        m.show_line_numbers = true
        m.end_of_buffer_char = '*'
        m
      },
      <<-VIEW
        >   1 placeholder the first line
        >     placeholder the second line
        >     placeholder the third line
        > *
        > *
        > *
VIEW
    )

    tests << ViewCase.new(
      "placeholder single line that is longer than max width",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "placeholder the first line that is longer than the max width"
        m.set_width(40)
        m.show_line_numbers = false
        m
      },
      <<-VIEW
        > placeholder the first line that is
        > longer than the max width
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "placeholder multiple lines that are longer than max width",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "placeholder the first line that is longer than the max width\nplaceholder the second line that is longer than the max width"
        m.show_line_numbers = false
        m.set_width(40)
        m
      },
      <<-VIEW
        > placeholder the first line that is
        > longer than the max width
        > placeholder the second line that is
        > longer than the max width
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "placeholder single line that is longer than max width with line numbers",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "placeholder the first line that is longer than the max width"
        m.show_line_numbers = true
        m.set_width(40)
        m
      },
      <<-VIEW
        >   1 placeholder the first line that is
        >     longer than the max width
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "placeholder multiple lines that are longer than max width with line numbers",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "placeholder the first line that is longer than the max width\nplaceholder the second line that is longer than the max width"
        m.show_line_numbers = true
        m.set_width(40)
        m
      },
      <<-VIEW
        >   1 placeholder the first line that is
        >     longer than the max width
        >     placeholder the second line that
        >     is longer than the max width
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "placeholder single line that is longer than max width at limit",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "123456789012345678"
        m.show_line_numbers = false
        m.set_width(20)
        m
      },
      <<-VIEW
        > 123456789012345678
        >
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "placeholder single line that is longer than max width at limit plus one",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "1234567890123456789"
        m.show_line_numbers = false
        m.set_width(20)
        m
      },
      <<-VIEW
        > 123456789012345678
        > 9
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "placeholder single line that is longer than max width with line numbers at limit",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "12345678901234"
        m.show_line_numbers = true
        m.set_width(20)
        m
      },
      <<-VIEW
        >   1 12345678901234
        >
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "placeholder single line that is longer than max width with line numbers at limit plus one",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "123456789012345"
        m.show_line_numbers = true
        m.set_width(20)
        m
      },
      <<-VIEW
        >   1 12345678901234
        >     5
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "placeholder multiple lines that are longer than max width at limit",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "123456789012345678\n123456789012345678"
        m.show_line_numbers = false
        m.set_width(20)
        m
      },
      <<-VIEW
        > 123456789012345678
        > 123456789012345678
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "placeholder multiple lines that are longer than max width at limit plus one",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "1234567890123456789\n1234567890123456789"
        m.show_line_numbers = false
        m.set_width(20)
        m
      },
      <<-VIEW
        > 123456789012345678
        > 9
        > 123456789012345678
        > 9
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "placeholder multiple lines that are longer than max width with line numbers at limit",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "12345678901234\n12345678901234"
        m.show_line_numbers = true
        m.set_width(20)
        m
      },
      <<-VIEW
        >   1 12345678901234
        >     12345678901234
        >
        >
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "placeholder multiple lines that are longer than max width with line numbers at limit plus one",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "123456789012345\n123456789012345"
        m.show_line_numbers = true
        m.set_width(20)
        m
      },
      <<-VIEW
        >   1 12345678901234
        >     5
        >     12345678901234
        >     5
        >
        >
VIEW
    )

    tests << ViewCase.new(
      "placeholder chinese character",
      ->(m : Term2::Components::TextArea) {
        m.placeholder = "输入消息..."
        m.show_line_numbers = true
        m.set_width(20)
        m
      },
      <<-VIEW
        >   1 输入消息...
        >
        >
        >
        >
        >
VIEW
    )

    tests.each do |tt|
      it tt.name do
        textarea = new_text_area
        if proc = tt.setup
          textarea = proc.call(textarea)
        end

        view = strip_string(textarea.view)
        want_view = strip_string(tt.want_view)
        view.should eq(want_view)

        if tt.cursor_row && tt.cursor_col
          textarea.cursor_line_number.should eq(tt.cursor_row.not_nil!)
          textarea.line_info.column_offset.should eq(tt.cursor_col.not_nil!)
        end
      end
    end
  end
end
